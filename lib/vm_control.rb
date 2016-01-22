require 'json_api'
require 'settings'
require 'control_sender'

class VMControl

  def initialize
    @ack_waitings = []
    @users = JsonAPI.file_reader(Settings::USERS_FILEPATH)
    @hosts = JsonAPI.file_reader(Settings::HOSTS_FILEPATH)
    control = {'function' => '', 'field' => {}}
  end

  def create(request)
    # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
    result = select_host_for_creating_vm(request)
    control = {'function' => '', 'field' => {}}
    if result.is_a?(Integer)
      # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
      control['function'] = 'VM_CREATE_ACK'
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = request['vm_id']
      control['field']['status'] = 'NG'
      control['field']['message'] = generate_error_message(result)
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::PORT, control.to_json).send
    else
      # VM を作成可能
      control['function'] = 'VM_CREATE'
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = request['vm_id']
      control['field']['mac_address'] = generate_mac_address
      control['field']['cpu'] = request['cpu']
      control['field']['memory'] = request['memory']
      control['field']['volume'] = request['volume']
      ControlSender.new(result, Settings::PORT, control.to_json).send
      ack_waitings << control
    end

  end

  def modify(request)
    # 要求が要件を満たさないときホストのIPアドレスでなくエラーコードを受け取る
    result = check_resource_for_modifying_vm(request)
    control = {'function' => '', 'field' => {}}
    if result.is_a?(Integer)
      control['function'] = 'VM_MODIFY_ACK'
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = request['vm_id']
      control['field']['status'] = 'NG'
      control['field']['message'] = generate_error_message(result)
      ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::PORT, control.to_json).send
    else
      # VM を編集可能
      control['function'] = 'VM_MODIFY'
      control['field']['user_id'] = request['user_id']
      control['field']['vm_id'] = request['vm_id']
      control['field']['cpu'] = request['cpu']
      control['field']['memory'] = request['memory']
      control['field']['volume'] = request['volume']
      ControlSender.new(result, Settings::PORT, control.to_json).send
      ack_waitings << control
    end

  end

  def delete(request)
    search_keys = ['users','user_id',request['user_id'],'vms','vm_id',request['vm_id']]
    vm = JsonAPI.search(@users, search_keys)
    search_keys = ['host','host_id',vm['host_id']]
    host = JsonAPI.search(@hosts, search_keys)
    control = {'function' => '', 'field' => {}}
    control['function'] = 'VM_DELETE'
    control['field']['user_id'] = request['user_id']
    control['field']['vm_id'] = request['vm_id']
    ControlSender.new(host['ip_address'], Settings::PORT, control.to_json).send
    ack_waitings << control
  end

  def ack_for_create(response)
    handle_ack('function'=>'VM_CREATE', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    control = {'function' => '', 'field' => {}}
    control['function'] = 'VM_CREATE_ACK'
    control['field']['user_id'] = response['user_id']
    control['field']['vm_id'] = response['vm_id']
    control['field']['status'] = response['status']
    control['field']['message'] = response['message']
    ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::PORT, control.to_json).send
  end

  def ack_for_modify(response)
    handle_ack('function'=>'VM_MODIFY', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    control = {'function' => '', 'field' => {}}
    control['function'] = 'VM_MODIFY_ACK'
    control['field']['user_id'] = response['user_id']
    control['field']['vm_id'] = response['vm_id']
    control['field']['status'] = response['status']
    control['field']['message'] = response['message']
    ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::PORT, control.to_json).send
  end

  def ack_for_delete(response)
    handle_ack('function'=>'VM_DELETE', 'user_id'=>response['user_id'],'vm_id'=>response['vm_id'])
    control = {'function' => '', 'field' => {}}
    control['function'] = 'VM_MODIFY_ACK'
    control['field']['user_id'] = response['user_id']
    control['field']['vm_id'] = response['vm_id']
    control['field']['status'] = response['status']
    control['field']['message'] = response['message']
    ControlSender.new(Settings::WEB_SERVER_IP_ADDRESS, Settings::PORT, control.to_json).send
  end

  def check_resource_for_modifying_vm(request)

    search_keys = ['users','user_id',request['user_id'],'vms','vm_id',request['vm_id']]
    vm = JsonAPI.search(@users, search_keys)
    search_keys = ['host','host_id',vm['host_id']]
    host = JsonAPI.search(@hosts, search_keys)

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

    return host['ip_address'] if sum == 0
    return sum
  end

  def select_host_for_creating_vm(request)
    search_keys = ['users','user_id',request['user_id'],'vms','vm_id',request['vm_id']]
    collision = JsonAPI.search(@users, search_keys) ? 1 : 0
    min = 65
    @hosts['hosts'].each do |host|
      sum = collision
      # 現在，その CPU の要求を受付できません
      sum += 2 if request['cpu'] > host['rest_cpu']
      # CPU の要求が要件を満たしていません
      sum += 4 if request['cpu'] < host['minimum_cpu'] || request['cpu'] > host['max_cpu']
      # 現在，その Memory の要求を受付できません
      sum += 8 if request['memory'] > host['rest_memory']
      # Memory の要求が要件を満たしていません
      sum += 16 if request['memory'] < host['minimum_memory'] || request['memory'] > host['max_memory']
      # 現在，その Volume の要求を受付できません
      sum += 32 if request['volume'] > host['rest_volume']
      # Volume の要求が要件を満たしていません
      sum += 64 if request['volume'] < host['minimum_volume'] || request['volume'] > host['max_volume']
      return host['ip_address'] if sum == 0
      min = sum if Integer.bitCount(sum) < Integer.bitCount(min)
    end
    return min
  end


  def generate_error_message(error_code)
    message = ''

    if result & 1 != 0
      message += "VM_ID が他の VM と重複しています\n"
    end

    if result & 2 != 0
      message += "現在，その CPU の要求を受付できません\n";
    elsif result & 4 != 0
      message += "CPU の要求が要件を満たしていません\n";
    end

    if result & 8 != 0
      message += "現在，その Memory の要求を受付できません\n";
    elsif result & 16 != 0
      message += "Memory の要求が要件を満たしていません\n";
    end

    if result & 32 != 0
      message += "現在，その Volume の要求を受付できません\n";
    elsif result & 64 != 0
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
    @users['users'].each do |user|
      user['vms'].each do |vm|
        return true if vm['mac_address'] == mac_str
      end
    end
    return false
  end

  def handle_ack(pairs)
    @ack_waitings.each_with_index do |ack_waiting, i|
      match = true
      pairs.each do |key, value|
        if (key == 'function' && ack_waiting[key] != value) || ack_waiting['field'][key] != value
          match = false
          break
        end
      end
      next if !match
      @ack_waitings.delete_at(i)
      return true
    end
    return false
  end

end
