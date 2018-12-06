module Report

  def self.carpenters(collection, elements, project)
    time = Time.now
    report = "#{project[:path]}\\#{collection.alias}_#{time.strftime('%Y%m%d_%H%M')}.carp"

    if project[:archival] == 'false'
      Buffalo.write(report, "{\"type\":\"standard\","\
                            "\"aic\":\"#{collection.alias}\","\
                            "\"collectionArkUrl\":\"#{project[:collection_uri]}\","\
                            "\"collectionTitle\":\"\","\
                            "\"objects\":[")
      if project[:items].nil?
        collection.hunt
      else
        collection.hunt(project[:items])
      end
      @object_size = collection.objects.size
      @object_count = 0
      puts "Writing #{collection.alias} Carpenters File..."
      collection.objects.each do |pointer, object|
        @object_count += 1
        Buffalo.append(report, "{\"uuid\":\"#{SecureRandom.uuid}\","\
                               "\"level\":\"item\","\
                               "\"dates\":[],"\
                               "\"containers\":[{\"type_1\":\"Item\","\
                                                "\"indicator_1\":#{@object_count}}],"\
                               "\"files\":[],"\
                               "\"productionNotes\":\"\","\
                               "\"do_ark\":\"\","\
                               "\"pm_ark\":\"\","\
                               "\"title\":\"#{object.metadata['Title']}\","\
                               "\"metadata\": {")
        metadata = CDM.metadata(object, elements)
        @metadata_size = metadata.size
        @metadata_count = 0
        metadata.each do |k,v|
          elements.each do |element|
            if element.name == k
              @namespace = element.namespace
            end
          end
          @metadata_count += 1
          Buffalo.append(report, "\"#{@namespace}.#{k}\":#{CDM.values_string(v,';').to_json}")
          Buffalo.append(report, ",") unless @metadata_count == @metadata_size
        end
        Buffalo.append(report, "}}")
        Buffalo.append(report, ",") unless @object_count == @object_size
      end
      Buffalo.append(report, "]}")

    else
      aspace = ASpace.new(project[:aspace][:endpoint], project[:aspace][:username], project[:aspace][:password])
      Buffalo.write(report, "{\"type\":\"findingaid\","\
                            "\"resource\":\"#{project[:collection_uri]}\","\
                            "\"collectionTitle\":\"\","\
                            "\"aic\":\"\","\
                            "\"objects\":[")
      if project[:items].nil?
        collection.hunt
      else
        collection.hunt(project[:items])
      end
      @object_size = collection.objects.size
      @object_count = 0
      @artificial_count = 0
      puts "Writing #{collection.alias} Carpenters File..."
      collection.objects.each do |pointer, object|
        @object_count += 1
        aspace_object = aspace.get_object(object.metadata['ArchivesSpace Identifier'])

        Buffalo.append(report, "{\"uuid\":\"#{SecureRandom.uuid}\",")
        level = aspace_object['level']
        if level == 'item'
          Buffalo.append(report, "\"title\":\"\","\
                                 "\"dates\":[],"\
                                 "\"containers\":[{\"type_1\":null,"\
                                                  "\"indicator_1\":null,"\
                                                  "\"type_2\":null,"\
                                                  "\"indicator_2\":null,"\
                                                  "\"type_3\":null,"\
                                                  "\"indicator_3\":null}],"\
                                 "\"uri\":\"#{object.metadata['ArchivesSpace Identifier']}\",")
        else
          @artificial_count += 1
          Buffalo.append(report, "\"title\":\"#{aspace_object['title']}\","\
                                 "\"dates\":[],"\
                                 "\"containers\":[{\"type_1\":\"Item\","\
                                                  "\"indicator_1\":#{@artificial_count},"\
                                                  "\"type_2\":null,"\
                                                  "\"indicator_2\":null,"\
                                                  "\"type_3\":null,"\
                                                  "\"indicator_3\":null}],"\
                                 "\"parent_uri\":\"#{object.metadata['ArchivesSpace Identifier']}\","\
                                 "\"artificial\":true,")
        end
        Buffalo.append(report,  "\"files\":[],"\
                                "\"productionNotes\":\"\","\
                                "\"do_ark\":\"\","\
                                "\"metadata\": {")
        metadata = CDM.metadata(object, elements)
        @metadata_size = metadata.size
        @metadata_count = 0
        metadata.each do |k,v|
          elements.each do |element|
            if element.name == k
              @namespace = element.namespace
            end
          end
          @metadata_count += 1
          Buffalo.append(report, "\"#{@namespace}.#{k}\":#{CDM.values_string(v,';').to_json}")
          Buffalo.append(report, ",") unless @metadata_count == @metadata_size
        end
        Buffalo.append(report, "}}")
        Buffalo.append(report, ",") unless @object_count == @object_size
      end
      Buffalo.append(report, "]}")
    end
  end

  def self.migrator(path, collection, elements, cdm_domain)
    report = "#{path}\\#{collection.name}.csv"
    url = "http://#{cdm_domain}/collection/#{collection.alias}/item"

    collection.hunt
    puts "Writing #{collection.name} CDM-Migrator Report..."
    CSV.open("#{report}", "wb") do |csv|
      csv << ['Object URL', 'Item URL', 'File Name']
      collection.objects.each do |pointer, object|
        csv << ["#{url}/#{pointer}", '', "#{object.metadata['File Name']}"]
        if object.type == 'compound'
          object_pointer = pointer
          object.items.each do |pointer, object|
            csv << ['', "#{url}/#{object_pointer}/show/#{pointer}", "#{object.metadata['File Name']}"]
          end
        end
      end
    end
  end

  def self.metadata_analysis(path, collection, elements, cdm_domain)
    report = "#{path}\\#{collection.name}.csv"
    url = "http://#{cdm_domain}/collection/#{collection.alias}/item"

    collection.hunt
    puts "Writing #{collection.name} Metadata Analysis..."
    CSV.open("#{report}", "wb") do |csv|
      csv << Report.analysis_header(elements)

      collection.objects.each do |pointer, object|
        row = ["#{url}/#{pointer}", '']
        metadata = CDM.metadata(object, elements)
        metadata.each do |element, values|
          row << CDM.values_string(values, ';')
        end
        csv << row
        if object.type == 'compound'
          object_pointer = pointer
          object.items.each do |pointer, object|
            row = ['', "#{url}/#{object_pointer}/show/#{pointer}"]
            metadata = CDM.metadata(object, elements)
            metadata.each do |element, values|
              row << CDM.values_string(values, ';')
            end
            csv << row
          end
        end
      end
    end
  end

  def self.migration(collection, elements, project = {path: "", cdm_domain: "", items: []})
    time = Time.now
    filename = "#{collection.alias}_#{time.strftime('%Y%m%d_%H%M')}"
    report = "#{project[:path]}/#{filename}.md"
    url = "http://#{project[:cdm_domain]}/collection/#{collection.alias}/item"
    thumbnail = "http://#{project[:cdm_domain]}/contentdm/image/thumbnail/#{collection.alias}"
    @count = 0

    Buffalo.write(report, "---\nlayout: template1\ntitle: #{collection.alias}\ncomments: false\n---\n\n\# #{collection.name}\n_#{filename}_\n\n")
    Buffalo.append(report, "<table>\n")
    Report.markdown_header(elements, report)

    if project[:items].nil?
      collection.hunt
    else
      collection.hunt(project[:items])
    end
    puts "Writing '#{collection.alias}' Migration Report..."

    collection.objects.each do |pointer, object|
      @count += 1
      if @count % 5 == 0
        Report.markdown_header(elements, report)
      end
      Buffalo.append(report, "<tr>\n")
      Buffalo.append(report, "<td><a href=\"#{url}/#{pointer}\"><img src=\"#{thumbnail}/#{pointer}\" alt=\"#{collection.alias}/#{pointer} thumbnail\" /></a></td>\n")
      Buffalo.append(report, "<td>#{object.metadata['File Name']}</td>\n")
      metadata = CDM.metadata(object, elements, 'unique')
      metadata.each do |element, values|
        if values.count > 1
          if element == 'title'
            Buffalo.append(report, "<td>#{values[0]}</td>\n")
          else
            Buffalo.append(report, "<td>\n")
            Buffalo.append(report, "<ul>\n")
            values.each {|value| Buffalo.append(report, "<li>#{value}</li>\n")}
            Buffalo.append(report, "</ul>\n")
            Buffalo.append(report, "</td>\n")
          end
        elsif values.count == 1
          # if values[0].include? 'public domain'
          #   Buffalo.append(report, "<td>Public Domain</td>\n")
          # elsif values[0].include? 'Educational use'
          #   Buffalo.append(report, "<td>Educational Use</td>\n")
          # elsif values[0].include? 'item is protected by copyright'
          #   Buffalo.append(report, "<td>In Copyright</td>\n")
          # elsif values[0].include? 'item may be protected by copyright'
          #   Buffalo.append(report, "<td>Rights Undertermined</td>\n")
          # else
            Buffalo.append(report, "<td>#{values[0]}</td>\n")
          # end
        else
          Buffalo.append(report, "<td style=\"background-color: #e6e6e6\"></td>\n")
        end
      end
      Buffalo.append(report, "</tr>\n")
      if object.type == 'compound'
        object_pointer = pointer
        object.items.each do |pointer, object|
          Buffalo.append(report, "<tr>\n")
          Buffalo.append(report, "<td>#{object.metadata['File Name']}</td>\n")
          Buffalo.append(report, "<td><a href=\"#{url}/#{object_pointer}/show/#{pointer}\"><img src=\"#{thumbnail}/#{pointer}\" alt=\"#{collection.alias}/#{pointer} thumbnail\" /></a></td>\n")
          metadata = CDM.metadata(object, elements)
          metadata.each do |element, values|
            if values.count > 1
              Buffalo.append(report, "<td>\n")
              Buffalo.append(report, "<ul>\n")
              values.each {|value| Buffalo.append(report, "<li>#{value}</li>\n")}
              Buffalo.append(report, "</ul>\n")
              Buffalo.append(report, "</td>\n")
            elsif values.count == 1
              Buffalo.append(report, "<td>#{values[0]}</td>\n")
            else
              Buffalo.append(report, "<td style=\"background-color: #e6e6e6\"></td>\n")
            end
          end
          Buffalo.append(report, "</tr>\n")
        end
      end
    end
    Buffalo.append(report, "<table>\n")
    filename
  end

  def self.element_list( collection, elements, project = {path:'', items:[]} )
    match_query = RDF::Query.new({
      :match => { RDF::URI("http://sindice.com/vocab/search#totalResults") => :result }
    })
    link_query = RDF::Query.new({
      :link => { RDF::URI("http://sindice.com/vocab/search#link") => :uri }
    })
    id_query = RDF::Query.new({
      :id => { RDF::URI("http://www.w3.org/2004/02/skos/core#exactMatch") => :ark }
    })

    if project[:items].nil?
      collection.hunt
    else
      collection.hunt(project[:items])
    end
    elements.each do |element|
      @values = Hash.new
      puts "Writing #{collection.name} \'#{element.label}\' List..."
      time = Time.now
      report = "#{project[:path]}\\#{collection.alias}_#{element.name}_#{time.strftime('%Y%m%d_%H%M')}.tsv"
      Buffalo.write(report, "CDM Field\t#{element.label}\tARK\n")
      collection.objects.each do |pointer, object|
        metadata = CDM.metadata(object, [element], 'element_report')
        metadata.each do |element, values|
          values.each { |k, v| @values[k] = v unless @values.has_key?(k) }
        end
      end
      sorted_keys = @values.keys.sort
      sorted_keys.each do |k|
        search = URI.escape("https://vocab.lib.uh.edu/search.ttl?depth=5&l=en&for=concept&q=#{k}&qt=exact&t=labels")
        search.gsub!("a\%CC\%81", "\%C3\%A1")
        search.gsub!("e\%CC\%81", "\%C3\%A9")
        search.gsub!("i\%CC\%81", "\%C3\%AD")
        search.gsub!("o\%CC\%81", "\%C3\%B3")
        search.gsub!("u\%CC\%81", "\%C3\%BA")
        begin
          graph = RDF::Graph.load("#{search}")
        rescue
          puts "ERROR: Cedar 501 for \'#{k}\'"
          puts search
          Buffalo.append(report, "#{k}\tquery failed\n")
          next
        end
        cdm_field = @values[k]
        results = match_query.execute(graph)
        if results.first[:result].to_i == 1
          link = link_query.execute(graph)
          id = id_query.execute(RDF::Graph.load("#{link.first[:uri]}.ttl"))
          Buffalo.append(report, "#{cdm_field}\t#{k}\t#{id.first[:ark]}\n")
        else
          Buffalo.append(report, "#{cdm_field}\t#{k}\t\n")
        end
      end
    end
  end

  def self.analysis_header(elements)
    header = ['Object', 'File']
    elements.each { |element| header << element.label }
    header
  end

  def self.markdown_header(elements, path)
    Buffalo.append(path, "<tr>\n")
    Buffalo.append(path, "<th>Object</th>\n")
    Buffalo.append(path, "<th>File</th>\n")
    elements.each { |element| Buffalo.append(path, "<th>#{element.label}</th>\n") }
    Buffalo.append(path, "</tr>\n")
  end

end
