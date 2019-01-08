module Carp

  def self.archival(collection, elements, project)
    aspace = ASpace.new(
      project[:aspace]['endpoint'],
      project[:aspace]['username'],
      project[:aspace]['password']
    )
    resource = aspace.get_object(project[:collection_uri])
    carp_file = {}
    carp_file[:type] = 'findingaid'
    carp_file[:resource] = resource['uri']
    carp_file[:collectionTitle] = resource['title']
    carp_file[:aic] = ''
    objects = []
    collection.objects.each do |pointer, object|
      aspace_object = aspace.get_object(object.metadata['ArchivesSpace URI'])
      level = aspace_object['level']
      begin
        sub_container = aspace_object['instances'][0]['sub_container']
      rescue
        puts "sub_container Error: " + pointer.to_s
        puts aspace_object
        next
      end
      begin
        container = aspace.get_object(sub_container['top_container']['ref'])
      rescue
        puts "container Error: " + pointer.to_s
        puts aspace_object
        next
      end

      archival_object = {}
      archival_object[:uuid] = SecureRandom.uuid
      archival_object[:files] = []
      archival_object[:productionNotes] = "CDM: #{pointer}"

      dates = []
      if aspace_object['dates'].nil?
        continue
      else
        aspace_object['dates'].each {|date| dates << date['expression']}
      end
      archival_object[:dates] = dates

      containers = []
      if level == 'item'
        archival_object[:title] = aspace_object['title']
        archival_object[:uri] = aspace_object['uri']
        containers << {
          :top_container => {:ref => container['uri']},
          :type_1 => container['type'],
          :indicator_1 => container['indicator'],
          :type_2 => sub_container['type_2'],
          :indicator_2 => sub_container['indicator_2'],
          :type_3 => sub_container['type_3'],
          :indicator_3 => sub_container['indicator_3']
        }
      else
        archival_object[:artificial] = true
        archival_object[:title] = object.metadata['Title']
        archival_object[:parent_uri] = object.metadata['ArchivesSpace URI']
        archival_object[:level] = 'item'
        containers << {
          :type_1 => container['type'],
          :indicator_1 => container['indicator'],
          :type_2 => sub_container['type_2'],
          :indicator_2 => sub_container['indicator_2'],
          :type_3 => 'Item',
          :indicator_3 => pointer
        }
      end
      archival_object[:containers] = containers

      cdm_metadata = CDM.metadata(object, elements)
      archival_object[:metadata] = Carp.format_metadata(cdm_metadata, elements)
      objects << archival_object
    end
    carp_file[:objects] = objects
    carp_file
  end

  def self.standard(collection, elements, project)
    carp_file = {}
    carp_file[:type] = 'standard'
    carp_file[:resource] = {
      :title => project[:collection_uri],
      :sip_ark => '',
      :collectionArkUrl => project[:collection_uri],
      :vocabTitle => '',
      :collectionArk => project[:collection_uri].sub('https://id.lib.uh.edu/', ''),
      :aic => ''
    }
    carp_file[:collectionTitle] = ''
    carp_file[:collectionArkUrl] = project[:collection_uri]
    carp_file[:aic] = ''
    objects = []
    collection.objects.each do |pointer, object|
      standard_object = {}
      standard_object[:uuid] = SecureRandom.uuid
      standard_object[:title] = object.metadata['Title']
      standard_object[:dates] = []
      standard_object[:containers] = [{:type_1 => 'Item',:indicator_1 => pointer}]
      standard_object[:level] = 'item'
      standard_object[:productionNotes] = ''
      standard_object[:files] = []
      cdm_metadata = CDM.metadata(object, elements)
      standard_object[:metadata] = Carp.format_metadata(cdm_metadata, elements)
      objects << standard_object
    end
    carp_file[:objects] = objects
    carp_file
  end

  def self.format_metadata(cdm_metadata, elements)
    object_metadata = {}
    cdm_metadata.each do |label,value|
      elements.each do |element|
        if element.name == label
          @ns = element.namespace
        end
      end
      object_metadata["#{@ns}.#{label}"] = CDM.values_string(value,';')
    end
    object_metadata
  end

end
