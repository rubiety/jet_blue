module JetBlue
  module BluePass
    class Flight
      attr_accessor :number
      attr_accessor :record_locator
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
      
      attr_accessor :index
      
      cattr_accessor :logger
      self.logger = JetBlue::BluePass.logger
      
      def initialize(attributes = {})
        attributes.each {|k,v| send("#{k}=", v) if respond_to?("#{k}=") }
        self.logger ||= JetBlue::BluePass.logger
        self
      end
      
      
      
      def self.booked
        # From Home Page
        # div.reviewTrip h5 should show "My Reservations"
        # div.tripReview for each trip
        #   div.usrHomePageBg is some sort of container for the real data
        #     There should be 7 div.column
        #     div.column[0] => "September, Tuesday 06 "
        #     div.column[1] p => "Boston , MA, US  (BOS)"
        #     div.column[2] p Should be "to"
        #     div.column[3] p => "San Diego , CA, US  (SAN)"
        #     div.column[4] p => "1 psgr"
        #     div.column[5] p => "PJLDQG" (Confirmation Code)
        #     div.column[6] p Should be "Purchased"
        #   p.singleLine immediately after div.usrHomePageBg
        #     a.singleLineLink with various values, each doing a window.open to the real page (parse this out and navigate there)?
        #       * Show Details (same markup as confirmation page)
        #       * Pay For Seats
        #       * Change
        #       * Cancel
        # 
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
        
        # TODO: Automate the form fields. Not comfortable with direct URLs here.
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
        review_itinerary
        reservation_details
        choose_seats
        complete_reservation
        read_confirmation
      end
      
      def change!(options = {})
        # There should be an h2 containing text "Select flight(s) to change"
        # div.flightOptions div.flight Here is an example. Check that first box.
        #   <div class="column one">
        #     <input name="ExchangeLeg1" id="ExchangeLeg1" value="ExchangeLeg1" onclick="SelectDirection('1','0');" type="checkbox">
        #   </div>
        #   <div class="column two">
        #     <p class="label highlight">Departs:</p>
        #     <p> 04:10 PM</p>
        #   </div>
        #   <div class="column three">
        #     <input name="departYear" value="2011" type="hidden">
        #     <p>
        #       Tuesday, September 6
        #     </p>
        #     <p class="departure">
        #       <span class="cityName">Boston </span>, MA&nbsp;(BOS)
        #     </p>
        #     <p class="arrival">
        #       <span class="cityName">San Diego </span>, CA&nbsp;(SAN)
        #     </p>
        #   </div>
        #   <div class="column four">
        #     <p>JetBlue Airways</p>
        #     <p>B6&nbsp;411</p>
        #   </div>
        # 
      end
      
      
      # TODO
      def review_itinerary
        form_with(:name => /itinReviewForm/i)
        
        css("div.outbound-flight p.flightNumber a").try(:content).try(:strip)
        css("input.button[value=Purchase]").click
        css("span.totalFee").try(:content).try(:strip)
      end
      
      def reservation_details
        form_with(:name => /ReservationDetailForm/i)
        
        # Fields:
        # firstTitle1 => Mr.
        # docGender1 => M
        # firstName1 => BENJAMIN
        # middleName1
        # lastName
        # frequent_flyer_num1 => 2087245182
        # RedressNumber1
        # ADTDay1 => 28
        # ADTMonth1 => JAN
        # ADTYear1 => 1986
        # mobile_PhoneCityCode - mobile_PhoneNumber
        # evening_PhoneCityCode - evening_PhoneNumber
        # day_PhoneCityCode - day_PhoneNumber
        # User_Email1
        # Verify_User_Email1
        # fax_PhoneCityCode - fax_PhoneNumber
        # User_Email2 - Verify_User_Email2
        # 
        # Submission:
        # id "payForSeatButton" for "Continue With Seats"
        # id "Cont_Button" for "Continue Without Seats"
      end
      
      def choose_seats
        form_with(:name => /seatForm/i)
        
        # div#seatSelection
        #   h2.flightHeadDetail
        #   span.textbold  which should start with Flight:
        #   table#currentSegmentPassengerList tbody tr (one for each passenger)
        #     td.passengerName
        #     td#seatNumberForSeat_1
        #     td#priceForSeat_1  (e.g. "65.00 USD")
        #     td#removeSeat_1 img (has onclick event, just click it)
        # 
        # table#seatMapTable
        #   First Row: (blank) (blank) A B C (blank) D E F  (on A320)
        #   Second Row: Separator (don't use)
        #   Other Rows: Actual Seats. First td in each is row number in a strong tag with a dot. 
        #   Second td is always blank, or contains an img with alt text "Emergency Exit" noting expensive seat, then:
        #     td classes of:
        #     * available  (within this an img tag that can be clicked. changes to class "selected" if selected, updates td#priceForSeat_1)
        #     * unavailable
        #     * aisle (don't click)
        #   
        # Submission:
        # "Continue" button is id and name "formSubmitButton"
        # "Skip Seat Selection" button is id and name "redirectToPaymentButton"
        # 
      end
      
      def complete_reservation
        form_with(:name => /ReservationDetailForm/i)  # NOTE: This is the same as the other form! Be careful!
        
        # div.flight  (one for each flight)
        #   Four div.columns. First one is useless
        # 
        #   div.column[1] contains:
        #     <p class="label highlight">Departs: </p>
        #     <p>04:10 PM</p>
        #     <p class="label highlight">Arrive: </p>
        #     <p>07:12 PM</p>
        # 
        #   div.column[2] contains:
        #     <p>Tuesday, September 6</p>
        #     <p class="departure">
        #       <span class="cityName">Boston </span>, MA&nbsp;(BOS)
        #     </p>
        #     <p>Tuesday, September 6</p>
        #     <p class="arrival">
        #       <span class="cityName">San Diego </span>, CA&nbsp;(SAN)
        #     </p>
        # 
        #   div.column[3] contains:
        #     <p class="airline">JetBlue Airways</p>
        #     <p class="flightNum">
        #       Non-Stop
        #       / 
        #       <a class="linkUnderline" href="javascript:flightnumlink('//www.jetblue.com/flightperformance/default.aspx?flightnumber=411','06SEP2011','&amp;origin=BOS&amp;destination=SAN','&amp;timeOfdep=1610')">
        #         B6 411
        #       </a>
        #     </p>
        #     <p class="aircraft">
        #       <span class="fltCabin">
        #         Aircraft:&nbsp;&nbsp;/&nbsp;
        #       </span>
        #       Airbus A320
        #     </p>
        #     <p>
        #       <a id="flightInfo_1" wjtrackingname="flightInfo" onclick="wsClickTrack(this);" href="javascript:openflifo('/meridia?posid=C5VE&amp;sid=me2reA2r9e2mii-iyyv:3f10c6d993bb0309df637d5fe5120e694e3fef380bef6db16239520e34548a5b&amp;page=flifoFlightInfoDetailsMessage_learn&amp;action=requestFlifo&amp;language=en&amp;airline=B6&amp;depCity=BOS&amp;depDate=06SEP2011&amp;arrCity=SAN&amp;flight=411')">
        #         Flight info
        #       </a>
        #     </p>
        # 
        # Form Fields:
        # 
        # ccCode  => AX, VI, CA (MasterCard), DS (Discover), DC (Diners Club)
        # cardNumber
        # cardHolderName
        # cardExpMonth (Numerical Months!)
        # cardExpYear
        # billingAddress1
        # billingAddress2
        # billingCity
        # billingStateProv (2 letter state code)
        # billingZip
        # billingCountry (2 letter ISO country code)
        # input[name=termsConditions] (check this!)
        # 
        # Submission:
        # id = purchaseButtonId, name = purch_submit
        # p.newSearch a ("Nevermind, I'd like to search for different flights")
        #
        # If Errors:
        # span.errorFullWidth will display general message
        # span.errorMsg for each specific message
        # 
      end
      
      def read_confirmation
        # Same div.flight as before with details
        # span#totalFee shows total
        # p#itinRevFare span shows "Total Air Fare & Taxes: "
        # span.recordLocater shows confirmation code
        # 
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