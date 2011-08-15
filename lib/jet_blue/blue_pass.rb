module JetBlue
  module BluePass
    
    mattr_accessor :base_url, :logger
    self.base_url = "https://jetpack.jetblue.com/"
    
    mattr_accessor :logger
    self.logger = Logger.new(STDOUT)
    
    mattr_accessor :username
    mattr_accessor :password
    mattr_accessor :corp_id
    self.corp_id = "BOS02"
    
    autoload :Flight, "jet_blue/blue_pass/flight"
  end
end