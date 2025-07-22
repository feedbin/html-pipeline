class SrcsetParser
  attr_reader :input, :candidates, :parse_errors

  def self.parse(srcset, &block)
    begin
      new(srcset, &block).parse
    rescue => e
      Result.new(nil, ["Block raised exception: #{e.class}: #{e.message} on input: #{srcset}"])
    end
  end

  def initialize(srcset, &block)
    @input = srcset || ''
    @position = 0
    @candidates = []
    @parse_errors = []
    @url_transform = block
  end

  def parse
    return Result.new('', []) if @input.empty?
    return Result.new(@input, []) if !@url_transform

    parse_candidates

    # If there are critical errors, return nil as the value
    if has_critical_errors?
      Result.new(nil, @parse_errors + ["Failed to parse srcset: #{@input}"])
    else
      Result.new(@candidates.join(', '), @parse_errors)
    end
  end

  private

  def has_critical_errors?
    # Define what constitutes a critical error that should cause parse failure
    # For now, we'll consider it critical if no valid candidates were parsed
    @candidates.empty? && !@input.strip.empty?
  end

  def parse_candidates
    while @position < @input.length
      skip_whitespace_and_commas

      break if @position >= @input.length

      url = collect_url
      descriptors = collect_descriptors(url)

      # Only process if we have a valid URL
      if url && !url.empty?
        process_candidate(url, descriptors)
      else
        @parse_errors << "Empty URL found at position #{@position}"
      end
    end
  end

  def skip_whitespace_and_commas
    start_pos = @position
    while @position < @input.length && (@input[@position] =~ /\s/ || @input[@position] == ',')
      if @input[@position] == ','
        @parse_errors << "Comma at position #{@position} in splitting loop"
      end
      @position += 1
    end
  end

  def collect_url
    url_start = @position
    while @position < @input.length && @input[@position] !~ /\s/
      @position += 1
    end
    @input[url_start...@position]
  end

  def collect_descriptors(url)
    if url.end_with?(',')
      []  # No descriptors when URL has trailing comma
    else
      tokenize_descriptors
    end
  end

  def handle_trailing_commas(url)
    original_length = url.length
    url = url.chomp(',') while url.end_with?(',')
    removed_commas = original_length - url.length
    if removed_commas > 1
      @parse_errors << "Multiple trailing commas removed from URL: #{url}"
    end
    url
  end

  def tokenize_descriptors
    skip_whitespace

    descriptors = []
    current_descriptor = ''
    state = :in_descriptor

    parsing_complete = false
    while @position < @input.length && !parsing_complete
      c = @input[@position]

      case state
      when :in_descriptor
        result = handle_in_descriptor_state(c, current_descriptor, descriptors)
        current_descriptor = result[:descriptor]
        state = result[:state]
        parsing_complete = result[:complete]

      when :in_parens
        current_descriptor += c
        state = :in_descriptor if c == ')'

      when :after_descriptor
        result = handle_after_descriptor_state(c)
        state = result[:state]
        parsing_complete = result[:complete]
        @position -= 1 if result[:rewind]
      end

      @position += 1 unless parsing_complete
    end

    descriptors << current_descriptor if !parsing_complete && !current_descriptor.empty?
    descriptors
  end

  def handle_in_descriptor_state(c, current_descriptor, descriptors)
    case c
    when /\s/
      if !current_descriptor.empty?
        descriptors << current_descriptor
        current_descriptor = ''
      end
      { descriptor: current_descriptor, state: :after_descriptor, complete: false }
    when ','
      descriptors << current_descriptor if !current_descriptor.empty?
      { descriptor: current_descriptor, state: :in_descriptor, complete: true }
    when '('
      { descriptor: current_descriptor + c, state: :in_parens, complete: false }
    else
      { descriptor: current_descriptor + c, state: :in_descriptor, complete: false }
    end
  end

  def handle_after_descriptor_state(c)
    case c
    when /\s/
      { state: :after_descriptor, complete: false, rewind: false }
    when ','
      { state: :after_descriptor, complete: true, rewind: false }
    else
      { state: :in_descriptor, complete: false, rewind: true }
    end
  end

  def skip_whitespace
    @position += 1 while @position < @input.length && @input[@position] =~ /\s/
  end

  def process_candidate(url, descriptors)
    if url.end_with?(',')
      url = handle_trailing_commas(url)
    end

    return if url.empty?

    # Apply URL transformation only if no critical errors
    transformed_url = @url_transform.call(url)

    # Rebuild the candidate with original descriptors
    if descriptors.empty?
      @candidates << transformed_url
    else
      @candidates << "#{transformed_url} #{descriptors.join(' ')}"
    end
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