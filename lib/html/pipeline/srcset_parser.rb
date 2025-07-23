require 'strscan'

class SrcsetParser
  def self.parse(srcset, &block)
    new(srcset, &block).parse
  rescue => e
    Result.new(nil, ["Block with `#{srcset}` raised exception: #{e.class}: #{e.message}"])
  end

  def initialize(srcset, &block)
    @input = srcset || ''
    @url_transform = block
  end

  def parse
    return Result.new('', []) if @input.empty?
    return Result.new(@input, []) unless @url_transform

    candidates = parse_candidates

    if candidates.empty? && !@input.strip.empty?
      Result.new(nil, ["Failed to parse srcset: #{@input}"])
    else
      Result.new(candidates.join(', '), [])
    end
  end

  private

  def parse_candidates
    candidates = []
    scanner = StringScanner.new(@input)
    
    until scanner.eos?
      # Skip whitespace and commas
      scanner.skip(/[\s,]+/)
      break if scanner.eos?
      
      # Parse URL - everything up to whitespace or a comma followed by whitespace/EOL
      url = scanner.scan(/[^\s,]+(?:,[^\s,]+)*/)
      break unless url
      
      # Skip whitespace after URL
      scanner.skip(/\s+/)
      
      # Parse descriptors (everything until comma or end)
      descriptors = []
      until scanner.eos? || scanner.check(/,/)
        if descriptor = scanner.scan(/[^\s,]+/)
          descriptors << descriptor
          scanner.skip(/\s+/)
        else
          break
        end
      end
      
      # Skip comma if present
      scanner.skip(/,/)
      
      # Transform and add candidate
      transformed_url = @url_transform.call(url)
      if descriptors.empty?
        candidates << transformed_url
      else
        candidates << "#{transformed_url} #{descriptors.join(' ')}"
      end
    end
    
    candidates
  end

  class Result
    attr_reader :value, :errors

    def initialize(value = nil, errors = [])
      @value = value
      @errors = errors
    end

    def success?
      !@value.nil?
    end
  end
end