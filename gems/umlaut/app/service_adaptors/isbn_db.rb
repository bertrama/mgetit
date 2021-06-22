# NOT recommended anymore, jrochkind has found IsbnDb to be pretty flaky, and
# hard to deal with. See book_finder.rb or all_books_dot_com.rb as alternatives. 
#
# Talks to the ISBNDb (isbndb.com) to get pricing info and links to pricing
# info for online sellers. There are potentially other services we could
# make use of there in the future too.
#
# By default makes an API request in advance to check if book is available, and thus requires
# an API key.  However, ISBNdb seems no longer as reliable as it once was there. 
# You may not want to use ISBNdb at all, see AllBooksDotCom as an alternative
# (although with no pre-check for hits.)
#
# jrochkind talked to the operators of isbndb and got a very high traffic limit
# (instead of the default free 500 requests/day), for free. You could try the
# same. 
#
# config params in services.yml:
#
#  access_key:  Your API access key from isbnDB.
#  display_text: (Optional) name of link.
#  timeout:  (Optional) seconds to wait for response
#  display_name: (Optional) what to call the service in display
class IsbnDb < Service
  require 'nokogiri'
  
  required_config_params :access_key
  
  def service_types_generated
    return [ServiceTypeValue['highlighted_link']]
  end

  def initialize(config)
    @timeout = 3
    @display_text = "Compare online prices"
    @display_name = "ISBNdb.com"
    
    @credits = {
      "ISBNdb" => "http://isbndb.com/"
    }
    
    super(config)
  end

  def handle(umlaut_request)
    
    isbn = umlaut_request.referent.metadata['isbn']
    
    # No isbn, nothing we can do. 
    return umlaut_request.dispatched(self, true) if isbn.blank?
    
    response = do_request(isbn)
    xml = Nokogiri::XML( response.body )
    book_xml = xml.at('ISBNdb/BookList/BookData')

    # No hits?
    return umlaut_request.dispatched(self, true) if book_xml.blank?
    
    prices_link = get_prices_link( book_xml )
    
    umlaut_request.add_service_response(
      :service=>self, 
      :url=> prices_link, 
      :display_text=> @display_text,
      :service_type_value => ServiceTypeValue[:highlighted_link]
      )

    return umlaut_request.dispatched(self, true)
  end

  def do_request(isbn)
    host = "isbndb.com"
    # including results=details will prime isbndb to refresh pricing, Andrew tells me. 
    path = "/api/books.xml?access_key=#{@access_key}&results=details,prices&index1=isbn&value1=#{isbn}"

    http = Net::HTTP.new( host )
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    response =  http.get( path )
    # raise if not 200 OK response
    response.value
    
    return response  
  end

  # Pass in nokogiri object representing the <BookData> element.
  # passes back string url of isbndb prices/availability page
  def get_prices_link( book_data )
    book_id = book_data.attributes['book_id']

    return (book_id) ? "http://isbndb.com/d/book/#{book_id}/prices.html" : nil 
  end
  
end
