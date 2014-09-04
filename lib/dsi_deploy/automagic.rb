class <<DSI::Deploy
  def auto_stage
    Rake.application.top_level_tasks # need to poke capistrano
    set :stage, (fetch(:branch_mapping)[fetch(:branch)] || fetch(:branch))

    if Rake::Task.task_defined?(fetch(:stage))
      DSI.log "Auto-set stage to #{fetch(:stage)} based on branch #{fetch(:stage)}"
      before 'ensure_stage', fetch(:stage)
      after 'load:defaults', 'fix-branch-var' do
        set :branch, fetch(:current_branch)
      end
    else
      DSI.warn "Stage was set to #{fetch(:stage)} based on branch #{fetch(:stage)}, but no stage task was defined."
    end
  end

  def auto_nodes
    fetch(:dsi_deploys).each do |deploy|
      deploy.nodes.each do |node|
        DSI.log "Auto-configuring node: server #{node.hostname}, roles: #{node.roles}, node: #{node}"
        server node.hostname, roles: node.roles, node: node
      end
    end
  end
end