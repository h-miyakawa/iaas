require 'socket'

class ControlSender

  def initialize(destination_ip_address, port, control)
    @destination_ip_address = destination_ip_address
    @port = port
    @control = control
  end

  def send
    begin
      sock = TCPSocket.open(@destination_ip_address, @port)
    rescue
      puts "TCPSocket.open failed : #$!\n"
    else
      sock.write(@control)
      sock.close
    end
  end

end
