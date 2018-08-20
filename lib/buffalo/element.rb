class Element

  attr_reader :name, :namespace, :label, :crosswalk

  def initialize(name, namespace, label, fields)
    @name = name
    @namespace = namespace
    @label = label
    @crosswalk = Array.new
    fields.each { |field| @crosswalk << field }
  end

end