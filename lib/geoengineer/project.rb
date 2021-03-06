########################################################################
# Projects are groups of resources used to organize and validate.
#
# A Project contains resources, has arbitrary attributes and validation rules
########################################################################
class GeoEngineer::Project
  include HasAttributes
  include HasLifecycle
  include HasResources
  include HasTemplates
  include HasSubResources
  include HasValidations

  attr_accessor :org, :name
  attr_reader :environment

  validate -> { environments.nil? ? "Project #{full_name} must have an environment" : nil }
  validate -> { all_resources.map(&:errors).flatten }

  def initialize(org, name, environment, &block)
    @org = org
    @name = name
    @environment = environment
    instance_exec(self, &block) if block_given?
    execute_lifecycle(:after, :initialize)
  end

  def full_id_name
    "#{org}_#{name}".tr('-', '_')
  end

  def full_name
    "#{org}/#{name}"
  end

  def resource(type, id, &block)
    return find_resource(type, id) unless block_given?
    resource = create_resource(type, id, &block)
    resource.project = self
    resource.environment = @environment
    resource
  end

  def all_resources
    [resources, all_template_resources].flatten
  end

  # dot method
  def to_dot
    str = ["  subgraph \"cluster_#{full_id_name}\" {"]
    str << "    style = filled; color = lightgrey;"
    str << "    label = <<B><FONT POINT-SIZE=\"24.0\">#{full_name}</FONT></B>>"
    nodes = all_resources.map do |res|
      "    node [label=#{res.short_name.inspect}, shape=\"box\"] #{res.to_ref.inspect};"
    end
    str << nodes
    str << "  }"
    str.join(" // #{full_name} \n")
  end
end
