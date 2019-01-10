module Report

  def self.carpenters(collection, elements, project)
    time = Time.now
    file_path = "#{project[:path]}\\#{collection.alias}_#{time.strftime('%Y%m%d_%H%M')}.carp"
    if project[:items].nil? then collection.hunt else collection.hunt(project[:items]) end

    puts "Writing #{collection.alias} Carpenters File..."
    if project[:archival] == 'true'
      Buffalo.write(file_path, Carp.archival(collection, elements, project).to_json)
    else
      Buffalo.write(file_path, Carp.standard(collection, elements, project).to_json)
    end
  end

  def self.migration_report(collection, elements, project = {path: "", cdm_domain: "", items: []})
    time = Time.now
    filename = "#{collection.alias}_#{time.strftime('%Y%m%d_%H%M')}"
    report = "#{project[:path]}/#{filename}.md"
    url = "http://#{project[:cdm_domain]}/collection/#{collection.alias}/item"
    thumbnail = "http://#{project[:cdm_domain]}/contentdm/image/thumbnail/#{collection.alias}"
    @count = 0

    if project[:items].nil?
      collection.hunt
    else
      collection.hunt(project[:items])
    end

    puts "Writing '#{collection.alias}' Migration Report... "
    Buffalo.write(report, "---\nlayout: template1"\
                          "\ntitle: #{collection.alias}"\
                          "\ncomments: false"\
                          "\n---\n\n\# #{collection.name}"\
                          "\n_#{filename}_\n\n")

    markdown = Builder::XmlMarkup.new(:indent => 2)
    markdown.table {
      markdown.tr {
        markdown.th('Object')
        markdown.th('File')
        elements.each { |element| markdown.th(element.label) }
      }
      collection.objects.each do |pointer, object|
        @count += 1
        if @count % 5 == 0
          markdown.tr {
            markdown.th('Object')
            markdown.th('File')
            elements.each { |element| markdown.th(element.label) }
          }
        end
        markdown.tr {
          markdown.td {
            markdown.a(:href => "#{url}/#{pointer}") {
              markdown.img(
                :src => "#{thumbnail}/#{pointer}",
                :alt => "#{collection.alias}/#{pointer} thumbnail"
              )
            }
          }
          markdown.td(object.metadata['File Name'])
          metadata = CDM.metadata(object, elements, 'unique')
          metadata.each do |element, values|
            if values.count > 1
              if element == 'title'
                markdown.td(values[0])
              else
                markdown.td {
                  markdown.ul {
                    values.each { |value| markdown.li(value) }
                  }
                }
              end
            elsif values.count == 1
              markdown.td(values[0])
            else
              markdown.td(:style => "background-color: \#e6e6e6")
            end
          end
          if object.type == 'compound'
            object_pointer = pointer
            object.items.each do |pointer, object|
              markdown.tr {
                markdown.td(object.metadata['File Name'])
                markdown.td {
                  markdown.a(:href => "#{url}/#{object_pointer}/show/#{pointer}") {
                    markdown.img(
                      :src => "#{thumbnail}/#{pointer}",
                      :alt => "#{collection.alias}/#{pointer} thumbnail"
                    )
                  }
                }
                metadata = CDM.metadata(object, elements)
                metadata.each do |element, values|
                  if values.count > 1
                    markdown.td {
                      markdown.ul {
                        values.each { |value| markdown.li(value) }
                      }
                    }
                  elsif values.count == 1
                    markdown.td(values[0])
                  else
                    markdown.td(:style => "background-color: \#e6e6e6")
                  end
                end
              }
            end
          end
        }
      end
    }
    markdown.br()
    markdown.br()
    Buffalo.append(report, markdown)
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

end
