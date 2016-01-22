require 'json'

class JsonAPI

  def self.file_reader(json_file_path)
    open(json_file_path) do |input|
      JSON.load(input)
    end
  end

  def self.file_writer(json_data, json_file_path)
    open(json_file_path, 'w') do |output|
      JSON.dump(json_data, output)
    end
  end

  def self.search(data, keys)
    return data if keys.empty?
    if data.is_a?(Hash)
      return search(data[keys.shift], keys)
    elsif data.is_a?(Array)
      return nil if keys.length < 2
      key = keys.shift
      value = keys.shift
      data.each do |each|
        return search(each, keys) if each[key] == value
      end
    else
      return data if data == keys.shift
    end
    return nil
  end

end
