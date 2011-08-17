module JetBlue
  module BluePass
    
    mattr_accessor :base_url, :logger
    self.base_url = "https://jetpack.jetblue.com/"
    
    mattr_accessor :logger
    self.logger = Logger.new(STDOUT)
    
    mattr_accessor :username
    mattr_accessor :password
    
    if settings = YAML.load_file(File.join(File.dirname(__FILE__), "../../config/jet_blue.yml"))
      self.username = settings["username"]
      self.password = settings["password"]
    end
    
    autoload :Flight, "jet_blue/blue_pass/flight"
    autoload :Session, "jet_blue/blue_pass/session"
  end
end