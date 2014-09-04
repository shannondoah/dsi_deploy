require 'hiera'
require 'dsi_deploy'

require 'dsi_deploy/automagic'



set :branch, -> {
  `git symbolic-ref --short HEAD`.strip.to_sym
}

set :rails_env, -> {fetch(:stage)}
set :environment, -> {fetch(:stage)}

set :hiera_config, 'hiera.yaml'

set :branch_mapping,  {
  develop: :staging,
  master: :production
}

set :hiera, ->{
  Hiera.new(config: fetch(:hiera_config)) if File.exists?(fetch(:hiera_config))
}

set :deploy_config, -> {
  if fetch(:hiera)
    fetch(:hiera).lookup("deploys", nil, {'environment' => fetch(:environment)}, nil, :hash)
  else
    {fetch(:application) => {"domain" => fetch(:domain)}}
  end
}

set :dsi_deploys, -> {
  fetch(:deploy_config).map do |name, conf|
    DSI::Deploy.new(name, conf, self)
  end
}
