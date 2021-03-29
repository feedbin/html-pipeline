require 'openssl'
require 'uri'

module HTML
  class Pipeline
    # HTML Filter for replacing http image URLs with camo versions. See:
    #
    # https://github.com/atmos/camo
    #
    # All images provided in user content should be run through this
    # filter so that http image sources do not cause mixed-content warnings
    # in browser clients.
    #
    # Context options:
    #   :asset_proxy (required) - Base URL for constructed asset proxy URLs.
    #   :asset_proxy_secret_key (required) - The shared secret used to encode URLs.
    #   :asset_proxy_whitelist - Array of host Strings or Regexps to skip
    #                            src rewriting.
    #
    # This filter does not write additional information to the context.
    class ImageproxyFilter < Filter
      # Hijacks images in the markup provided, replacing them with URLs that
      # go through the github asset proxy.
      def call
        return doc unless asset_proxy_enabled?

        doc.search("img").each do |element|
          original_src = element['src']
          next unless original_src

          begin
            uri = URI.parse(original_src)
          rescue Exception
            next
          end

          next if uri.host.nil?
          next if asset_host_whitelisted?(uri.host)

          element["src"] = nil
          element[src_attribute] = asset_proxy_url(original_src)
          element['data-canonical-src'] = original_src
        end

        doc.search("video").each do |element|
          original_src = element['poster']
          next unless original_src

          begin
            uri = URI.parse(original_src)
          rescue Exception
            next
          end

          next if uri.host.nil?
          next if asset_host_whitelisted?(uri.host)

          element["poster"] = nil
          element["data-camo-poster"] = asset_proxy_url(original_src)
          element['data-canonical-poster'] = original_src
        end
        doc
      end

      # Implementation of validate hook.
      # Errors should raise exceptions or use an existing validator.
      def validate
        needs :asset_proxy, :asset_proxy_secret_key
      end

      # The camouflaged URL for a given image URL.
      def asset_proxy_url(url)
        "#{asset_proxy_host}/s#{asset_url_hash(url)}/#{url}"
      end

      # Private: calculate the HMAC digest for a image source URL.
      def asset_url_hash(url)
        Base64.urlsafe_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), asset_proxy_secret_key, url)).strip()
      end

      # Private: Return true if asset proxy filter should be enabled
      def asset_proxy_enabled?
        !context[:disable_asset_proxy]
      end

      # Private: the host to use for generated asset proxied URLs.
      def asset_proxy_host
        context[:asset_proxy]
      end

      def asset_proxy_secret_key
        context[:asset_proxy_secret_key]
      end

      def asset_proxy_whitelist
        context[:asset_proxy_whitelist] || []
      end

      def asset_host_whitelisted?(host)
        asset_proxy_whitelist.any? do |test|
          test.is_a?(String) ? host == test : test.match(host)
        end
      end

      def src_attribute
        context[:asset_src_attribute] || "src"
      end

      # Private: helper to hexencode a string. Each byte ends up encoded into
      # two characters, zero padded value in the range [0-9a-f].
      def hexencode(str)
        str.to_enum(:each_byte).map { |byte| "%02x" % byte }.join
      end
    end
  end
end
