module Buffalo

  def self.write(path, content = '')
    File.open(path, 'w') do |f|
      f.puts content
      f.close
    end
  end

  def self.append(path, content)
    File.open(path, 'a') do |f|
      f.puts content
      f.close
    end
  end

  def self.hierarchy(level, content = 'x')
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
    else # 6+
      ["","","","","","#{content}"]
    end
  end

end