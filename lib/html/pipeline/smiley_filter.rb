require 'openssl'
require 'uri'

module HTML
  class Pipeline
    # HTML Filter for replacing wp-smily with actual emoji
    class SmileyFilter < Filter
      def call
        doc.search("img[alt].wp-smiley").each do |image|
          alt = image["alt"]
          if alt.bytesize > alt.length
            image.replace(alt)
          end
        end
        doc
      end
    end
  end
end
