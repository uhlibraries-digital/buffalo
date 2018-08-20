module Buffalo

  # Configuration defaults
  @config = { :dmwg => 'path/to/dmwg',
              :map => 'path/to/bcdams-map',
              :items => []}

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each do |key,value|
      if @valid_config_keys.include? key.to_sym
        @config[key.to_sym] = value
      end
    end
    @config
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    config = YAML::load(IO.read(path_to_yaml_file))
    configure(config)
  end

  def self.config
    @config
  end

  def self.write(path, content = '')
    File.open(path, 'w') do |f|
      f.print content
      f.close
    end
  end

  def self.append(path, content)
    File.open(path, 'a') do |f|
      f.print content
      f.close
    end
  end

end
