module Crosswalk

  def self.elements(path, map)
    elements = Array.new
    crosswalk = YAML.load_file(path)
    crosswalk.each do |element|
      if map.elements.has_key? element[0].to_sym
        elements << Element.new(element[0], map.elements[element[0].to_sym]['label'], element[1])
      else
        puts "Element Not Found in MAP: #{element[0]}"
      end
    end
    elements
  end

end