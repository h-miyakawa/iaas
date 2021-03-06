require 'settings'

class HostManager < ControlManager

  def initialize(options)
    super(options)
  end

  def update(request)
    hosts_file = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    hosts_file = {} unless hosts_file
    hosts_file['hosts'] = [] unless hosts_file['hosts']
    search_line = ['hosts','host_id',request['host_id']]
    host = JsonAPI.search(hosts_file, search_line)

    if !host
      host = {'host_id' => request['host_id']}
      hosts_file['hosts'] << host
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
    host['port'] = request['port'] if request['port']

    JsonAPI.file_writer(hosts_file, Settings::HOSTS_FILEPATH)
  end

end
