class ASpace

  attr_reader :session, :base_url

  def initialize(base_url, user, password)
    @base_url = base_url
    response = HTTParty.post("#{base_url}/users/#{user}/login", body: {password: password})
    @session = response.parsed_response['session']
  end

  def get_object(uri)
    object = HTTParty.get("#{self.base_url}#{uri}", headers: {'X-ArchivesSpace-Session' => self.session})
  end

end