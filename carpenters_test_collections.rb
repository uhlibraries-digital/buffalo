require 'csv'
require 'hunting'
require './lib/buffalo.rb'
require './lib/buffalo/carpenters.rb'
require './lib/buffalo/ead.rb'
Hunting.configure_with('.\\config.yml')

def write_match(object, level)
  @match += 1
  @location.delete(object.pointer)
  @csv << Carpenters.line(:object, level, Carpenters.metadata(object))
  if object.type == 'compound'
    object.items.each do |pointer, item|
      @csv << Carpenters.line(:file, level + 1, {:filename => item.metadata['File Name'], :title => item.title})    
    end
  else
    @csv << Carpenters.line(:file, level + 1, {:filename => object.metadata['File Name'], :title => ''})
  end
end

def build(hierarchy, level)
  case hierarchy['level']
  when 'series'
    @csv << Carpenters.line(:series, level, EAD.series(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H3/H4 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'subseries'
    @csv << Carpenters.line(:series, level, EAD.series(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H3/H4 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'other level'
    if hierarchy['did'][0]['unitid'][0].downcase.include? 'sub'
      @csv << Carpenters.line(:series, level, EAD.series(hierarchy))
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
      object_location[:box] = Carpenters.box(@test.collections[@c_alias].objects[pointer].metadata['Original Item Location'])
      object_location[:folder] = Carpenters.folder(@test.collections[@c_alias].objects[pointer].metadata['Original Item Location'])
      ead_location[:box] = hierarchy['did'][0]['container'][0]['content'].to_i
      if hierarchy['did'][0]['container'][1]
        ead_location[:folder] = hierarchy['did'][0]['container'][1]['content'].to_i
      else
        ead_location[:folder] = Carpenters.folder(hierarchy['did'][0]['unitid'][0])
      end
      if @c_alias == 'p15195coll5'
        if object_location[:folder] == ead_location[:folder]
          write_match(@test.collections[@c_alias].objects[pointer], level)
        end
      else
        if object_location[:box] == ead_location[:box] and object_location[:folder] == ead_location[:folder]
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

source = '..\\buffalo-dev\\test_collection_ead'
destination = '..\\buffalo-dev\\test_collection_carpenters'

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

  @csv = CSV.open("#{destination}\\#{@c_alias}.csv", 'wb')
  @csv << Carpenters.line(:header)

  if @c_alias == 'p15195coll26'
    @title = @test.collections[@c_alias].name
    @csv << Carpenters.line(:collection, 1, {:directory => "Student_Art", :title => @title})
    @test.collections[@c_alias].objects.each do |pointer, object|
      @match += 1
      metadata = Carpenters.metadata(@test.collections[@c_alias].objects[pointer])
      @csv << Carpenters.line(:object, 2, metadata)
      if @test.collections[@c_alias].objects[pointer].type == 'compound'
        @test.collections[@c_alias].objects[pointer].items.each do |pointer, item|
          filename = item.metadata['File Name']
          @csv << Carpenters.line(:file, 3, {:filename => filename, :title => item.title})
        end
      else
        filename = @test.collections[@c_alias].objects[pointer].metadata['File Name']
        @csv << Carpenters.line(:file, 3, {:filename => filename, :title => ''})    
      end
    end
  else
    ead = XmlSimple.xml_in(open("#{source}\\#{@c_alias}.xml"))
    directory = ead['archdesc'][0]['did'][0]['unitid'][0]
    @title = ead['archdesc'][0]['did'][0]['unittitle'][0]
    @csv << Carpenters.line(:collection, 1, {:directory => directory, :title => @title})
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
      metadata = Carpenters.metadata(@test.collections[@c_alias].objects[pointer])
      metadata[:location] = location
      @csv << Carpenters.line(:unmatched_object, 5, metadata)
      if @test.collections[@c_alias].objects[pointer].type == 'compound'
        @test.collections[@c_alias].objects[pointer].items.each do |pointer, item|
          filename = item.metadata['File Name']
          @csv << Carpenters.line(:file, 6, {:filename => filename, :title => item.title})
        end
      else
        filename = @test.collections[@c_alias].objects[pointer].metadata['File Name']
        @csv << Carpenters.line(:file, 6, {:filename => filename, :title => ''})    
      end
    end
  end
  puts "Matched Objects for '#{@test.collections[@c_alias].name}': #{@match}/#{size}"
end
