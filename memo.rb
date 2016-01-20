target_ip_address = "Input from User";
hosts = topology.hosts.each_with_object({}) do |host, tmp|
  mac_address, ip_address, dpid, port_no = *host
  if ip_address = target_ip_address then
    target_dpid = dpid
    break
  end
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
