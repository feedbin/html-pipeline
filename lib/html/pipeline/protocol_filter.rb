require 'uri'

module HTML
  class Pipeline

    class ProtocolFilter < Filter
      # HTML Filter for replacing adding a protocol to protocol relative urls
      #
      # Browsers understand protocol relative URLs but not all clients do (i.e. iOS)
      #
      # This filter does not write additional information to the context.
      def call
        doc.search("iframe").each do |element| 
          next if element['src'].nil? || element['src'].empty?
          src = element['src'].strip
          if src.start_with? '//'
            element['src'] = "http:#{src}"
          end
        end
        doc
      end
    
    end
  end
end