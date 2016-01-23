require 'socket'
require 'json'
require 'vm_control'
require 'host_manager'
require 'user_manager'
require 'settings'

class ControlReceiver

  def initialize
    @vmc = VMControl.new
  end

  def start_server
    socket = TCPServer.open(Settings::PORT)
    @continue = true
    begin
      while @continue
        control_json = ''
        tmp = s0.accept

        while buf = tmp.gets
          control_json += buf.to_s
        end

        control = JSON.load(control_json)
        run(control)

        tmp.close
      end
    rescue
      # nothing
    ensure
      socket.close
    end
  end

  def run(control)
    case control['function']
    # from web server
    when 'USER_CREATE'
      UserManager.create(control['field'])
    when 'USER_DELETE'
      UserManager.delete(control['field'])
    when 'VM_CREATE'
      @vmc.create(control['field']
    when 'VM_MODIFY'
      @vmc.modify(control['field'])
    when 'VM_DELETE'
      @vmc.delete(control['field'])
    when 'FW_CONTROL_ADD'
    when 'FW_CONTROL_MODIFY'
    when 'FW_CONTROL_DELETE'
    # from host
    when 'VM_CREATE_ACK'
      @vmc.ack_for_create(control['field'])
    when 'VM_MODIFY_ACK'
      @vmc.ack_for_modify(control['field'])
    when 'VM_DELETE_ACK'
      @vmc.ack_for_delete(control['field'])
    when 'RESOURCE_UPDATE'
      HostManager.update_host(control['field'])
    # error
    else
      puts 'unknown_function'
    end
  end

  def

  def add_observer

  end

  def end_server
    @continue = false
  end

end
