require 'json_api'
require 'settings'

class IPAddressManager

  def initialize
    @table = {}
  end

  def start_manager
    puts 'start IP address Manager'
    @continue = true
    begin
      begin
        sleep(5)
        update_table
        users_file = JsonAPI.file_reader(Settings::USERS_FILEPATH)
        next until users_file
        users = users_file['users']
        users.each do |user|
          next unless user['vms']
          user['vms'].each do |vm|
            vm['ip_address'] = @table[vm['mac_address']] if @table[vm['mac_address']]
          end
        end
        JsonAPI.file_writer(users_file, Settings::USERS_FILEPATH)
      end while @continue
    rescue Interrupt
      puts "IPAddressManager ended."
    end
  end

  def update_table
    ip_address = nil
    mac_address = nil
    file = File.open(Settings::DHCP_LEASES_FILEPATH)
    file.each do |line|
      case line
      when /lease (.*) \{/
        ip_address = $1
      when /hardware ethernet (.*);/
        mac_address = $1
      when /\}/
        @table[mac_address] = ip_address
      end
    end
    file.close
  end

=begin
  def delete_vm(user_id, vm_id, mac_address)
    my_leases = JsonAPI.file_reader(Settings::MY_DHCP_LEASES_FILEPATH)
    vm_name = user_id + '_' + vm_id

    my_leases.delete_if do |key, value|
      key == vm_name
    end

    # 設定ファイルに書き込み
    File.open(Settings::DHCP_CONF_FILEPATH, "w") do |io|
      File.foreach(Settings::DHCP_BASECONF_FILEPATH) do |line|
        io.puts line
      end
      io.puts hash_to_conf(my_leases)
    end
    #.jsonも更新
    JsonAPI.file_writer(my_leases, Settings::MY_DHCP_LEASES_FILEPATH)
    puts 'DHCP Server RESTART' if system('service isc-dhcp-server restart')
  end

  def add_vm(user_id, vm_id, mac_address)
    my_leases = JsonAPI.file_reader(Settings::MY_DHCP_LEASES_FILEPATH)
    range = Range.new(Settings::MIN_LEASE_IP, Settings::MAX_LEASE_IP)
    vm_name = user_id + '_' + vm_id
    # 割り当てるIPアドレスを決定
    for i in range
      ip_address = Settings::BASE_LEASE_IP + i.to_s
      next if my_leases.find {|key, value| value['ip_address'] == ip_address}
      my_leases[vm_name] = {'mac_address' => mac_address, 'ip_address' => ip_address}
      break
    end
    # 設定ファイルに書き込み
    File.open(Settings::DHCP_CONF_FILEPATH, "w") do |io|
      File.foreach(Settings::DHCP_BASECONF_FILEPATH) do |line|
        io.puts line
      end
      io.puts hash_to_conf(my_leases)
    end
    #.jsonも更新
    JsonAPI.file_writer(my_leases, Settings::MY_DHCP_LEASES_FILEPATH)
    puts 'DHCP Server RESTART' if system('service isc-dhcp-server restart')
  end

  def hash_to_conf(hash)
    text = ''
    hash.each do |vm_name, value|
      text += 'host ' + vm_name + ' {\n'
      text += '  hardware ethernet ' + value['mac_address'] + ';\n'
      text += '  fixed-address ' + value['ip_address'] + ';\n'
      text += '}\n\n'
    end
    return text
  end
=end
  def end_manager
    @continue = false
  end

end
