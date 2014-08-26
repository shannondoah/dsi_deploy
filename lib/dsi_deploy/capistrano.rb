require 'hiera'
require 'dsi_deploy'

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

