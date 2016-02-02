def get_datapath_id(host_ip_address)
  target_ip_address = "Input from User";
  hosts = topology.hosts.each_with_object({}) do |host, tmp|
    mac_address, ip_address, dpid, port_no = *host
    if ip_address = target_ip_address then
      return dpid
    end
  end
  # host not found
  return -1
end
  
# vendor/topology/lib/view/graphviz.rb
g_hosts = topology.hosts.each_with_object({}) do |host, tmp|
  mac_address, ip_address, dpid, port_no = *host
  new_label = "#{ip_address.to_s}\n#{mac_address.to_s}"
  if g_host = gviz.get_node(mac_address.to_s)
    tmp[mac_address.to_s] = g_host[label: new_label]
  else
    tmp[mac_address.to_s] = gviz.add_nodes(mac_address.to_s, shape: 'ellipse', label: new_label)
  end
  next unless g_switches[dpid]
  gviz.add_edges tmp[mac_address.to_s], g_switches[dpid], dir: 'none'
end




      puts "packet_in not lldp"
      # puts message.data[:ip_protocol]

      options = {}
      options[:ether_type] = 0x0800
      options[:source_ip_address] =  message.source_ip_address
      options[:ip_protocol] = 17
      # options[:destination_ip_address] = message.destination_ip_address
      # add_block_entry(
      #   100,
      #   options
      # )
      # delete_firewall_entry(
      #   100,
      #   options
      # )
      send_flow_mod_add(
        dpid,
        priority: 100,
        match: Match.new(options),
        actions: SendOutPort.new(2)
      )

      dump_flows = `sudo ovs-ofctl dump-flows brswitch1`.split("\n")
      dump_flows.each do |dump_flow|
        if dump_flow.include?("udp") then
          if dump_flow =~ /n_packets=(\d+)/ then
             @n_packets = $1
             break
          end
        end
      end
      # filter
      if (@n_packets.to_i > 3) then
        puts "n_packets: ", @n_packets
      end
