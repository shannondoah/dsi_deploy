require 'hiera'
require 'dsi_deploy'

def dsi_parse_git_hostname(uri)
  URI.parse(uri).hostname
rescue URI::InvalidURIError
  # git@...:  type url, or so we hope
  uri[/\@(.*?):/, 1] or raise
end

set :branch, -> {
  `git symbolic-ref --short HEAD`.strip.to_sym
}

set :stage, -> {
  {
    develop: :staging,
    master: :production
  }[fetch(:branch)] or fetch(:branch)
}

set :rails_env, -> {fetch(:stage)}

set :hiera_config, 'hiera.yaml'

set :hiera, ->{
  Hiera.new(config: fetch(:hiera_config))
}

set :deploy_config, -> {
  fetch(:hiera).lookup("deploys", nil, {'environment' => fetch(:stage)}, nil, :hash)
}

set :dsi_deploys, -> {
  fetch(:deploy_config).map do |name, conf|
    DSI::Deploy.new(name, conf, self)
  end
}



fetch(:dsi_deploys).each do |deploy|
  deploy.nodes.each do |node|
    server node.hostname, roles: node.roles, node: node
  end
end
