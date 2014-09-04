class DSI::Deploy::Node
  attr_reader :deploy, :role, :index
  def initialize(deploy, role, index)
    @deploy = deploy
    @role = role
    @index = index
  end
  def domain
    deploy.domain
  end
  def hostname
    deploy.hosts_pattern % {
      domain: domain,
      role: role,
      index: index
    }
  end
  def roles
    roles = [@role]
    if @role == deploy.migrator_role
      roles << :migrator
    end
    roles
  end
  def to_s
    "#<#{self.class} #{hostname}>"
  end
end