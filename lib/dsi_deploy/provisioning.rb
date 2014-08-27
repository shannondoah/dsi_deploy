require 'dsi_deploy/capistrano'
require 'aws-sdk'


# SSHKit.config.output_verbosity=Logger::DEBUG


set :puppet_opts, -> {[
  "--modulepath=dev:modules",
  "--parser=future",
  "--hiera_config=#{fetch(:hiera_config)}",
]}

set :provision_file, "manifests/provisioning.pp"

set :ssh_keys_path, "~/.ssh"

namespace :dsi do
  desc "Run provsisioning recipe against AWS"
  task :provision, [:puppet_opts, :aws_profile] do |t, args|
    run_locally do
      env_vars = {:FACTER_environment => fetch(:stage)}
      fetch(:dsi_deploys).each do |deploy|
        env_vars["FACTER_#{deploy.underscore_name}_deploy_secret"] = deploy.secret
      end
      if args[:aws_profile]
        env_vars[:aws_profile] = args[:aws_profile]
      end
      with env_vars do
        puts capture( :puppet, :apply, fetch(:provision_file), args[:puppet_opts], *fetch(:puppet_opts))
      end
    end
  end

  desc "Generate a key pair for each configured deploy and download them."
  task :generate_keys do
    run_locally do
      ec2 = AWS::EC2.new
      fetch(:dsi_deploys).each do |deploy|
        pair = ec2.regions[deploy.region].key_pairs.create(deploy.underscore_name)
        File.open(deploy.ssh_key_file, 'w') do |file|
          file.write(pair.private_key)
        end
        File.chmod(0700, deploy.ssh_key_file)
        puts "Downloaded deploy key for #{deploy.underscore_name} to #{deploy.ssh_key_file}"
      end
    end
  end
end
