class Container < ActiveRecord::Base
  include Authorizable
  include Taxonomix

  belongs_to :compute_resource
  belongs_to :registry, :class_name => "DockerRegistry", :foreign_key => :registry_id
  has_many :environment_variables, :dependent  => :destroy, :foreign_key => :reference_id,
                                   :inverse_of => :container,
                                   :class_name => 'EnvironmentVariable',
                                   :validate => false
  accepts_nested_attributes_for :environment_variables, :allow_destroy => true
  include ForemanDocker::ParameterValidators

  scoped_search :on => :name

  attr_accessible :command, :repository_name, :name, :compute_resource_id, :entrypoint,
                  :cpu_set, :cpu_shares, :memory, :tty, :attach_stdin, :registry_id,
                  :attach_stdout, :attach_stderr, :tag, :uuid, :environment_variables_attributes,
                  :katello

  def repository_pull_url
    repo = tag.blank? ? repository_name : "#{repository_name}:#{tag}"
    repo = registry.prefixed_url(repo) if registry
    repo
  end

  def parametrize
    { 'name'  => name, # key has to be lower case to be picked up by the Docker API
      'Image' => repository_pull_url,
      'Tty'          => tty,                    'Memory'       => memory,
      'Entrypoint'   => entrypoint.try(:split), 'Cmd'          => command.try(:split),
      'AttachStdout' => attach_stdout,          'AttachStdin'  => attach_stdin,
      'AttachStderr' => attach_stderr,          'CpuShares'    => cpu_shares,
      'Cpuset'       => cpu_set,
      'Env' => environment_variables.map { |env| "#{env.name}=#{env.value}" } }
  end

  def in_fog
    @fog_container ||= compute_resource.vms.get(uuid)
  end

  def self.humanize_class_name(_name = nil)
    _("Docker/Container")
  end
end
