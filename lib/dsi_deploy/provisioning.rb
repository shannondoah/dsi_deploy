require 'dsi_deploy/capistrano'
require 'aws-sdk'


SSHKit.config.output_verbosity=Logger::DEBUG


set :puppet_opts, -> {[
  "--modulepath=dev:modules",
  "--parser=future",
  "--hiera_config=#{fetch(:hiera_config)}",
]}

set :provision_file, "manifests/provisioning.pp"

set :node_manifest, '/etc/puppet/manifests/site.pp'

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
        # execute w/ stdout streaming is broken with run_locally...
        cmd  = [:puppet, :apply, fetch(:provision_file), args[:puppet_opts], *fetch(:puppet_opts)].join(' ')
        cmd = env_vars.map{|k,v| "#{k.upcase}=#{v}" }.join(' ') + ' ' + cmd
        puts "Exec: #{cmd}"
        exec( cmd )
      end
    end
  end

  desc "Query or set an AWS resource"
  task :resource, [:resource, :title] do |t, args|
    run_locally do
      env_vars = {:FACTER_environment => fetch(:stage)}
      with env_vars do
        execute :puppet, :resource, args[:resource], args[:title], *fetch(:puppet_opts)
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


  desc "One-time setup for new nodes."
  task :setup , [:giturl, :githost, :gitident] do  |t, args|
    opts = args.to_hash
    run_locally do
      opts[:giturl] ||= capture :git, :config, 'remote.origin.url'
      opts[:githost] ||= dsi_parse_git_hostname(opts[:giturl])
      opts[:gitident] ||= capture(:'ssh-keyscan', '-H', opts[:githost])
    end

    on roles(:all) do |server|
      node =  server.properties.node
      sudo :hostname, node.hostname
      sudo :sh, '-c', "'echo #{node.hostname} > /etc/hostname'"
      sudo :'apt-get', :install, '-y', 'git', 'puppet-common'
      unless test "[ -d /etc/puppet/.git ]"
        if test "[ -d /etc/puppet ]"
          sudo :mv, '/etc/puppet', '/etc/puppet.orig'
        end
        sudo :mkdir, '/etc/puppet'
        me = capture(:whoami)
        sudo :chown, me, '/etc/puppet'
        execute "echo '#{opts[:gitident]}' >> ~/.ssh/known_hosts"
        execute :git, :clone, '-b', fetch(:branch), opts[:giturl] ,'/etc/puppet'
      end
      s = StringIO.new <<-CONF
[main]
environment=#{fetch(:rails_env)}
CONF
      upload! s, '/etc/puppet/puppet.conf'
    end
  end


  desc "Pull puppet repo remotely"
  task :pull do
    on roles(:all) do
      within '/etc/puppet' do
        execute :git, :pull
      end
    end
  end
  after :setup, :pull

  desc "Apply local puppet manifest"
  task :apply do
    on roles(:all) do
      within '/etc/puppet' do
        sudo :puppet, :apply, '--modulepath=modules', fetch(:node_manifest)
      end
    end
  end


end
