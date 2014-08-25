require 'hiera'

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

set :deploys, -> {
  fetch(:hiera).lookup("deploys", nil, {'environment' => fetch(:stage)}, nil, :hash)
}

