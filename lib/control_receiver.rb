require 'socket'
require 'json'
require 'vm_manager'
require 'host_manager'
require 'user_manager'
require 'settings'
require 'control_sender'

class ControlReceiver

  attr_reader :vm_manager

  def initialize(options)
    @vm_manager = VirtualMachineManager.new(options)
    @user_manager = UserManager.new(options)
    @host_manager = HostManager.new(options)
    @observers = []
  end

  def start_server
    puts "start server"
    @socket = TCPServer.open(Settings::LISTENING_PORT)
    @continue = true
    while @continue
      control_json = ''
      tmp = @socket.accept

      while buf = tmp.gets
        control_json += buf.to_s
      end

      control = JSON.load(control_json)
      run(control)

      tmp.close
    end
  end

  def run(control)
    return unless control
    puts control['function']
    case control['function']
    when 'USER_CREATE'
      @user_manager.create(control['field'])
    when 'USER_DELETE'
      @user_manager.delete(control['field'])
    when 'VM_CREATE'
      @vm_manager.create(control['field'])
    when 'VM_MODIFY'
      @vm_manager.modify(control['field'])
    when 'VM_DELETE'
      @vm_manager.delete(control['field'])
    when 'VM_START'
      @vm_manager.start(control['field'])
    when 'VM_STOP'
      @vm_manager.stop(control['field'])
    when 'FW_CONTROL_ADD', 'FW_CONTROL_MODIFY', 'FW_CONTROL_DELETE'
      fw_update(control)
    when 'VM_CREATE_ACK'
      @vm_manager.ack_for_create(control['field'])
    when 'VM_MODIFY_ACK'
      @vm_manager.ack_for_modify(control['field'])
    when 'VM_DELETE_ACK'
      @vm_manager.ack_for_delete(control['field'])
    when 'VM_START_ACK'
      @vm_manager.ack_for_start(control['field'])
    when 'VM_STOP_ACK'
      @vm_manager.ack_for_stop(control['field'])
    when 'USER_UPDATE'
      @user_manager.update(control['field'])
    when 'VM_STATUS_ACK'
      @user_manager.ack_for_update(control['field'])
    when 'HOST_UPDATE'
      @host_manager.update(control['field'])
    # error
    else
      puts 'unknown_function'
    end
  end

  def fw_update(control)
    @observers.each do |observer|
      observer.update(control)
    end
  end

  def fw_ack(control)
    ControlSender.new(WEB_SERVER_IP_ADDRESS, Settings::WEB_SERVER_PORT, control.to_json).send
  end

  def add_observer(controller)
    @observers << controller
  end

  def end_server
    @continue = false
    @socket.close
  end

end
