module Carp

  def self.archival(collection, elements, project)
    aspace = ASpace.new(project[:aspace]['endpoint'], project[:aspace]['username'], project[:aspace]['password'])
    resource = aspace.get_object(project[:collection_uri])
    report = {}
    report[:type] = 'findingaid'
    report[:resource] = resource['uri']
    report[:collectionTitle] = resource['title']
    report[:aic] = ''
    objects = []
    collection.objects.each do |pointer, object|
      aspace_object = aspace.get_object(object.metadata['ArchivesSpace URI'])
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
      level = aspace_object['level']
      dates = []
      if level == 'item'
        if aspace_object['dates'].nil?
          continue
        else
          aspace_object['dates'].each {|date| dates << date['expression']}
        end
        archival_object[:title] = aspace_object['title']
        archival_object[:dates] = dates
        containers = []
        containers << {:top_container => {:ref => container['uri']},
                       :type_1 => container['type'],
                       :indicator_1 => container['indicator'],
                       :type_2 => sub_container['type_2'],
                       :indicator_2 => sub_container['indicator_2'],
                       :type_3 => sub_container['type_3'],
                       :indicator_3 => sub_container['indicator_3']}
        archival_object[:containers] = containers
        archival_object[:uri] = aspace_object['uri']
      else
        # artificial items attached to parent
      end
      archival_object[:files] = []
      archival_object[:productionNotes] = ''
      archival_object[:do_ark] = ''
      archival_object_metadata = {}
      metadata = CDM.metadata(object, elements)
      metadata.each do |k,v|
        elements.each do |element|
          if element.name == k
            @namespace = element.namespace
          end
        end
        archival_object_metadata["#{@namespace}.#{k}"] = CDM.values_string(v,';')
      end
      archival_object[:metadata] = archival_object_metadata
      objects << archival_object
    end
    report[:objects] = objects
    report
  end

  def self.standard(collection, elements, project)
    #  standard project report
  end

end
