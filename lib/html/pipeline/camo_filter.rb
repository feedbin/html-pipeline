require "openssl"
require "uri"
require_relative 'srcset_parser'

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
    class CamoFilter < Filter
      # Hijacks images in the markup provided, replacing them with URLs that
      # go through the github asset proxy.
      def call
        return doc unless asset_proxy_enabled?

        elements("img").each do |element|
          original_src = element["src"]
          next unless original_src

          uri = begin
            Addressable::URI.parse(original_src)
          rescue Exception
            next
          end

          next if uri.host.nil?
          next if asset_host_whitelisted?(uri.host)
          original_src = uri.normalize.to_s

          element.delete("src") unless keep_src?
          element[src_attribute] = asset_proxy_url(original_src)
          element["data-canonical-src"] = original_src unless keep_src?
        end

        elements("video").each do |element|
          original_src = element["poster"]
          next unless original_src

          uri = begin
            Addressable::URI.heuristic_parse(original_src)
          rescue Exception
            next
          end

          next if uri.host.nil?
          next if asset_host_whitelisted?(uri.host)
          original_src = uri.normalize.to_s

          element.delete("poster") unless keep_src?
          element["data-camo-poster"] = asset_proxy_url(original_src)
          element["data-canonical-poster"] = original_src unless keep_src?
        end

        elements_with("srcset").each do |element|
          srcset = element["srcset"]
          next if srcset.nil? || srcset.empty?

          result = SrcsetParser.parse(srcset) do |url|
            uri = Addressable::URI.heuristic_parse(url)
            raise if uri.host.nil?
            asset_proxy_url(uri.normalize.to_s)
          end

          element.delete("srcset") unless keep_src?
          if result.success?
            element["data-canonical-srcset"] = srcset unless keep_src?
            element["data-camo-srcset"] = result.value
          end
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
        "#{asset_proxy_host}/#{asset_url_hash(url)}/#{hexencode(url)}"
      end

      # Private: calculate the HMAC digest for a image source URL.
      def asset_url_hash(url)
        OpenSSL::HMAC.hexdigest("sha1", asset_proxy_secret_key, url)
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

      # Private: leave src, poster and srcset in place and only add the
      # data-camo-* attributes beside them, for output that must work
      # without the page's JavaScript.
      def keep_src?
        !!context[:asset_keep_src]
      end

      def src_attribute
        context[:asset_src_attribute] || "src"
      end

      # Private: helper to hexencode a string. Each byte ends up encoded into
      # two characters, zero padded value in the range [0-9a-f].
      def hexencode(str)
        str.unpack1("H*")
      end
    end
  end
end
