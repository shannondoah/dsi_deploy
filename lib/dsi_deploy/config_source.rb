require 'dsi_deploy'
require 'net/http'
require 'digest'

# rails_config source - compatible with Settings.add_source!()
class DSI::Deploy::ConfigSource
  def initialize(settings)
    config = settings.dsi_deploy.to_h
    name = config.delete(:name)
    config[:environment] ||= Rails.env
    config[:domain] ||= (Settings[:hostname] || Settings[:host])
    @deploy = DSI::Deploy.new(name, config)
  end
  # This is the only interface rails_config expects -s hould return a Hash-like
  def load
    # TODO: turn into some sort of lazy lookup
    {
      'db' => {
        'password' => self.db_password,
        'host' => self.service(:db).target,
      },
      'redis' => {
        'url' => "redis://#{self.service(:redis).target}:#{self.service(:redis).port}"
      }
    }
  end
  EC2_METADATA_URI = URI('http://169.254.169.254/latest/user-data')
  def user_data
    @user_data ||= begin
      key, value = Net::HTTP.get(EC2_METADATA_URI).split('=', 2)
      # Single value only for now:
      {key.to_sym => value}
    end
  end

  def db_password
    Digest::MD5.hexdigest("#{user_data[:secret]}:db")
  end

  def service(name, proto=:tcp)
    @deploy.service(name, proto)
  end
end