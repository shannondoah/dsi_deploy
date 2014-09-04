require "dsi_deploy/version"
require 'base64'

module DSI
  class <<self
    def log(msg)
      # If there is a way to detect --quiet at load-time (I've tried and failed to find it), this
      # would be the place to check for it.
      puts "[DSI::Deploy]: #{msg}"
    end

    def warn(msg)
      Kernel::warn "[DSI::Deploy (!)]: #{msg}"
    end

    def parse_git_hostname(uri)
      URI.parse(uri).hostname
    rescue URI::InvalidURIError
      # git@...:  type url, or so we hope
      uri[/\@(.*?):/, 1] or raise
    end

  end

  class Deploy
  end
end

require "dsi_deploy/node"
require "dsi_deploy/deploy"