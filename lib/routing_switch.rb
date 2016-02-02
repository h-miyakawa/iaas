$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'forwardable'
require 'optparse'
require 'path_manager'
require 'sliceable_switch'
require 'topology_controller'
require 'control_receiver'
require 'ip_address_manager'

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
    @ip_address_manager = IPAddressManager.new
    @control_receiver = ControlReceiver.new(@options)
    @control_receiver.vm_manager.add_ip_address_manager(@ip_address_manager)
    # 制御サーバ起動
    Thread.start(@control_receiver) do |cr|
      cr.start_server
    end
    # IPアドレス管理サーバ起動
    Thread.start(@ip_address_manager) do |iam|
      iam.start_manager
    end
    @control_receiver.add_fw_manager(self)
    @num_icmp = {}
    @threshold = 3
    @protocol_number = 1 #udp:17, icmp:1?
    logger.info 'Routing Switch started.'
  end

  def_delegators :@topology, :switch_ready
  def_delegators :@topology, :features_reply
  def_delegators :@topology, :switch_disconnected
  def_delegators :@topology, :port_modify

  def packet_in(dpid, message)
    # for DHCP
    case message.data
    when Dhcp::Discover, Dhcp::Offer, Dhcp::Request, Dhcp::Ack
      send_packet_out(
        dpid,
        packet_in: message,
        actions: SendOutPort.new(:flood)
      )
    else
      @topology.packet_in(dpid, message)
      unless message.lldp? then
        puts "packet_in"
        @path_manager.packet_in(dpid, message)

        # count ICMP packet
        data = message.data
        if ((data[:ether_type] == 0x0800) && (data[:ip_protocol] == @protocol_number))
          src = data[:source_ip_address].to_s
          unless @num_icmp.has_key?(src) then
            @num_icmp[src] = 1
          else
            @num_icmp[src] = @num_icmp[src] + 1
            if (@num_icmp[src] > @threshold) then
              puts "block", src
              options = {:ether_type => 0x0800,
                :source_ip_address => src
              }
              add_block_entry(10, options)
            end # if
          end # unless
        end # if
      end # unless
    end # case
  end # def

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

  # ip_src = options[:source_ip_address]
  # # get datapath id from ip address
  # host_info = get_host_info_from_ip(ip_src)
  # @_dpid = host_info[:dpid]
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

  def get_dpid_list
    list = Array.new
    @path_manager.topology.hosts.each_with_object({}) do |host, tmp|
      mac_address, ip_address, dpid, port_no = *host
      unless list.include?(dpid)  then
        list << dpid
      end
    end
    return list
  end

  def delete_firewall_entry(user_id, priority, options)
    dpids = get_dpid_list
    dpids.each do |dpid|
      # TCP: ip_protocol:6 
      send_flow_mod_delete(
        @_dpid,
        priority: priority,
        match: Match.new(options),
      )
    end
  end # delete_firewall_flow_entry

  def add_block_entry(user_id, priority, options)
    dpids = get_dpid_list
    dpids.each do |dpid|
      # add flow entry
      # TCP: ip_protocol:6 
      send_flow_mod_add(
        dpid,
        priority: priority,
        match: Match.new(options),
        # actions: SendOutPort.new(@port)
      )
    end
  end

end
