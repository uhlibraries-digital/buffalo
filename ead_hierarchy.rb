require 'csv'
require 'xmlsimple'
require './lib/buffalo.rb'
require './lib/buffalo/ead.rb'

def build(hierarchy, level)
  case hierarchy['level']
  when 'series'
    @csv << EAD.line(:series, level, EAD.series(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H3 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'subseries'
    @csv << EAD.line(:series, level, EAD.series(hierarchy))
    if hierarchy['c'].nil?
      # '--- no H4 data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'other level'
    if hierarchy['did'][0]['unitid'][0].downcase.include? 'series'
      @csv << EAD.line(:series, level, EAD.series(hierarchy))
    else
      @csv << EAD.line(:other, level, EAD.object(hierarchy))      
    end
    if hierarchy['c'].nil?
      # '--- no H5+ data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'file'
    @csv << EAD.line(:file, level, EAD.object(hierarchy))    
    if hierarchy['c'].nil?
      # '--- no H5+ data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  when 'item'
    @csv << EAD.line(:item, level, EAD.object(hierarchy))    
    if hierarchy['c'].nil?
      # '--- no H5+ data ---'
    else
      hierarchy['c'].each {|hierarchy| build(hierarchy, level + 1)}
    end
  else
  end
end

report = '..\\buffalo-dev'
source = '..\\buffalo-dev\\ead'
destination = '..\\buffalo-dev\\ead_hierarchy'
Buffalo.write("#{report}\\empty_finding_aids.txt", "COLLECTION\n")
Buffalo.write("#{report}\\html_tags.txt", "COLLECTION\tID\tTITLE\n")

Dir.foreach(source) do |ead_file|
  next if ead_file == '.' or ead_file == '..'
  puts "Processing #{ead_file}"
  name = File.basename(ead_file, '.xml')
  @csv = CSV.open("#{destination}\\#{name}.csv", 'wb')
  @csv << EAD.line(:header)

  ead = XmlSimple.xml_in(open("#{source}\\#{ead_file}"))
  directory = ead['archdesc'][0]['did'][0]['unitid'][0]
  $title = ead['archdesc'][0]['did'][0]['unittitle'][0]
  @csv << EAD.line(:collection, 1, {:directory => directory, :title => @title})
  ead['archdesc'][0]['dsc'].each do |collection|
    if collection['c'].nil?
      # '--- no H2 data ---'
      puts 'EMPTY FINDING AID'
      Buffalo.append("#{report}\\empty_finding_aids.txt", "#{name}\n")
      @csv.close
      File.delete("#{destination}\\#{name}.csv")
    else
      collection['c'].each do |hierarchy|
        build(hierarchy, 2)
      end
    end
  end
end
