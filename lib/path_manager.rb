require 'graph'
require 'path'
require 'trema'

# L2 routing path manager
class PathManager < Trema::Controller

  attr_reader :topology

  def start
    @observers = []
    @graph = Graph.new
    logger.info 'Path Manager started.'
  end

  # added by t-kitagawa
  def add_observer(observer)
    @observers << observer
  end

  # added by t-kitagawa
  def set_topology(topology)
    @topology = topology
  end

  # This method smells of :reek:FeatureEnvy but ignores them
  def packet_in(_dpid, message)
    path = maybe_create_shortest_path(message)
    ports = path ? [path.out_port] : @graph.external_ports
    ports.each do |each|
      send_packet_out(each.dpid,
                      raw_data: message.raw_data,
                      actions: SendOutPort.new(each.number))
    end
    maybe_send_handler :packet_in, path
  end

  # added by t-kitagawa
  def add_switch(dpid, _topology)
    maybe_send_handler :add_switch, dpid
  end

  # added by t-kitagawa
  def delete_switch(dpid, _topology)
    maybe_send_handler :delete_switch, dpid
  end

  def add_port(port, _topology)
    @graph.add_link port.dpid, port
    maybe_send_handler :add_port, port
  end

  def delete_port(port, _topology)
    @graph.delete_node port
    maybe_send_handler :delete_port, port
  end

  # TODO: update all paths
  def add_link(port_a, port_b, _topology)
    @graph.add_link port_a, port_b
    maybe_send_handler :add_link, port_a, port_b
  end

  def delete_link(port_a, port_b, _topology)
    @graph.delete_link port_a, port_b
    Path.find { |each| each.link?(port_a, port_b) }.each(&:destroy)
    maybe_send_handler :delete_link, port_a, port_b
  end

  def add_host(mac_address, port, _topology)
    @graph.add_link mac_address, port
    maybe_send_handler :add_host, mac_address, port
  end

  private

  def maybe_create_shortest_path(packet_in)
    shortest_path = @graph.dijkstra(packet_in.source_mac,
                                    packet_in.destination_mac)
    return unless shortest_path
    Path.create shortest_path, packet_in
  end

  # added by t-kitagawa
  def maybe_send_handler(method, *args)
    @observers.each do |each|
      if each.respond_to?(:update)
        # for graphviz
        each.__send__ :update, method, args, @topology, Path.all, []
      end
      # for text_mode
      each.__send__ method, *args if each.respond_to?(method)
    end
  end

end
