require 'slice'
require 'control_manager'

class UserManager < ControlManager

  def initialize(options)
    super(options)
  end

  def create(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    search_line = ['users','user_id',request['user_id']]
    user = JsonAPI.search(users, search_line)
    Slice.create(user['user_id']) if @options.slicing
    user['fw_rule'] = []
    user['vms'] = []
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def delete(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    search_line = ['users','user_id',request['user_id']]
    user = JsonAPI.search(users, search_line)
    Slice.destroy(user['user_id']) if @options.slicing
    users.delete(user)
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def update(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    search_line = ['users','user_id',request['user_id']]
    user = JsonAPI.search(users, search_line)
    controls = {}

    user['vms'].each do |vm|
      host_id = vm['host_id']
      if !controls[host_id]
        controls[host_id] = {'function' => 'VM_STATUS', 'field' => {}}
        controls[host_id]['field']['user_id'] = user['user_id']
        controls[host_id]['field']['vms'] = []
        controls[host_id]['field']['host_id'] = host_id
      end
      controls[host_id]['field']['vms'] << {'vm_id' => vm['vm_id']}
    end

    controls.each do |host_id, control|
      search_line = ['hosts','host_id',host_id,'ip_address']
      ip_address = JsonAPI.search(hosts, search_line)
      @ack_waitings << control
      puts "send VM_STATUS to " + ip_address
      puts control.to_json
      ControlSender.new(ip_address, Settings::HOST_PORT, control.to_json).send
    end

    if controls.empty?
      puts "vms is empty"
      control = {'function' => 'USER_UPDATE_ACK', 'field' => {'user_id' => request['user_id']}}
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
    end

  end

  def ack_for_update(response)
    puts response
    puts 
    request = handle_ack('function'=>'VM_STATUS', 'user_id'=>response['user_id'],'host_id'=>response['host_id'])
    puts "request is nil" if !request
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    search_line = ['users','user_id',response['user_id'],'vms']
    vms = JsonAPI.search(users, search_line)
    response['vms'].each do |_vm|
      search_line = ['vm_id', _vm['vm_id']]
      vm = JsonAPI.search(vms, search_line)
      next if vm['status'] == 'processing'
      vm['status'] = _vm['status']
    end
    puts "koko1"
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
    # その他のホストからACKが返ってなければリターン
    @ack_waitings.each do |ack_waiting|
      puts ack_waiting['field']['user_id']
      return if ack_waiting['field']['user_id'] == response['user_id']
    end
    puts "koko2"
    control = {'function' => 'USER_UPDATE_ACK', 'field' => {'user_id' => response['user_id']}}
    ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
  end

end
