class Map

  attr_reader :elements

  def initialize(data)
    @elements = Hash.new
    data.each do |element|
      e = element['name'].to_sym
      @elements[e] = element
    end
  end

end