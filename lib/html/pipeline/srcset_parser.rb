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
    position = 0

    while position < @input.length
      # Skip whitespace and commas
      while position < @input.length && (@input[position] =~ /[\s,]/)
        position += 1
      end
      break if position >= @input.length

      # Find URL end (whitespace or comma after non-whitespace)
      url_start = position
      url_end = position

      while position < @input.length
        if @input[position] == ','
          # Check if this comma is followed by whitespace or end of string
          # If so, it's a separator, not part of the URL
          next_pos = position + 1
          if next_pos >= @input.length || @input[next_pos] =~ /\s/
            url_end = position
            break
          end
        elsif @input[position] =~ /\s/
          url_end = position
          break
        end
        position += 1
      end

      # Handle end of string
      url_end = position if position >= @input.length

      url = @input[url_start...url_end]

      # Skip whitespace after URL
      while position < @input.length && @input[position] =~ /\s/
        position += 1
      end

      # Collect descriptors
      descriptors = []
      descriptor_start = position

      while position < @input.length && @input[position] != ','
        if @input[position] =~ /\s/
          if descriptor_start < position
            descriptors << @input[descriptor_start...position]
            descriptor_start = position + 1
          end
        end
        position += 1
      end

      # Add last descriptor if any
      if descriptor_start < position && position <= @input.length
        last_descriptor = @input[descriptor_start...position].strip
        descriptors << last_descriptor unless last_descriptor.empty?
      end

      # Transform and add candidate
      if !url.empty?
        transformed_url = @url_transform.call(url)
        if descriptors.empty?
          candidates << transformed_url
        else
          candidates << "#{transformed_url} #{descriptors.join(' ')}"
        end
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