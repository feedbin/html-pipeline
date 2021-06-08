require 'uri'

module HTML
  class Pipeline

    class AbsoluteSourceFilter < Filter
      # HTML Filter for replacing relative and root relative image URLs with
      # fully qualified URLs
      #
      # This is useful if an image is root relative but should really be going
      # through a cdn, or if the content for the page assumes the host is known
      # i.e. scraped webpages and some RSS feeds.
      #
      # Context options:
      #   :image_base_url - Base URL for image host for root relative src.
      #   :image_subpage_url - For relative src.
      #
      # This filter does not write additional information to the context.
      # This filter would need to be run before CamoFilter.
      def fully_qualify(src)
        unless src.start_with? /https?:/
          if src.start_with? '/'
            base = image_base_url
          else
            base = image_subpage_url
          end
          src = URI.join(base, src.gsub(' ', '%20')).to_s rescue nil
        end
        src
      end

      def call
        doc.search("img,video,audio,source").each do |element|
          next if element['src'].nil? || element['src'].empty?
          src = element['src'].strip
          next if src.start_with? 'data:'
          element['src'] = fully_qualify(src)
        end
        doc.search("video").each do |element|
          next if element['poster'].nil? || element['poster'].empty?
          src = element['poster'].strip
          next if src.start_with? 'data:'
          element['poster'] = fully_qualify(src)
        end
        doc
      end

      # Private: the base url you want to use
      def image_base_url
        context[:image_base_url] or raise "Missing context :image_base_url for #{self.class.name}"
      end

      # Private: the relative url you want to use
      def image_subpage_url
        context[:image_subpage_url] or raise "Missing context :image_subpage_url for #{self.class.name}"
      end

    end
  end
end