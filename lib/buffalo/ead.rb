module EAD

  def self.series(hierarchy)
    if hierarchy['did'][0]['unitid']
      directory = hierarchy['did'][0]['unitid'][0].gsub(/\s/,"_")
    else
      directory = 'series'
    end
    title = hierarchy['did'][0]['unittitle'][0]
    id = hierarchy['id']
    if title.is_a? Hash
      Buffalo.append("..\\buffalo-dev\\html_tags.txt", "#{$title}\t#{directory}\t#{title}\n")
    end
    {:directory => directory, :title => title, :id => id}
  end

  def self.object(hierarchy)
    if hierarchy['did'][0]['unittitle']
      title = hierarchy['did'][0]['unittitle'][0]
    else
      title = ''
    end
    if hierarchy['did'][0]['unitid']
      id = hierarchy['did'][0]['unitid'][0]
    else
      id = ''
    end
    if hierarchy['did'][0]['unitdate']
      date = hierarchy['did'][0]['unitdate'][0]['content']
    else
      date = ''
    end
    if hierarchy['did'][0]['container']
      location1_type = hierarchy['did'][0]['container'][0]['type']
      location1_number = hierarchy['did'][0]['container'][0]['content']
      location1 = location1_type + ' ' + location1_number
      if hierarchy['did'][0]['container'][1]
        location2_type = hierarchy['did'][0]['container'][1]['type']
        location2_number = hierarchy['did'][0]['container'][1]['content']
        location2 = location2_type + ' ' + location2_number
      else
        if hierarchy['did'][0]['unitid']
          location2 = hierarchy['did'][0]['unitid'][0]
        else
          location2 = ''
        end
      end
    else
      location1 = ''
      location2 = ''
    end
    if title.is_a? Hash
      Buffalo.append("..\\buffalo-dev\\html_tags.txt", "#{$title}\t#{id}\t#{title}\n")
    end
    {:title => title, :id => id, :date => date, :location1 => location1, :location2 => location2}
  end

  def self.line(type, level = 0, content = {})
    case type
    when :collection
      hierarchy = Buffalo.hierarchy(level, content[:directory])
      data = ["#{content[:title]}","","","","",""]
    when :series
      hierarchy = Buffalo.hierarchy(level, content[:directory])
      data = ["#{content[:title]}","#{content[:id]}","","","",""]
    when :file
      hierarchy = Buffalo.hierarchy(level, 'file')
      data = ["#{content[:title]}","","#{content[:id]}","#{content[:date]}","#{content[:location1]}","#{content[:location2]}"]
    when :other
      hierarchy = Buffalo.hierarchy(level, 'other')
      data = ["#{content[:title]}","","#{content[:id]}","#{content[:date]}","#{content[:location1]}","#{content[:location2]}"]
    when :item
      hierarchy = Buffalo.hierarchy(level, 'item')
      data = ["#{content[:title]}","","#{content[:id]}","#{content[:date]}","#{content[:location1]}","#{content[:location2]}"]
    else # :header
      hierarchy = %w( H1 H2 H3 H4 H5 H6 )
      data = %w( dc.title aspaceID unitid unitdate location1 location2 )
    end
    hierarchy.push(*data)
  end

end