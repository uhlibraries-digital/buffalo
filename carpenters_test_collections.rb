require 'csv'
require 'hunting'
Hunting.configure_with('.\\config.yml')

def write(name, content)
  File.open(name, 'w') do |f|
    f.puts content
    f.close
  end
end

def append(name, content)
  File.open(name, 'a') do |f|
    f.puts content
    f.close
  end
end

def series_content(hierarchy)
  directory = hierarchy['did'][0]['unitid'][0].gsub(/\s/,"_")
  title = hierarchy['did'][0]['unittitle'][0]
  id = hierarchy['id']
  {:directory => directory, :title => title, :id => id}
end

def object_content(object)
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

def write_match(object, level)
  @match += 1
  @location.delete(object.pointer)
  @csv << write_line(:object, level, object_content(object))
  if object.type == 'compound'
    object.items.each do |pointer, item|
      @csv << write_line(:file, level + 1, {:filename => item.metadata['File Name'], :title => item.title})    
    end
  else
    @csv << write_line(:file, level + 1, {:filename => object.metadata['File Name'], :title => ''})
  end
end

def write_line(type, level = 0, content = {})
  case type
  when :collection
    hierarchy = construct_hierarchy(level, content[:directory])
    data = ["","","","","#{content[:title]}","","","","","","","","",""]
  when :series
    hierarchy = construct_hierarchy(level, content[:directory])
    data = ["","","","","#{content[:title]}","#{content[:id]}","","","","","","","",""]
  when :object
    hierarchy = construct_hierarchy(level)
    data = ["","","","","#{content[:title]}","","#{content[:creator]}","#{content[:contributor]}","#{content[:date]}","#{content[:description]}","#{content[:publisher]}","#{@title}","#{content[:rights]}",""]
  when :unmatched_object
    hierarchy = construct_hierarchy(level)
    data = ["","","","","#{content[:title]}","#{content[:location]}","#{content[:creator]}","#{content[:contributor]}","#{content[:date]}","#{content[:description]}","#{content[:publisher]}","#{@title}","#{content[:rights]}",""]
  when :file
    hierarchy = construct_hierarchy(level)
    data = ["#{content[:filename]}","","","","#{content[:title]}","","","","","","","","",""]
  else # :header
    hierarchy = %w( H1 H2 H3 H4 H5 H6 )
    data = %w( filename pm mm ac dc.title uhlib.aspaceID dcterms.creator dcterms.contributor dc.date dcterms.description dcterms.publisher dcterms.isPartOf dc.rights dcterms.accessRights )
  end
  hierarchy.push(*data)
end

def construct_hierarchy(level, content = 'x')
  case level
  when 1
    ["#{content}","","","","",""]
  when 2
    ["","#{content}","","","",""]
  when 3
    ["","","#{content}","","",""]
  when 4
    ["","","","#{content}","",""]
  when 5
    ["","","","","#{content}",""]
  else # 6
    ["","","","","","#{content}"]
  end
end

def box(location)
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

def folder(location)
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


def build(hierarchy, level)
  case hierarchy['level']
  when 'series'
    @csv << write_line(:series, level, series_content(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H3/H4 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'subseries'
    @csv << write_line(:series, level, series_content(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H3/H4 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'other level'
    if hierarchy['did'][0]['unitid'][0].downcase.include? 'sub'
      @csv << write_line(:series, level, series_content(hierarchy))
      if hierarchy['c'].nil?
        # '--- no H5 data ---'
      else
        hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
      end
    end
  when 'file'
    @location.each do |pointer|
      object_location = {}
      ead_location = {}
      object_location[:box] = box(@test.collections[@c_alias].objects[pointer].metadata['Original Item Location'])
      object_location[:folder] = folder(@test.collections[@c_alias].objects[pointer].metadata['Original Item Location'])
      ead_location[:box] = hierarchy['did'][0]['container'][0]['content'].to_i
      if hierarchy['did'][0]['container'][1]
        ead_location[:folder] = hierarchy['did'][0]['container'][1]['content'].to_i
      else
        ead_location[:folder] = folder(hierarchy['did'][0]['unitid'][0])
      end
      if @c_alias == 'p15195coll5'
        if (object_location[:folder] == ead_location[:folder])
          write_match(@test.collections[@c_alias].objects[pointer], level)
        end
      else
        if ((object_location[:box] == ead_location[:box])&&(object_location[:folder] == ead_location[:folder]))
          write_match(@test.collections[@c_alias].objects[pointer], level)
        end        
      end
    end
  when 'item'
    if hierarchy['did'][0]['container'][1].nil?
    else
    end
  else
  end
end

collections = %w( p15195coll5 p15195coll17 p15195coll2 p15195coll10 p15195coll26 p15195coll4 hca30 ville)
puts ''
@test = Repository.scout(collections)
collections.each do |c_alias|
  puts ''
  @c_alias = c_alias
  size = @test.collections[@c_alias].size
  @test.collections[@c_alias].hunt
  @location = []
  no_location = []
  @test.collections[@c_alias].objects.each do |pointer, object|
    if object.metadata['Original Item Location'] == ''
      no_location.push(pointer)
    else
      @location.push(pointer)
    end
  end
  @match = 0

  @csv = CSV.open("#{@c_alias}.csv", 'wb')
  @csv << write_line(:header)

  if @c_alias == 'p15195coll26'
    @title = @test.collections[@c_alias].name
    @csv << write_line(:collection, 1, {:directory => "Student_Art", :title => @title})
    @test.collections[@c_alias].objects.each do |pointer, object|
      @match += 1
      object_metadata = object_content(@test.collections[@c_alias].objects[pointer])
      @csv << write_line(:object, 2, object_metadata)
      if @test.collections[@c_alias].objects[pointer].type == 'compound'
        @test.collections[@c_alias].objects[pointer].items.each do |pointer, item|
          filename = item.metadata['File Name']
          @csv << write_line(:file, 3, {:filename => filename, :title => item.title})
        end
      else
        filename = @test.collections[@c_alias].objects[pointer].metadata['File Name']
        @csv << write_line(:file, 3, {:filename => filename, :title => ''})    
      end
    end
  else
    ead = XmlSimple.xml_in(open(".\\test_collection_ead\\#{@c_alias}.xml"))
    directory = ead['archdesc'][0]['did'][0]['unitid'][0]
    @title = ead['archdesc'][0]['did'][0]['unittitle'][0]
    @csv << write_line(:collection, 1, {:directory => directory, :title => @title})
    ead['archdesc'][0]['dsc'].each do |collection|
      if collection['c'].nil?
        # '--- no H2 data ---'
      else
        collection['c'].each do |hierarchy|
          build(hierarchy, 2)
        end
      end
    end
    no_location.push(*@location)
    @csv << ["NO MATCH","*","*","*","*","*","*","*","*","*","*","*","*","*","*","*","*","*","*","*"]
    no_location.each do |pointer|
      location = @test.collections[@c_alias].objects[pointer].metadata['Original Item Location']
      object_metadata = object_content(@test.collections[@c_alias].objects[pointer])
      object_metadata[:location] = location
      @csv << write_line(:unmatched_object, 5, object_metadata)
      if @test.collections[@c_alias].objects[pointer].type == 'compound'
        @test.collections[@c_alias].objects[pointer].items.each do |pointer, item|
          filename = item.metadata['File Name']
          @csv << write_line(:file, 6, {:filename => filename, :title => item.title})
        end
      else
        filename = @test.collections[@c_alias].objects[pointer].metadata['File Name']
        @csv << write_line(:file, 6, {:filename => filename, :title => ''})    
      end
    end
  end
  puts "Matched Objects for '#{@test.collections[@c_alias].name}': #{@match}/#{size}"
end
