require 'json_api'
require 'settings'

class HostManager

  def self.update_host(request)
    data = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    host = JsonAPI.search(data, ['hosts','host_id',request['field']['host_id']])

    if !host
      host = {}
      host['host_id'] = request['field']['host_id']
      hosts = JsonAPI.search(data, ['hosts'])
      hosts << host
    end

    host['ip_address'] = request['ip_address'] if request['ip_address']
    host['min_cpu'] = request['min_cpu'] if request['min_cpu']
    host['max_cpu'] = request['max_cpu'] if request['max_cpu']
    host['min_memory'] = request['min_memory'] if request['min_memory']
    host['max_memory'] = request['max_memory'] if request['max_memory']
    host['min_volume'] = request['min_volume'] if request['min_volume']
    host['max_volume'] = request['max_volume'] if request['max_volume']
    host['rest_memory'] = request['rest_memory'] if request['rest_memory']
    host['rest_volume'] = request['rest_volume'] if request['rest_volume']

    JsonAPI.file_writer(data, Settings::HOSTS_FILEPATH)
  end

end
