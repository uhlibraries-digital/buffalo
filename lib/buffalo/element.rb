class Element

  attr_reader :name, :label, :crosswalk

  def initialize(name, label, fields)
    @name = name
    @label = label
    @crosswalk = Array.new
    fields.each { |field| @crosswalk << field }
  end

end