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


namespace :web do
  %w[start stop restart reload].each do |command|
    desc "#{command} web-server"
    task command do
      on roles(:web) do
        execute :sudo, :service, fetch(:application), command
      end
    end
  end

  after 'deploy:finished', 'web:start-or-reload' do
    on roles(:web) do
      if capture(:sudo, :service, fetch(:application), :status) =~ /\w+\/running/
        execute :sudo, :service, fetch(:application), :reload
      else
        execute :sudo, :service, fetch(:application), :start
      end
    end
  end
end

namespace :workers do
  %w[start stop restart].each do |command|
    desc "#{command} worker service"
    task command do
      on roles(:worker) do
        execute :sudo, :service, "#{fetch(:application)}-workers", command
      end
    end
  end

  after 'deploy:finished', 'workers:start-or-restart' do
    on roles(:worker) do
      if test :sudo, :service, "#{fetch(:application)}-workers", :status
        execute :sudo, :service, "#{fetch(:application)}-workers", :restart
      else
        execute :sudo, :service, "#{fetch(:application)}-workers", :start
      end
    end
  end
end