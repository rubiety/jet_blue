require "active_support/core_ext"
require "mechanize"

module JetBlue
  autoload :BluePass, "jet_blue/blue_pass"
  
  class InteractionError < StandardError; end
end