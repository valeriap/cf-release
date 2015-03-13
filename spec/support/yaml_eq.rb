RSpec::Matchers.define :yaml_eq do |expected|
  match do |actual|
    spiff_diff(actual, expected)
    YAML.load(actual) == YAML.load(expected)
  end

  failure_message do |actual|
    object_eq(YAML.load(actual), YAML.load(expected))
    @error_message.join("\n")
  end

  def spiff_diff(actual, expected)
      actual_manifest = Tempfile.new("actual-manifest.yml")
      File.open(actual_manifest, "w") do |file|
        file.print actual
      end

      expected_manifest = Tempfile.new("expected-manifest.yml")
      File.open(expected_manifest, "w") do |file|
        file.print expected
      end

      puts `spiff diff #{expected_manifest.path} #{actual_manifest.path}`
  end

  def object_eq(actual, expected, path=[])
    return if actual == expected

    @error_message ||= []

    types = [actual, expected].map(&:class).uniq

    if types == [Hash]
      compare_arrays(actual.keys, expected.keys, path, actual)
      expected.each do |k, expected_val|
        object_eq(actual[k], expected_val, path + [k])
      end

    elsif types == [Array]
      if compare_arrays(actual, expected, path)
        expected.each_with_index do |expected_el, i|
          object_eq(actual[i], expected_el, path + ["[#{i}]"])
        end
      end

    elsif types.size == 1 # same class
      @error_message << "Mismatched values in #{path}:"
      @error_message <<  "\t  actual=#{actual}"
      @error_message <<  "\texpected=#{expected}"

    else
      @error_message <<  "Mismatched types in #{path}:"
      @error_message <<  "\t  actual=#{types[0]} value=#{actual.inspect}"
      @error_message <<  "\texpected=#{types[1]} value=#{expected.inspect}"
    end
  end

  def compare_arrays(actual, expected, path, context=actual)
    if expected.size != actual.size
      @error_message <<  "Extra/missing elements in #{path}:"
      @error_message <<  "\tactual=#{actual.size} expected=#{expected.size}"
      @error_message <<  "\textra=#{actual - expected}"
      @error_message <<  "\tmissing=#{expected - actual}"
      @error_message <<  "\tcontext=#{context}"
      false
    else
      true
    end
  end
end

