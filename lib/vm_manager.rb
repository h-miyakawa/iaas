require 'control_manager'
require 'settings'
require 'slice'
require 'port'

class VirtualMachineManager < ControlManager

  def initialize(options)
    super(options)
  end

  # VM_CREATE
  def create(request)
    # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
    selected_host = select_host_for_creating_vm(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = {'vm_id' => request['vm_id']}
    vm['mac_address'] = generate_mac_address
    vm['cpu'] = request['cpu']
    vm['memory'] = request['memory']
    vm['volume'] = request['volume']
    vm['host_id'] = selected_host['host_id']

    if selected_host.is_a?(Integer)
      # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
      control = {'function' => 'VM_CREATE_ACK', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = vm['vm_id']
      control['field']['status'] = 'NG'
      control['field']['message'] = generate_error_message(selected_host)
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
    else
      # VM を作成可能
      vm['status'] = 'processing'
      user['vms'] << vm

      control = {'function' => 'VM_CREATE_ACK', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = vm['vm_id']
      control['field']['status'] = 'OK'
      control['field']['message'] = ''
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send

      JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
      control = {'function' => 'VM_CREATE', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = vm['vm_id']
      control['field']['mac_address'] = vm['mac_address']
      control['field']['cpu'] = vm['cpu']
      control['field']['memory'] = vm['memory']
      control['field']['volume'] = vm['volume']
      control['field']['host_id'] = vm['host_id']
      @ack_waitings << control
      ControlSender.new(selected_host['ip_address'], Settings::HOST_PORT, control.to_json).send
    end

  end

  # VM_MODIFY
  def modify(request)
    # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
    checked_host = check_host_for_modifying_vm(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    if checked_host.is_a?(Integer)
      control = {'function' => 'VM_MODIFY_ACK', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = vm['vm_id']
      control['field']['status'] = 'NG'
      control['field']['message'] = generate_error_message(checked_host)
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
    else

      control = {'function' => 'VM_MODIFY_ACK', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = vm['vm_id']
      control['field']['status'] = 'OK'
      control['field']['message'] = ''
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send

      # VM を編集可能
      vm['status'] = 'processing'
      JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
      control = {'function' => 'VM_MODIFY', 'field' => {}}
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = request['vm_id']
      control['field']['cpu'] = request['cpu']
      control['field']['memory'] = request['memory']
      control['field']['volume'] = request['volume']
      @ack_waitings << control
      ControlSender.new(checked_host['ip_address'], Settings::HOST_PORT, control.to_json).send
    end

  end

  # VM_DELETE
  def delete(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    host = JsonAPI.search(hosts, ['host','host_id',vm['host_id']])
    vm['status'] = 'processing'
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
	  control = {'function' => 'VM_DELETE', 'field' => {}}
		control['field']['user_id'] = request['user_id']
		control['field']['vm_id'] = request['vm_id']
		@ack_waitings << control
		ControlSender.new(host['ip_address'], Settings::HOST_PORT, control.to_json).send
  end

  # VM_START
  def start(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    host = JsonAPI.search(hosts, ['host','host_id',vm['host_id']])
    vm['status'] = 'processing'
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
	  control = {'function' => 'VM_START', 'field' => {}}
    control['field']['user_id'] = request['user_id']
    control['field']['vm_id'] = request['vm_id']
		@ack_waitings << control
		ControlSender.new(host['ip_address'], Settings::HOST_PORT, control.to_json).send
  end

  # VM_STOP
  def stop(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    host = JsonAPI.search(hosts, ['host','host_id',vm['host_id']])
    vm['status'] = 'processing'
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
    control = {'function' => 'VM_STOP', 'field' => {}}
    control['field']['user_id'] = request['user_id']
    control['field']['vm_id'] = request['vm_id']
    @ack_waitings << control
    ControlSender.new(host['ip_address'], Settings::HOST_PORT, control.to_json).send
  end

  # VM_CREATE_ACK
  def ack_for_create(response)
    request = handle_ack('function'=>'VM_CREATE', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    if response['status'] == 'OK'
      vm['status'] = 'standby'
      vm['message'] = ''
      if @options.slicing
        hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
        host = JsonAPI.search(hosts, ['hosts','host_id',vm['host_id']])
        port = Port.parse(host['port'])
        Slice.find_by!(name: user['user_id']).
          add_mac_address(vm['mac_address'], dpid: port[:dpid], port_no: port[:port_no])
      end
    else
      vm['status'] = 'error'
      vm['message'] = response['message']
    end
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  # VM_MODIFY_ACK
  def ack_for_modify(response)
    request = handle_ack('function'=>'VM_MODIFY', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    if response['status'] == 'OK'
      vm['cpu'] = request['cpu']
      vm['memory'] = request['memory']
      vm['volume'] = request['volume']
      vm['status'] = 'standby'
      vm['message'] = ''
    else
      vm['status'] = 'standby'
      vm['message'] = response['message']
    end
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  # VM_DELETE_ACK
  def ack_for_delete(response)
    request = handle_ack('function'=>'VM_DELETE', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    user = JsonAPI.search(users, ['users','user_id',request['user_id']])
    vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
    if response['status'] == 'OK'
      user['vms'].delete(vm)
      if @options.slicing
        hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
        host = JsonAPI.search(hosts, ['hosts','host_id',vm['host_id']])
        port = Port.parse(host['port'])
        Slice.find_by!(name: user['user_id']).
          delete_mac_address(vm['mac_address'], dpid: port[:dpid], port_no: port[:port_no])
      end
    else
      vm['status'] = 'standby'
      vm['message'] = response['message']
    end
    JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  # VM_START_ACK
  def ack_for_start(response)
      request = handle_ack('function'=>'VM_START', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
      users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
      user = JsonAPI.search(users, ['users','user_id',request['user_id']])
      vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
      if response['status'] == 'OK'
        vm['status'] = 'running'
        vm['message'] = ''
      else
        vm['status'] = 'standby'
        vm['message'] = response['message']
      end
      JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  # VM_STOP_ACK
  def ack_for_stop(response)
      request = handle_ack('function'=>'VM_STOP', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
      users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
      user = JsonAPI.search(users, ['users','user_id',request['user_id']])
      vm = JsonAPI.search(user, ['vms','vm_id',request['vm_id']])
      if response['status'] == 'OK'
        vm['status'] = 'standby'
        vm['message'] = ''
      else
        vm['status'] = 'running'
        vm['message'] = response['message']
      end
      JsonAPI.file_writer(users, Settings::USERS_FILEPATH)
  end

  def check_host_for_modifying_vm(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    search_keys = ['users','user_id',request['user_id'],'vms','vm_id',request['vm_id']]
    vm = JsonAPI.search(users, search_keys)
    search_keys = ['host','host_id',vm['host_id']]
    host = JsonAPI.search(hosts, search_keys)

    diff_cpu = request['cpu'] - vm['cpu']
    diff_memory = request['memory'] - vm['memory']
    diff_volume = request['volume'] - vm['volume']

    sum = 0
    # 現在，その CPU の要求を受付できません
    sum += 2 if diff_cpu > host['rest_cpu']
    # CPU の要求が要件を満たしていません
    sum += 4 if request['cpu'] < host['minimum_cpu'] || request['cpu'] > host['max_cpu']
    # 現在，その Memory の要求を受付できません
    sum += 8 if diff_memory > host['rest_memory']
    # Memory の要求が要件を満たしていません
    sum += 16 if request['memory'] < host['minimum_memory'] || request['memory'] > host['max_memory']
    # 現在，その Volume の要求を受付できません
    sum += 32 if diff_volume > host['rest_volume']
    # Volume の要求が要件を満たしていません
    sum += 64 if request['volume'] < host['minimum_volume'] || request['volume'] > host['max_volume']

    return host if sum == 0
    return sum
  end

  def select_host_for_creating_vm(request)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    search_keys = ['users','user_id',request['user_id'],'vms','vm_id',request['vm_id']]
    collision = JsonAPI.search(users, search_keys) ? 1 : 0
    min = 127
    hosts['hosts'].each do |host|
      sum = collision
      # 現在，その CPU の要求を受付できません
      sum += 2 if request['cpu'] > host['rest_cpu']
      # CPU の要求が要件を満たしていません
      sum += 4 if request['cpu'] < host['min_cpu'] || request['cpu'] > host['max_cpu']
      # 現在，その Memory の要求を受付できません
      sum += 8 if request['memory'] > host['rest_memory']
      # Memory の要求が要件を満たしていません
      sum += 16 if request['memory'] < host['min_memory'] || request['memory'] > host['max_memory']
      # 現在，その Volume の要求を受付できません
      sum += 32 if request['volume'] > host['rest_volume']
      # Volume の要求が要件を満たしていません
      sum += 64 if request['volume'] < host['min_volume'] || request['volume'] > host['max_volume']
      return host if sum == 0
      # 要変更
      min = sum if sum < min
    end
    return min
  end


  def generate_error_message(error_code)
    message = ''

    if error_code & 1 != 0
      message += "VM_ID が他の VM と重複しています\n"
    end

    if error_code & 2 != 0
      message += "現在，その CPU の要求を受付できません\n";
    elsif error_code & 4 != 0
      message += "CPU の要求が要件を満たしていません\n";
    end

    if error_code & 8 != 0
      message += "現在，その Memory の要求を受付できません\n";
    elsif error_code & 16 != 0
      message += "Memory の要求が要件を満たしていません\n";
    end

    if error_code & 32 != 0
      message += "現在，その Volume の要求を受付できません\n";
    elsif error_code & 64 != 0
      message += "Volume の要求が要件を満たしていません\n";
    end

    return message
  end

  def generate_mac_address
    mac_arr = [0xde, 0xca, 0xde, Random.rand(0x7f), Random.rand(0xff), Random.rand(0xff)]
    mac_str = (["%02x"] * 6).join(":") % mac_arr
    mac_str = generate_mac_address if check_mac_address_collision(mac_str)
    return mac_str
  end

  def check_mac_address_collision(mac_str)
    users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    users['users'].each do |user|
      user['vms'].each do |vm|
        return true if vm['mac_address'] == mac_str
      end
    end
    return false
  end

end
