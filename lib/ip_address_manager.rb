require 'json_api'
require 'settings'

class IPAddressManager

  def initialize
    @table = {}
  end

  def start_manager
    @continue = true
    begin
      begin
        sleep(5)
        update_table
        users_file = JsonAPI.file_reader(Settings::USERS_FILEPATH)
        users = users_file['users']
        users.each do |user|
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
    file = File.open(Settings::DHCP_FILEPATH)
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

  def end_updater
    @continue = false
  end

end
