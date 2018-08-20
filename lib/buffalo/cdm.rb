module CDM

  def self.metadata(object, elements, include = 'all')
    metadata = Hash.new
    elements.each do |element|
      if include == 'element_report'
        values = Hash.new
      else
        values = Array.new
      end
      element.crosswalk.each do |field|
        case include
        when 'all'
          CDM.push_values(values, CDM.get_values(object.metadata[field]))
          if object.type == 'compound'
            object.items.each do |pointer, object|
              CDM.push_values(values, CDM.get_values(object.metadata[field]))              
            end
          end
        when 'unique'
          CDM.push_unique_values(values, CDM.get_values(object.metadata[field]))
          if object.type == 'compound'
            object.items.each do |pointer, object|
              CDM.push_unique_values(values, CDM.get_values(object.metadata[field]))              
            end
          end
        when 'element_report'
          CDM.push_element_report_values(values, CDM.get_values(object.metadata[field]), field)
          if object.type == 'compound'
            object.items.each do |pointer, object|
              CDM.push_element_report_values(values, CDM.get_values(object.metadata[field]), field)              
            end
          end
        else
          # specify additional behavior?
        end
      end
      metadata[element.name] = values
    end
    metadata
  end

  def self.get_values(values)
    if values == nil
      array = ['']
    else
      array = values.strip.chomp(';').split(';')
    end
  end

  def self.push_values(array, values)
    values.each do |v|
      value = v.gsub("\t",' ').gsub("\n",' ').strip
      case value
      when ' '
        next
      when ''
        next
      else
        array.push(value)
      end
    end
  end

  def self.push_unique_values(array, values)
    values.each do |v|
      value = v.gsub("\t",' ').gsub("\n",' ').strip
      case value
      when ' '
        next
      when ''
        next
      else
        array.push(value) unless array.include?(value)
      end
    end
  end

  def self.push_element_report_values(hash, values, field)
    values.each do |v|
      value = v.gsub("\t",' ').gsub("\n",' ').strip
      case value
      when ' '
        next
      when ''
        next
      else
        hash[value] = field unless hash.has_key?(value)
      end
    end
  end

  def self.values_string(array, delimiter)
    values = String.new
    array.each { |v| values << v + delimiter + ' '}
    values.strip.chomp(delimiter)
  end

end