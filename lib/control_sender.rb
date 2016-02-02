require 'socket'

class ControlSender

  def initialize(destination_ip_address, port, control)
    @destination_ip_address = destination_ip_address
    @port = port
    @control = control
  end

  def send
    begin
      sleep(0.1)
      sock = TCPSocket.open(@destination_ip_address, @port)
    rescue
      puts "TCPSocket.open failed : #$!\n"
    rescue Interrupt
      puts "ControlSender sleep failed."
    else
      sock.write(@control)
      puts "send to #{@destination_ip_address}:#{@port}"
      sock.close
    end
  end

end
