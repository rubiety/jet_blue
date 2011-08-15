module JetBlue
  module BluePass
    class Flight
      attr_accessor :number
      attr_accessor :status
      attr_accessor :origin_airport_code
      attr_accessor :destination_airport_code
      attr_accessor :start_at
      attr_accessor :end_at
      attr_accessor :actual_start_at
      attr_accessor :actual_end_at
      attr_accessor :plane
      attr_accessor :stops
      attr_accessor :logger
      
      cattr_accessor :logger
      self.logger = JetBlue::BluePass.logger
      
      def initialize(attributes = {})
        attributes.each {|k,v| send("#{key}=", v) if respond_to?("#{key}=") }
        self.logger ||= JetBlue::BluePass.logger
        self
      end
      
      def to_s
        "#{number} #{origin_airport_code}->#{destination_airport_code} on #{start_at}"
      end
      
      def self.all(options = {})
        raise ArgumentError, "Origin :from airport required (3-letter code)." unless options[:from] =~ /.../
        raise ArgumentError, "Destination :to airport required (3-letter code)" unless options[:to] =~ /.../
        raise ArgumentError, "Starting date required." unless options[:start]
        raise ArgumentError, "Ending date required." if options[:return] && !options[:end]
        
        login_page = mechanize.get(JetBlue::BluePass.base_url)
        dashboard = login_page.form_with(:name => /login/i) do |f|
          f.field_with(:name => /accountID/i).value = JetBlue::BluePass.username
          f.field_with(:name => /password/i).value = JetBlue::BluePass.password
        end.click_button
        
        unless dashboard
          logger.warn "  !! RAISED InteractionError: Unable to log in."
          raise JetBlue::InteractionError.new("Unable to log in.")
        end
        
        url = "#{JetBlue::BluePass.base_url}/meridia?page=requestAirMessage_air&action=airRequest&posid=C5VE&corpID=#{JetBlue::BluePass.corp_id}&realRequestAir=realRequestAir&direction=#{options[:return] ? 'returntravel' : 'onewaytravel'}&From=#{options[:from].upcase}&depDay=#{options[:start].day}&depMonth=#{options[:start].strftime('%b').upcase}&depTime=anytime&To=#{options[:to].upcase}&retDay=#{options[:end].try(:day)}&retMonth=#{options[:end].try(:strftime, '%b').to_s.upcase}&retTime=anytime&ADT=1&INF=0&maxumnr=1&UMNR=0&flightType=1&actionType=nonFlex"
        logger.info "URL: #{url}"
        
        mechanize.get(url) do |page|
          out_table = page.search("#bfm_tbl_out")[0]
          out_flight_rows = out_table.css("tr")[2..-1]
          
          # back_table = page.search("#bfm_tbl_in")[0]
          # back_flight_rows = table.css("tr")[2..-1]
          
          return out_flight_rows.map do |flight_row|
            columns = flight_row.css("td")
            raise JetBlue::InteractionError, "Expected 5 columns but got #{columns.size}." if columns.size != 5
            
            new(
              :origin_airport_code => options[:from],
              :destination_airport_code => options[:to],
              :number => columns[2].css("span.matrix_flight_num")[0].try(:content).try(:strip),
              :start_at => columns[0].css("p")[0].try(:content).try(:strip),
              :end_at => columns[1].css("p")[0].try(:content).try(:strip),
              :plane => columns[2].css("span.matrix_flight_equip")[0].try(:content).try(:strip),
              :stops => columns[3].try(:content).try(:strip),
              :booking_form => page.forms.first,
              :booking_selector => columns[4].css("input[type=radio]")
            )
          end
        end
      end
      
      def book!
        
      end
      
      
      protected
      
      def self.mechanize
        @mechanize ||= Mechanize.new.tap do |m|
          m.user_agent_alias = 'Mac Safari'
        end
      end
      
      def mechanize
        @mechanize ||= Mechanize.new.tap do |m|
          m.user_agent_alias = 'Mac Safari'
        end
      end
    end
  end
end