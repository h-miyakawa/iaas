require 'graphviz'

module View
  # Topology controller's GUI (graphviz).
  class Graphviz

    #BASE_COLOR = 0xf54321

    def initialize(output = 'topology.png')
      @output = output
    end

    # rubocop:disable AbcSize
    def update(_event, _changed, topology, paths, slices)

      GraphViz.new(:G) do |gviz|

        color_names = ["red","blue","green","brown","cyan","gold","mediumpurple","orange"]

        g_switches = topology.switches.each_with_object({}) do |switch, tmp|
          tmp[switch] = gviz.add_nodes(switch.to_hex, shape: 'box')
        end

        topology.links.each do |link|
          g_sw1 = g_switches[link.dpid_a]
          g_sw2 = g_switches[link.dpid_b]
          next unless g_sw1 && g_sw2
          gviz.add_edges g_sw1, g_sw2, dir: 'none'
        end

        slice_colors = slices.each.with_index.each_with_object({})  do |(slice, i), tmp|
          color_name = color_names[i%color_names.length]
          g_slice = gviz.add_graph("cluster_#{slice.name}", label: slice.name, color: color_name , style: "dashed")
          slice.ports.each do |port|
            slice.get_ports[port].each do |mac_address|
              tmp[mac_address.to_s] = color_name
              g_slice.add_nodes(mac_address.to_s, shape: 'ellipse')
            end
          end
        end

        g_hosts = topology.hosts.each_with_object({}) do |host, tmp|
          mac_address, ip_address, dpid, port_no = *host
          new_label = "#{ip_address.to_s}\n#{mac_address.to_s}"
          if g_host = gviz.get_node(mac_address.to_s)
            tmp[mac_address.to_s] = g_host[label: new_label]
          else
            tmp[mac_address.to_s] = gviz.add_nodes(mac_address.to_s, shape: 'ellipse', label: new_label)
          end
          next unless g_switches[dpid]
          gviz.add_edges tmp[mac_address.to_s], g_switches[dpid], dir: 'none', headlabel: port_no.to_s
        end

        paths.each do |path|
	  full_path = path.full_path
          unless path_color = slice_colors[full_path.first.to_s] then
            path_color = "red"
          end

          full_path.each_with_index do |node, i|
            next if i % 2 == 1
            if i == 0 then
              g_node1 = g_hosts[full_path[i].to_s]
            else
              g_node1 = g_switches[full_path[i].dpid]  
            end 

            if i == full_path.length - 2 then
              g_node2 = g_hosts[full_path[i + 1].to_s]
            else
              g_node2 = g_switches[full_path[i + 1].dpid]
            end

            gviz.add_edges g_node1, g_node2, color: path_color
          end
        end

        gviz.output png: @output

      end
    end

    # rubocop:enable AbcSize

    def to_s
      "Graphviz mode, output = #{@output}"
    end

    def c_rot(base_num, count)
      "#%06x" % ((base_num >> count%24) | (base_num << (24 - count%24)) & 0xffffff)
    end

  end
end
