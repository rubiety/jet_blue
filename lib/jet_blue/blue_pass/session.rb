module JetBlue
  module BluePass
    class Session
      require 'capybara'
      require 'capybara/dsl'

      Capybara.default_driver = :selenium
      Capybara.app_host = JetBlue::BluePass.base_url
      Capybara.run_server = false
      
      include Capybara::DSL
      
      attr_accessor :home_path
      
      def initialize
        login
      end
      
      def login
        visit("/")
        within("form#frmLogin") do
          fill_in "accountID", :with => JetBlue::BluePass.username
          fill_in "password", :with => JetBlue::BluePass.password
        end
        
        find("input.login_btn[type=button]").click
        self.home_path = Capybara.current_session.current_path
      end
      
      def logout
        page.evaluate_script('window.confirm = function() { return true; }')
        page.evaluate_script('window.alert = function() { return true; }')
        
        within("ul.navigation") do
          click_link("Logout")
        end
      end
      
      def reservations
        all("div.tripReview div.usrHomePageBg").map do |entry|
          columns = entry.all("div.column")
          
          JetBlue::BluePass::Flight.new(
            :start_at => Date.parse(columns[0].text.strip),
            :origin_airport_code => columns[1].first("p").text.strip.scan(/\((...)\)/).flatten[0],
            :end_at => nil,
            :destination_airport_code => columns[3].first("p").text.strip.scan(/\((...)\)/).flatten[0],
            :confirmation_code => columns[5].first("p").text.strip
          )
        end
      end
      
      def find_flights(origin, destination, date, return_date = nil)
        click_link("Find Flights")
        
        if return_date
          choose "Round Trip"
        else
          choose "One-Way"
        end
        
        select origin, :from => "departCity"
        select destination, :from => "returnCity"
        select date.day.to_s, :from => "depDay"
        select date.strftime("%b").to_s, :from => "depMonth"
        
        if return_date
          select return_date.day.to_s, :from => "retDay"
          select return_date.strftime("%b").to_s, :from => "retMonth"
        end
        
        within("div.button") do
          find("input[value=Search]").click
        end
        
        out_flight_rows = all("table#bfm_tbl_out > tbody > tr")[2..-1]
        
        flights = []
        out_flight_rows.each_with_index do |flight_row, i|
          columns = flight_row.all(:xpath, "td")
          raise JetBlue::InteractionError, "Expected 5 columns but got #{columns.size}." if columns.size != 5
          
          flights << new(
            :origin_airport_code => options[:from],
            :destination_airport_code => options[:to],
            :number => columns[2].first("span.matrix_flight_num").try(:text).try(:strip),
            :start_at => columns[0].first("p").try(:text).try(:strip),
            :end_at => columns[1].first("p").try(:text).try(:strip),
            :plane => columns[2].first("span.matrix_flight_equip").try(:text).try(:strip),
            :stops => columns[3].try(:text).try(:strip),
            :index => (i + 1)
          )
        end.compact
      end
      
      def book_flight(index)
        
      end
      
    end
  end
end
