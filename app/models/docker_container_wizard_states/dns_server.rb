module DockerContainerWizardStates
  class DnsServer < Parameter
    belongs_to :environment, :foreign_key => :reference_id, :inverse_of => :dns_servers,
               :class_name => 'DockerContainerWizardStates::Environment'
    validates :name, :uniqueness => { :scope => :reference_id }
  end
end
