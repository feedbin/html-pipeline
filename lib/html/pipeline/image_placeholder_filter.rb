module HTML
  class Pipeline

    class ImagePlaceholderFilter < Filter
      # HTML Filter for replacing image src with a placeholder and moving src to
      # a data attribute
      #
      # Context options:
      #   :placeholder_url - url for the placeholder
      #   :placeholder_attribute - attribute to store the original src in
      #
      # This filter does not write additional information to the context.
      def call
        doc.search("img").each do |element|
          next if element['src'].nil? || element['src'].empty?
          src = element['src'].strip
          next if src.start_with? 'data'
          element[placeholder_attribute] = src
          element['src'] = placeholder_url
        end
        doc
      end

      # Private: url for the placeholder
      def placeholder_url
        context[:placeholder_url] or raise "Missing context :placeholder_url for #{self.class.name}"
      end

      # Private: attribute to store the original src in
      def placeholder_attribute
        context[:placeholder_attribute] or raise "Missing context :placeholder_attribute for #{self.class.name}"
      end

    end
  end
end