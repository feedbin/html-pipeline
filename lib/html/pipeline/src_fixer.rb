module HTML
  class Pipeline
    class SrcFixer < Filter
      EXTENSIONS = %w(APNG BMP GIF JPEG JPG PNG SVG apng bmp gif jpeg jpg png svg)

      def call
        doc.search("img").each do |element|
          src = element["src"]
          if ext = EXTENSIONS.find { |ext| src.include?(pattern(ext)) }
            parts = src.split(pattern(ext))
            element["src"] = "#{parts.first}.#{ext}"
          end
        end
        doc
      end

      def pattern(extension)
        ".#{extension}%20"
      end

    end
  end
end