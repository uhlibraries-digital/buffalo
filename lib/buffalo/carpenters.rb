module Carpenters

  def self.line(type, level = 0, content = {})
    case type
    when :collection
      hierarchy = Buffalo.hierarchy(level, content[:directory])
      data = ["","","","","#{content[:title]}","","","","","","","","",""]
    when :series
      hierarchy = Buffalo.hierarchy(level, content[:directory])
      data = ["","","","","#{content[:title]}","#{content[:id]}","","","","","","","",""]
    when :object
      hierarchy = Buffalo.hierarchy(level)
      data = ["","","","","#{content[:title]}","","#{content[:creator]}","#{content[:contributor]}","#{content[:date]}","#{content[:description]}","#{content[:publisher]}","#{@title}","#{content[:rights]}",""]
    when :unmatched_object
      hierarchy = Buffalo.hierarchy(level)
      data = ["","","","","#{content[:title]}","#{content[:location]}","#{content[:creator]}","#{content[:contributor]}","#{content[:date]}","#{content[:description]}","#{content[:publisher]}","#{@title}","#{content[:rights]}",""]
    when :file
      hierarchy = Buffalo.hierarchy(level)
      data = ["#{content[:filename]}","","","","#{content[:title]}","","","","","","","","",""]
    else # :header
      hierarchy = %w( H1 H2 H3 H4 H5 H6 )
      data = %w( filename pm mm ac dc.title uhlib.aspaceID dcterms.creator dcterms.contributor dc.date dcterms.description dcterms.publisher dcterms.isPartOf dc.rights dcterms.accessRights )
    end
    hierarchy.push(*data)
  end

  def self.box(location)
    box_number = nil
    split_location = location.split(',')
    split_location.each do |container|
      container.strip!
      if container.downcase.include? 'box'
        split_container = container.split(/\s/)
        box_number = split_container[1].to_i
      end
    end
    box_number
  end

  def self.folder(location)
    folder_number = nil
    split_location = location.split(',')
    split_location.each do |container|
      container.strip!
      if container.downcase.include? 'folder'
        split_container = container.split(/\s/)
        folder_number = split_container[1].to_i
      end
    end
    folder_number
  end

  def self.metadata(object)
    creator = object.metadata['Creator (LCNAF)']
    creator.strip!
    creator.chomp!(';')
    creator == '' ? creator = object.metadata['Creator (HOT)'] : creator = creator + '; ' + object.metadata['Creator (HOT)']
    creator.strip!
    creator.chomp!(';')
    creator == '' ? creator = object.metadata['Creator (Local)'] : creator = creator + '; ' + object.metadata['Creator (Local)']
    creator.strip!
    creator.chomp!(';')
    contributor = object.metadata['Contributor (LCNAF)']
    contributor.strip!
    contributor.chomp!(';')
    contributor == '' ? contributor = object.metadata['Contributor (HOT)'] : contributor = creator + '; ' + object.metadata['Contributor (HOT)']
    contributor.strip!
    contributor.chomp!(';')
    contributor == '' ? contributor = object.metadata['Contributor (Local)'] : contributor = creator + '; ' + object.metadata['Contributor (Local)']
    contributor.strip!
    contributor.chomp!(';')

    { :title => object.title,
      :creator => creator,
      :contributor => contributor,
      :date => object.metadata['Date (ISO 8601)'],
      :description => object.metadata['Description'],
      :publisher => object.metadata['Publisher'],
      :rights => object.metadata['Use and Reproduction']
    }
  end

end
