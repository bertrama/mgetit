# This is a link_out_filter service, it msut be set up in your services.yml
# with task: link_out_filter
#
# no parameters. 
#
## Send an sfx 'pass through' URL _in the background_. Send the user to the
# target resource directly, but also send a back-channel hit to SFX
# so SFX will record it for statistical purposes. The reason we
# do it like this is sometimes the 'pass through' url doesn't work! Better
# to just lose the statistic than to mess up the user.
# 
# We also do it all in a background thread, to avoid slowing down the user
# with this step if SFX is being slow. 
require 'uri'
require 'net/http'

class SfxBackchannelRecord < Service

   def initialize(config)
     @display_name = "SFX Statistics"
     super(config)
     @timeout ||= 5
   end
   
  # This is meant to be called as task:link_out_filter, it doesn't have an
  # implementation for handle, it implements link_out_filter() instead. 
  def handle(request)
     raise "Not implemented."
  end

  # Hook method called by Umlaut. 
  # We always return nil because we aren't interested in modifying the url,
  # just using the callback to record the click with SFX. 
  def link_out_filter(orig_url, service_response, other_args = {})
    # Only work on responses that came from SFX.
    unless (service_response.service.class.to_s == "Sfx")
       return nil
    end
    make_backchannel_request( service_response )
    
    
    return nil
  end

  # Does everything in a background thread to avoid slowing down the user. 
  def make_backchannel_request(service_response)

    Thread.new do
      begin
        direct_sfx_url = Sfx.pass_through_url(service_response.data_values)
        # now we call that url through a back channel just to record it
        # with SFX.
        
        parsed_uri = URI.parse(direct_sfx_url )
        sfx_response = Net::HTTP.get_response( parsed_uri  )
        
        #raise if not 200 OK response
        unless ( sfx_response.kind_of?(Net::HTTPSuccess) ||
                 sfx_response.kind_of?(Net::HTTPRedirection) )
               # raise
               sfx_response.value
        end                
      rescue Exception => e
        Rails.logger.error("Could not record sfx backchannel click for service_response id #{service_response.id} ; sfx backchannel url attempted: #{direct_sfx_url} ; problem: #{e}")
        Rails.logger.error( e.backtrace.join("\n"))
      end
    end
  end
end
