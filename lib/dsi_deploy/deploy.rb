class DSI::Deploy
  def initialize(name, config, fetch_env=nil)
    @name = name
    @config = config
    @fetch_env = fetch_env
    @srv_cache = {}
  end
  attr_reader :name

  %w(domain environment ssh_keys_path region hosts_pattern).each do |lookup_attr|
    define_method lookup_attr do
      lookup(lookup_attr)
    end
  end
  def full_name
    "#{name}-#{environment}"
  end
  def underscore_name
    full_name.gsub('-','_')
  end

  def secret
    Base64.strict_encode64 `echo #{full_name} | openssl rsautl -inkey #{self.ssh_key_file} -sign`
  end
  def ssh_key_file
    File.expand_path(File.join(ssh_keys_path, "#{underscore_name}.pem"))
  end

  def node_counts
    meta_lookup(:roles) || {}
  end

  def migrator_role
    :worker
  end

  def nodes(role_filter=nil)
    if role_filter
      1.upto(node_counts[role_filter]).map do |index|
         DSI::Deploy::Node.new(self, role_filter, index)
      end
    else
      node_counts.map do |role, counts|
        1.upto(counts).map do |index|
          DSI::Deploy::Node.new(self, role, index)
        end
      end.flatten
    end
  end

  class Service
    attr_reader :target, :port
    def initialize(target, port)
      @target, @port = target.to_s, port.to_i
    end
  end
  def service(name, proto=:tcp)
    subdomain = "_#{name}._#{proto}"
    @srv_cache[subdomain] ||= begin
      srvs = dns_lookup(:SRV, subdomain)
      if srvs.size == 1
        srv = srvs.first
      else
        raise "SRV query returned multiple records, but SRV weighted-sorting is not yet supported!"
      end
      DSI::Deploy::Service.new(srv.target, srv.port)
    end
  end


  private


  def lookup(key)
    @config[key.to_sym] || @config[key.to_s] || (@fetch_env && @fetch_env.fetch(key.to_sym)) || meta_lookup(key)
  end

  def meta_lookup(key)
    key = key.to_sym
    if key == :domain
      raise "Can't lookup DNS domain using DNS domain..."
    end
    @meta ||= begin
      meta = {}
      dns_lookup(:TXT, '_meta').each do |record|
        name, value = record.data.split('=')
        if value =~ /^\d+$/
          value = value.to_i
        end
        if name =~ /^(.*?)\[(.*?)\]$/
          meta[$1.to_sym] ||= {}
          meta[$1.to_sym][$2.to_sym] = value
        else
          meta[name.to_sym] = value
        end
      end
      meta
    end
    @meta[key]
  end


  def dns_lookup(record_type, subdomain='')
    DSI.log "DNS query: #{record_type} IN #{subdomain}.#{domain}"
    Resolv::DNS.open do |dns|
      return dns.getresources "#{subdomain}.#{domain}", Resolv::DNS::Resource::IN.const_get(record_type)
    end
  end
end