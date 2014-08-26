require "dsi_deploy/version"

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
      @config[:domain]
    end
    def environment
      @settings.fetch(:environment) or @settings.fetch(:stage)
    end
    def ssh_keys_path
      @settings.fetch(:ssh_keys_path)
    end
    def ssh_key_file
      File.expand_path(File.join(ssh_keys_path, "#{underscore_name}.pem"))
    end
    def dns_lookup(record_type, subdomain='')
      Resolv::DNS.open do |dns|
        return dns.getresources "#{subdomain}.#{domain}", Resolv::DNS::Resource::IN.const_get(record_type)
      end
    end
  end
end

