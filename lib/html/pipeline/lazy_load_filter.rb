module HTML
  class Pipeline
    class LazyLoadFilter < Filter
      # HTML Filter for replacing lazy loaded images with their real source
      #
      # This filter does not write additional information to the context.
      # This filter would need to be run before CamoFilter.
      def call
        doc.search("img").each do |element|
          next if element['data-original'].nil? || element['data-original'].empty?
          original_src = element['data-original'].strip
          element["src"] = original_src
        end
        doc
      end

    end
  end
end