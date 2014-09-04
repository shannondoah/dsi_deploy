require "dsi_deploy/version"
require 'base64'

module DSI
  class Deploy
    def initialize(name, config, settings)
      @name = name
      @config = config
      @settings = settings

    end
    attr_reader :name
    def full_name
      "#{name}-#{environment}"
    end
    def underscore_name
      full_name.gsub('-','_')
    end
    def domain
      @config['domain']
    end
    def environment
      @settings.fetch(:environment) or @settings.fetch(:stage)
    end
    def ssh_keys_path
      @settings.fetch(:ssh_keys_path)
    end
    def region
      @config['region']
    end
    def secret
      Base64.strict_encode64 `echo #{full_name} | openssl rsautl -inkey #{self.ssh_key_file} -sign`
    end
    def ssh_key_file
      File.expand_path(File.join(ssh_keys_path, "#{underscore_name}.pem"))
    end
    def dns_lookup(record_type, subdomain='')
      Resolv::DNS.open do |dns|
        return dns.getresources "#{subdomain}.#{domain}", Resolv::DNS::Resource::IN.const_get(record_type)
      end
    end
    def node_counts
      @node_counts ||= Hash[self.dns_lookup(:TXT, '_nodes').map{|record|
        role, count = record.data.split('=')
        [role.to_sym, count.to_i]
      }]
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

  end
end

require "dsi_deploy/node"
