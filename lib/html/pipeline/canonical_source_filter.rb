module HTML
  class Pipeline

    class CanonicalSourceFilter < Filter
      # Put the original source in data-canonical-src before it is touched by
      # any other filter
      #
      # This filter does not write additional information to the context.
      def call
        doc.search("img").each do |element|
          next if element['src'].nil? || element['src'].empty?
          src = element['src'].strip
          next if src.start_with? 'data'
          element['data-canonical-src'] = src
        end
        doc
      end

    end
  end
end