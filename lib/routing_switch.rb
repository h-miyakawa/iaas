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
      
    unless message.lldp? then
      options = {}
      options[:ether_type] = 0x0800
      options[:source_ip_address] =  message.source_ip_address
      # options[:destination_ip_address] = message.destination_ip_address
      add_block_entry(
        100,
        options
      )
      delete_firewall_entry(
        100,
        options
      )
    end
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

  def get_host_info_from_ip(ip_addr)
    hosts = @path_manager.topology.hosts.each_with_object({}) do |host, tmp|
      mac_address, ip_address, dpid, port_no = *host
      if ip_address == ip_addr then
        host_info = {}
        host_info[:dpid] = dpid
        host_info[:port_no] = port_no
        return host_info
      end
    end
  end

  def delete_firewall_entry(
    priority,
    options
  )
    ip_src = options[:source_ip_address]
    # get datapath id from ip address
    host_info = get_host_info_from_ip(ip_src)
    @_dpid = host_info[:dpid]

    # add flow entry
    # TCP: ip_protocol:6 
    send_flow_mod_delete(
      @_dpid,
      priority: priority,
      match: Match.new(options),
    )
  end # delete_firewall_flow_entry

  def add_block_entry(
    priority,
    options
  )

    ip_src = options[:source_ip_address]
    # get datapath id from ip address
    host_info = get_host_info_from_ip(ip_src)
    @_dpid = host_info[:dpid]

    # add flow entry
    # TCP: ip_protocol:6 
    send_flow_mod_add(
      @_dpid,
      priority: priority,
      match: Match.new(options),
      # actions: SendOutPort.new(@port)
    )
  end
end
