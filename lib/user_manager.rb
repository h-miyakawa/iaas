require 'slice'
require 'control_manager'

class UserManager < ControlManager

  def initialize(options)
    super(options)
  end

  def create(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    Slice.create(user['user_id']) if @options.slicing
    user['fw_rule'] = []
    user['vms'] = []
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def delete(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    Slice.destroy(user['user_id']) if @options.slicing
    users.delete(user)
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def update(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
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
      ip_address = JsonAPI.search(hosts, ['hosts','host_id',host_id,'ip_address'])
      @ack_waitings << control
      ControlSender.new(ip_address, Settings::HOST_PORT, control.to_json).send
    end

  end

  def ack_for_update(response)
    request = handle_ack('function'=>'VM_STATUS', 'user_id'=>response['user_id'],'host_id'=>response['host_id'])
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    vms = JsonAPI.search(users, ['users','user_id',response['user_id'],'vms'])
    response['vms'].each do |_vm|
      vm = JsonAPI.search(vms, ['vm_id', _vm['vm_id']])
      next if vm['status'] == 'processing'
      vm['status'] = _vm['status']
    end
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
    # その他のホストからACKが返ってなければリターン
    @ack_waitings.each do |ack_waiting|
      return if ack_waiting['field']['user_id'] == response['user_id']
    end
    control = {'function' => 'USER_UPDATE_ACK', 'field' => {'user_id' => response['user_id']}}
    ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
  end

end
