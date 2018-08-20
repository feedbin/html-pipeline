require 'openssl'
require 'uri'

module HTML
  class Pipeline
    # HTML Filter for replacing iframes with a placeholder
    #
    # All images provided in user content should be run through this
    # filter so that http image sources do not cause mixed-content warnings
    # in browser clients.
    #
    # Context options:
    #   :embed_url (required) - The endpoint that will render the embed
    #
    # This filter does not write additional information to the context.
    class IframeFilter < Filter
      # Hijacks images in the markup provided, replacing them with URLs that
      # go through the github asset proxy.
      def call
        doc.search("iframe").each do |element|
          replacement = Nokogiri::XML::Element.new("div", doc)
          uri = URI(element["src"]) rescue nil
          if uri && uri.host
            width = element["width"] && element["width"].to_i
            height = element["height"] && element["height"].to_i
            attributes = iframe_attributes(uri, width, height)
            attributes.each do |attribute, value|
              replacement.set_attribute(attribute, value)
            end
          end
          element.replace(replacement)
        end
        doc
      end

      def iframe_attributes(iframe_src, width, height)
        iframe_src = URI(iframe_src)
        id = Digest::SHA1.hexdigest(iframe_src.to_s)

        query = URI.encode_www_form({
          url: iframe_src.to_s,
          dom_id: id,
          width: width,
          height: height
        })

        attributes = {
          "id" => id,
          "class" => embed_classes,
          "data-iframe-src" => iframe_src.to_s,
          "data-iframe-host" => iframe_src.host,
          "data-iframe-embed-url" => "#{embed_url}?#{query}",
        }

        if width && height
          attributes["data-iframe-width"] = width
          attributes["data-iframe-height"] = height
        end
        attributes
      end

      def embed_url
        context[:embed_url]
      end

      def embed_classes
        context[:embed_classes]
      end

      # Implementation of validate hook.
      # Errors should raise exceptions or use an existing validator.
      def validate
        needs :embed_url
      end
    end
  end
end
