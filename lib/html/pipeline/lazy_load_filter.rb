module HTML
  class Pipeline
    class LazyLoadFilter < Filter
      # HTML Filter for replacing lazy loaded images with their real source
      #
      # This filter does not write additional information to the context.
      # This filter would need to be run before CamoFilter.
      def call
        doc.search("img").each do |element|
          patterns = ['data-original', 'data-canonical-src']
          patterns.each do |pattern|
            if !element[pattern].nil? && !element[pattern].empty?
              original_src = element[pattern].strip
              element["src"] = original_src
            end
          end
        end
        doc
      end

    end
  end
end