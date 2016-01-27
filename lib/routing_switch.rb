$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'forwardable'
require 'optparse'
require 'path_manager'
require 'sliceable_switch'
require 'topology_controller'

# L2 routing switch
class RoutingSwitch < Trema::Controller
  extend Forwardable

  # Command-line options of RoutingSwitch
  class Options
    attr_reader :slicing

    def initialize(args)
      @opts = OptionParser.new
      @opts.on('-s', '--slicing') { @slicing = true }
      @opts.parse [__FILE__] + args
    end
  end

  timer_event :flood_lldp_frames, interval: 1.sec

  def_delegators :@topology, :flood_lldp_frames

  def slice
    fail 'Slicing is disabled.' unless @options.slicing
    Slice
  end

  # @!group Trema event handlers

  def start(args)
    @options = Options.new(args)
    @path_manager = start_path_manager
    @topology = start_topology args
    logger.info 'Routing Switch started.'
  end

  def_delegators :@topology, :switch_ready
  def_delegators :@topology, :features_reply
  def_delegators :@topology, :switch_disconnected
  def_delegators :@topology, :port_modify

  def packet_in(dpid, message)
    @topology.packet_in(dpid, message)
    @path_manager.packet_in(dpid, message) unless message.lldp?
    # print message
    add_block_entry(message.source_ip_address, message.destination_ip_address, 100) unless message.lldp?
  end

  private

  def start_path_manager
    fail unless @options
    (@options.slicing ? SliceableSwitch : PathManager).new.tap(&:start)
  end

  def start_topology(args)
    fail unless @path_manager
    TopologyController.new.tap do |topology_controller|
      args.delete_if{|arg| arg =~ /\-s|\-\-slicing/} if @options.slicing
      topology_controller.start args
      topology_controller.add_observer @path_manager
      slice.add_observer @path_manager if @options.slicing
      @path_manager.set_topology topology_controller.topology
      @path_manager.add_observer topology_controller.view
    end
  end



  # def delete_firewall_flow_entry()
  # end # delete_firewall_flow_entry

  # black list
#   def add_firewall_flow_entry()
#       send_flow_mod_add(
#         datapath_id,
#         match: Match.new(
#           ip_source_address: src_ip_for_blocking,
#           ip_destination_address: dest_ip_for_blocking,
#           transport_source_port: src_port_for_blocking,
#           transport_destination_port: dest_port_for_blocking
#         )
#       )
#   end # add_firewall_flow_entry

  def add_block_entry(
    ip_src,
    ip_dst,
    priority
    )

    # get datapath id from ip address
    hosts = topology.hosts.each_with_object({}) do |host, tmp|
      mac_address, ip_address, dpid, port_no = *host
      if ip_address = ip_src then
        datapath_id = dpid
      end
    end

    # add flow entry
    # oldfathioned? nw_dst: ip_dst, dl_type: 0x0800
    send_flow_mod_add(
      datapath_id,
      priority: priority,
      match: Match.new(
        ip_source_address: ip_src,
        ip_destination_address: ip_dst,
      )
    )
  end
end
