# = The Section Architecture
#
# Umlaut has what could be considered a 'domain specific language' for
# describing the display individual sections of content on the resolve menu 
# page. These sections often correspond to a ServiceTypeValue, like "fulltext".
# But sometimes may include multiple ServiceTypeValues (eg related_items section
# includes cited_by and similar_items), or no ServiceTypeValue at all (eg
# section to display a COinS).
#
# A description of a section is simply a hash with certain conventional
# keys describing various aspects of the contents and display of that section.
# These hashes are listed in the resolve_sections application configuration
# variable, initialized in the resolve_views.rb initializer, and customized
# or over-ridden in the local resolve_views.rb initializer. 
#
# One benefit of describing a section through configuration is that section
# display can often by changed at configure time without requiring a code
# time. Another is that the description of the section can be used not
# only to generate the initial HTML page; but also by the javascript that 
# update the sections with new background content as available; and by the
# partial_html_sections api that delivers HTML fragments for sections in an
# XML or JSON container.
#
# A description of a section is simply a hash, suitable for passing to
# SectionRenderer.new, detailed below. Plus some additional variables
# specifying _where_ to display the section, documented in the resolve_views.rb
# initializer. 
#
# = The SectionRenderer
# A SectionRenderer object provides logic for displaying a specific section
# on the Umlaut resolve menu page. It is initialized with a hash describing
# the details -- or significantly, with simply a pointer to such a hash
# already existing in the resolve_sections config variable. 
#
# A SectionRenderer is typically created by the ResolveHelper#render_section
# method, which then passes the SectionRender object to the
# _section_display.erb.html that does the actual rendering, using
# the SectionRenderer for logic and hashes to pass to render calls in
# the partial.
#
#
# == Section Options
#
# Section options are typically configured in hashes in the application
# config variable resolve_sections, which is expected to be a list of hashes.
# That hash is suitable to be passed to a SectionRenderer.new() as configuration
# options for the section. The various ways these options can be used
# is documented below. 
#
# === Simplest Case, Defaults
#
# As is common in ruby, SectionRenderer will make a lot of conventional
# assumptions, allowing you to be very concise for the basic simple case:
#
#     { :div_id => "fulltext", :html_area => :main }
#
# This means that:
# * this section is assumed to be contained within a <div id="fulltext">. The
#   div won't be automatically rendered, it's the containing pages
#   responsibility to put in a div with this id.
# 
# * this section is assumed to contain responses of type
#   ServiceTypeValue["fulltext"]
#
# * The section will be displayed with stock heading block including a title
#   from Rails i18n under key `umlaut.display_sections.#{section_id}.title`,
#   or if not there then 
#   constructed from the display_name of ServiceTypeValue["fulltext"], or 
#   in general the display_name of the first ServiceTypeValue included
#   in this section.
#
# * The section will include a stock 'spinner' if there are potential background
#   results being gathered for the ServiceTypeValue(s) contained.
#
# * The actual ServiceResponses collected for the ServiceTypeValue included
#   will be rendered with a _standard_response_item
#   partial, using render :collection.
#
# * The section will be displayed whether or not there are any actual
#   responses included. If there are no responses, a message will be displayed
#   to that effect.
#
# The display of a section can be customized via configuration parameters to
# a large degree, including supplying your own partial to take over almost
# all display of the section.
#
# === Customizing ServiceTypeValues
#
# You can specifically supply the ServiceTypeValues contained in this
# section, to a different type than would be guessed from the div_id:
#
#     {:div_id => "my_area", :service_type_values => ["fulltext"]}
#
# Or specify multiple types included in one section:
#
#     {:div_id => "related_items", :service_type_values => ['cited_by', 'similar]}
#
# Or a section that isn't used for displaying service responses at all,
# and has no service type:
#
#     {:div_id => "coins", :partial => "coins", :service_type_values => []}
#
# Note that a custom partial needs to be supplied if there are no service_type_values supplied.
#
# === Customizing heading display
#
# Using Rails i18n, you can supply a title for the section that's different than what would
# be guessed from it's ServiceTypeValues. You can also supply a prompt.
#
#   {:div_id =>"excerpts"}
#
# In your config/locales/en.yml (or other language):
#    umlaut:
#      display_sections:
#         excerpts:
#           title: "Really great Excerpts"
#           prompt: "Click on them to see them, far out!"
#
# You can also suppress display of the stock section heading at all:
#   {:show_heading => false, ...}
#
# This may be becuase you don't want a heading, or because you are supplying
# a custom partial that will take care of the heading in a custom way.
#
# === Customizing spinner display
#
# You can also suppress display of the stock spinner, because you don't
# want a spinner, or because your custom partial will be taking care of it.
#   {:show_spinner => false, ...}
#
# By default, the spinner displays what type of thing it's waiting on, guessing
# from the ServiceTypeValue configured. If you want to specify this item name, 
# use Rails i18n under the section_id in config/locales/en.yml, generally
# using a plural name:
#
#     umlaut:
#       display_sections:
#         excerpts:
#           load_more_item_name: "amazing excerpts"
#   
#
# === Customizing visibility of section
#
# By default, a section will simply be displayed regardless of whether
# there are any actual responses to display. However, the 'visibility'
# argument can be used to customize this in many ways.
# visibilty:
# [*true*]  
#       Default, always show section.
# [*false*] 
#       Never show section. (Not sure why you'd want this).
# [<b>:any_services</b>] 
#       Show section if and only if there are any configured
#       services that generate the ServiceTypeValues included
#       in this section, regardless of whether in this case
#       they have or not.
# [<b>:in_progress</b>]  
#       Show the section if responses exist, OR if any services
#       are currently in progress that are capable of generating
#       responses of the right type for this section.
# [<b>:responses_exist</b>] 
#       Show the section if and only if some responses
#       have actually been generated of the types contained
#       in this section.
# [<b>:complete_with_responses</b>] 
#                            Show the section only if there are responses
#                            generated, AND all services supplying
#                            responses of the type contained in section
#                            have completed, no more responses are possible.
# [<b>(lambda object)</b>] 
#                  Most flexibly of all, you can supply your own lambda
#                  supplying custom logic to determine whether to show
#                  the section, based on current context. The lambda
#                  will be passed the SectionRenderer object as an argument,
#                  providing access to the Umlaut Request with context.
#                  eg:
#                    :visibility => lambda do |renderer|
#                                             renderer.request.something == something
#                                   end
#
# === List with limit
#
# You can have the section automatically use the ResolveHelper#list_with_limit
# helper to limit the number of items initially displayed, with the rest behind
# a 'more' expand/contract widget.
#
#    { :div_id => "highlighted_link",
#      :list_visible_limit => 1,
#      :visibility => :in_progress, ... }
#
# === Custom partial display
#
# By default, the SectionRenderer assumes that all the ServiceResposnes included
# are capable of being displayed by the standard_item_response, and displays
# them simply by render standard_item_response with a \:colection. Sometimes
# this assumption isn't true, or you want custom display for other reasons.
# You can supply your own partial that the renderer will use to display
# the content.
#
#   { :div_id => "my_div", :partial => "my_partial", ... }
# 
# The partial so supplied should live in resolve/_my_partial.html.erb
#
# When this partial is called, it will have local variables set
# to give it the data it needs in order to create a display:
#
# [*responses_by_type*]
#                      a hash keyed by ServiceTypeValue name, with the
#                      the value being an array of the respective ServiceType
#                      objects.
# [*responses*]        a flattened list of all ServiceTypes included in
#                      this section, of varying ServiceTypeValues. Most
#                      useful when the section only includes one 
#                      ServiceTypeValue
# [*renderer*]         The SectionRenderer object itself, from which
#                      the current umlaut request can be obtained,
#                      among other things.
#
# You can supply additional static local arguments to the partial
# in the SectionRenderer setup:
#
#     {:div_id=> "foo", :partial=>"my_partial", :partial_locals => {:mode => "big"}, ... }
#
# the :partial_locals argument can be used with the standard_response_item
# too:
#     {:div_id => "highlighted_link", :partial_locals => {:show_source => true}}
#
# Note that your custom partial will still be displayed with stock
# header and possibly spinner surrounding it. You can suppress these elements:
#
#    {:div_id => "cover_image", :partial => "cover_image", :show_heading => false, :show_spinner => false}
#
# But even so, some 'wrapping' html is rendered surrounding your partial.
# If you want to disable even this, becuase your partial will take care of it
# itself, you can do so with \:show_partial_only => true
#    {:div_id => "search_inside", :partial => "search_inside", :show_partial_only => true}
class SectionRenderer
  include ActionView::Helpers::TagHelper

  # First argument is the current umlaut Request object.
  # Second argument is a session description hash. See class overview
  # for an overview. Recognized keys of session description hash:
  # * [id] SessionRenderer will look up session description hash in
  #        resolve_views finding one with :div_id == id
  # * [div_id] The id of the <div> the section lives in. Also used
  #            generally as unique ID for the section.
  # * [service_type_values] ServiceTypeValue's that this section contains.
  #                         defaults to [ServiceTypeValue[div_id]]
  # * [section_title] (DEPRECATED, use Rails i18n) Title for the section. Defaults to 
  #                   service_type_values.first.display_name
  # * [section_prompt] Prompt. Default nil.
  # * [show_heading] Show the heading section at all. Default true.
  # * [show_spinner] Show a stock spinner for bg action for service_type_values.
  #                  default true.
  # * [visibilty] What logic to use to decide whether to show the section at
  #               all. true|false|:any_services|:in_progress|:responses_exist|:complete_with_responses|(lambda object)
  # * [list_visible_limit] Use list_with_limit to limit initially displayed
  #                        items to value. Default nil, meaning don't use
  #                        list_with_limit.
  # * [partial] Use a custom partial to display this section, instead of
  #             using render("standard_response_item", :collection => [all responses]) as default.
  # * [show_partial_only] Display custom partial without any of the usual
  #                       standardized wrapping HTML. Custom partial will
  #                       take care of it itself. 
  def initialize(a_umlaut_request, section_def = {})
    @umlaut_request = a_umlaut_request
    
    @div_id = section_def[:div_id] || section_def[:id]
    raise Exception.new("SectionRenderer needs a :div_id passed in arguments hash") unless @div_id
    

    # Merge in default arguments for this section from config. 
    construct_options(section_def)
  end

  # Returns all ServiceTypeValue objects contained in this section, as
  # configured. Lazy caches result for perfomance. 
  def service_type_values
    @service_type_values ||=
    @options[:service_type_values].collect do |s|
      s.kind_of?(ServiceTypeValue)? s : ServiceTypeValue[s]
    end    
  end

  # Whether any services that generate #service_type_values are
  # currently in progress. Lazy caches result for efficiency. 
  def services_in_progress?
    # cache for efficiency
    @services_in_progress ||=
    @umlaut_request.service_types_in_progress?(service_type_values)
  end

  # Hash of ServiceType objects (join obj
  # representing individual reponse data) included in this
  # section. Keyed by string ServiceTypeValue id, value is array
  # of ServiceTypes
  def responses
    unless (@responses)
      @responses = {}
      service_type_values.each do |st|
        @responses[st.name] = @umlaut_request.get_service_type(st) 
      end      
    end
    @responses
  end

  # All the values from #responses, flattened into a simple Array.
  def responses_list
    responses.values.flatten
  end

  def responses_empty?
    responses_list.empty?
  end

  def request
    return @umlaut_request
  end

  def div_id
    return @div_id
  end

  def show_heading?
    (! show_partial_only?) && @options[:show_heading]
  end
  

  def show_spinner?
    (! show_partial_only?) && @options[:show_spinner] &&
       @umlaut_request.service_types_in_progress?(service_type_values)
  end

  # A hash suitable to be passed to Rails render(), to render
  # a spinner for this section. Called by section_display partial,
  # nobody else should need to call it. 
  def spinner_render_hash
    custom_item_name = I18n.t("load_more_item_name", :scope => "umlaut.display_sections.#{self.div_id}", :default => "")
    custom_item_name = nil if custom_item_name.blank?

    { :partial => "background_progress",
      :locals =>{ :svc_types => service_type_values,
                  :div_id => "progress_#{self.div_id}",
                  :current_set_empty => responses_empty?,
                  :item_name => custom_item_name
                }
    }
  end
  
  def show_partial_only?
    @options[:show_partial_only]
  end

  def custom_partial?
    ! @options[:partial].nil?
  end

  # A hash suitable to be passed to Rails render() to render the
  # inner content portion of the section. Called by the section_display
  # partial, nobody else should need to call this. You may be looking
  # for ResolveHelper#render_section instead. 
  def content_render_hash        
    if custom_partial?
      {:partial => @options[:partial].to_s,
       :object => responses_list,
       :locals => @options[:partial_locals].merge(
            {:responses_by_type => responses,
             :responses => responses_list,
             :umlaut_request => request,
             :renderer => self})}
    else
      {:partial => @options[:item_partial].to_s, 
       :collection => responses_list,
       :locals => @options[:partial_locals].clone}
    end
  end

  # used only with with list_with_limit functionality in section_display
  # partial. 
  def item_render_hash(item)
    # need to clone @options[:partial_locals], because
    # Rails will modify it to add the 'object' to it. Bah!
    {:partial => @options[:item_partial], 
       :object => item,
       :locals => @options[:partial_locals].clone}    
  end

  # Is the section visible according to it's settings calculated in current
  # context?
  def visible?
    case @options[:visibility]
      when true, false
        @options[:visibility]
      when :any_services
        any_services?
      when :in_progress
        # Do we have any of our types generated, or any services in progress
        # that might generate them?
          (! responses_empty?) || services_in_progress?             
      when :responses_exist
        # Have any responses of our type actually been generated?
        ! responses_empty?
      when :complete_with_responses
        (! responses.empty?) && ! (services_in_progress?)
      when Proc
        # It's a lambda, which takes this SectionRenderer as an arg
        @options[:visibility].call(self)
      else true        
    end
  end
  
  # do any services exist which even potentially generate our types, even
  # if they've completed without doing so?.         
  def any_services?
    nil != @umlaut_request.dispatched_services.to_a.find do |ds|
        ! (service_type_values & ds.can_generate_service_types ).empty? 
    end
  end

  def list_visible_limit
    @options[:list_visible_limit]
  end
  
  # Display title of the section can come from several places, in order
  # of precedence:
  #   * 1. (DEPRECATED) :section_title key in config hash. Prefer i18n instead. 
  #   * 2. Rails i18n, under key 'umlaut.display_sections.#{section_id}.title'
  #   * 3. If not given, as a default we use the display_name of the first ServiceTypeValue
  #        object included in this section's results. 
  #  If still blank after all those lookups, then no section title. Set a section title
  #  to the empty string in i18n to force no section title. 
  def section_title
    section_title = nil

    if @options.has_key? :section_title
      # deprecation warning? Not sure the right way to do that. 
      section_title = @options[:section_title]
    else
      section_title = I18n.t("title", :scope => "umlaut.display_sections.#{self.div_id}", 
        :default => Proc.new {
          # Look up from service_type name if possible as default
          if (service_type_values.length > 0)
            service_type_values.first.display_name_pluralize.titlecase
          else
            ""
          end
      })
    end

    section_title = nil if section_title.blank?
    return section_title
  end

  # Optional section prompt, from Rails i18n key `umlaut.display_sections.#{section_div_id}.prompt`
  # Deprecated legacy, you can force with :section_prompt key in section config hash. 
  def section_prompt
    prompt = nil

    if @options.has_key?(:section_prompt)
      prompt = @options[:section_prompt]
    else
      prompt = I18n.t("prompt", :scope => "umlaut.display_sections.#{self.div_id}", :default => "")
    end
    
    prompt = nil if prompt.blank?
    return prompt
  end

  # For a given resonse type section, returns a string that will change 
  # if the rendered HTML has changed, HTTP etag style. 
  #
  # Output in API responses, used by partial html updater
  # to know if a section needs to be updated on page. 
  #
  # tag is created by appending:
  # * the progress status for the section (in progress or not)
  # * The current visibility status of the section
  # * Number of responses in section
  # * the timestamp of most recent response in section, if any. 
  def section_etag
    parts = []

    parts << self.services_in_progress?.to_s
    parts << self.visible?.to_s
    parts << responses_list.length
    max = responses_list.max_by {|response| response.created_at}    
    parts << (max ? max.created_at.utc.strftime("%Y-%m-%d-%H:%M:%S") : "")

    return parts.join("_")
  end


  protected

  def construct_options(arguments)
    
    # Fill in static defaults
    @options = {:show_spinner => true,
                :show_heading =>  true,
                :visibility => true,
                :show_partial_only => false,
                :partial_locals =>  {}}.merge!(arguments)
    

    # service type value default to same name as section_id
    @options[:service_type_values] ||= [self.div_id]    

    # Partials to display. Default to _standard_response_item item partial.
    if ( @options[:partial] == true)
      @options[:partial] = self.div_id
    end
    
    @options[:item_partial] = 
      case @options[:item_partial]
        when true then self.div_id + "_item"
        when String then options[:item_partial]
        else "standard_response_item"
      end
  

    # sanity check
    if ( @options[:show_partial_only] && ! @options[:partial])
      raise Exception.new("SectionRenderer: You must supply a :partial argument if :show_partial_only is set true")
    end    
    
    return @options
  end
  




    
  
end
