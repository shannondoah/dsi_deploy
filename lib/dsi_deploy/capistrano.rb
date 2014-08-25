require 'hiera'

unless fetch(:stage)
	puts "Auto-set stage"
	set :stage, :test
end

set :hiera_config, 'hiera.yaml'

set :hiera do
	Hiera.new(config: fetch(:hiera_config))
end

task :default do
  run_locally do
  	puts 'deploy info:'
    puts fetch(:hiera).lookup("deploy")
  end
end
