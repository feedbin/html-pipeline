require 'uri'

module HTML
  class Pipeline

    class AbsoluteHrefFilter < Filter
      # HTML Filter for replacing relative and root relative href
      #
      # This is useful if the content for the page assumes the host is known
      # i.e. scraped webpages and some RSS feeds.
      #
      # Context options:
      #   :href_base_url (required) - Base URL for image host for root relative href.
      #   :href_subpage_url (required) - For relative href.
      #
      # This filter does not write additional information to the context.
      def call
        doc.search("a").each do |element|
          next if element['href'].nil? || element['href'].empty?
          href = element['href'].strip
          unless href.start_with? 'http'
            if href.start_with? '/'
              base = href_base_url
            else
              base = href_subpage_url
            end
            begin
              element["href"] = URI.join(base, href).to_s
            rescue Exception => e
              element["href"] = href
            end
          end
        end
        doc
      end

      # Private: the base url you want to use
      def href_base_url
        context[:href_base_url] or raise "Missing context :href_base_url for #{self.class.name}"
      end

      # Private: the relative url you want to use
      def href_subpage_url
        context[:href_subpage_url] or raise "Missing context :href_subpage_url for #{self.class.name}"
      end

    end
  end
end