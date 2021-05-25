require 'httparty'

module Umlaut
  module Alma
    class OptionList
      def self.from_xml(xml)
puts xml
        return self.from_xml_object(Nokogiri::XML(xml))
      end

      def self.from_xml_object(parsed)
        self.new(
          metadata: parsed.xpath('//xmlns:context_object').first,
          options: parsed.xpath('//xmlns:context_service').map { |context_service|
            Option.for_xml_object(context_service)
          }
        )
      end

      def initialize(metadata: NullMetadata.new, options: []) 
        @metadata = metadata
        @options = deduplicate(options)
      end

      def enhance_metadata(request)
        puts "Enhance Metadata:"
        puts @metadata.inspect
      end

      def add_service(request, service)
        puts "Add Service:"
        puts @options.inspect
        if @options.empty?
          context = request.referent.to_context_object.to_hash
          ids = context['rft_id'] || []
          if ids.any? { |id| id.start_With('info:pmid') }
            request.add_service_response(
              service: service,
              service_type_value: 'site_message',
              type: 'warning',
              message: 'umlaut.message.pubmed_unavailable'
            )
          end
          if ids.any? { |id| id.start_With('info:doi') }
            request.add_service_response(
              service: service,
              service_type_value: 'site_message',
              type: 'warning',
              message: 'umlaut.message.doi_unavailable'
            )
          end
          return false
        end
        @options.each do |option|
          base = { service: service, service_type_value: 'fulltext' }
          option.add_fulltext(request, base)
        end
        true
      end

      private
      def deduplicate(options)
        deduped = {}
        options.each do |option|
          response = HTTParty.head(option.url)
          resolved_url = response.headers['location'] || option.url
          unless deduped.has_key?(resolved_url)
            deduped[resolved_url] = option
          end
        end
        deduped.values
      end
    end
  end
end
