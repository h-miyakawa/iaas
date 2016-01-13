require 'active_support/core_ext/class/attribute_accessors'
require 'json'
require 'path_manager'
require 'port'
require 'slice_exceptions'
require 'slice_extensions'

# Virtual slice.
# rubocop:disable ClassLength
class Slice
  extend DRb::DRbUndumped
  include DRb::DRbUndumped

  cattr_accessor(:all, instance_reader: false) { [] }

  def self.create(name)
    if find_by(name: name)
      fail SliceAlreadyExistsError, "Slice #{name} already exists"
    end
    # edited by t-kitagawa
    new(name).tap {
      |slice| all << slice
      maybe_send_handler :create_slice
    }
  end

  def self.find_by(queries)
    queries.inject(all) do |memo, (attr, value)|
      memo.find_all do |slice|
        slice.__send__(attr) == value
      end
    end.first
  end

  def self.find_by!(queries)
    find_by(queries) || fail(SliceNotFoundError,
                             "Slice #{queries.fetch(:name)} not found")
  end

  def self.find(&block)
    all.find(&block)
  end

  def self.destroy(name)
    find_by!(name: name)
    Path.find { |each| each.slice == name }.each(&:destroy)
    all.delete_if { |each| each.name == name }
    maybe_send_handler :destroy
  end

  def self.destroy_all
    all.clear
    maybe_send_handler :destroy_all
  end

  @@observers = []
  def self.add_observer(observer)
    @@observers << observer
  end 
    
  attr_reader :name

  def initialize(name)
    @name = name
    @ports = Hash.new([].freeze)
  end
  private_class_method :new

  def add_port(port_attrs)
    port = Port.new(port_attrs)
    if @ports.key?(port)
      fail PortAlreadyExistsError, "Port #{port.name} already exists"
    end
    @ports[port] = [].freeze

    # added by t-kitagawa
    Slice.maybe_send_handler :add_port_to_slice
  end

  def delete_port(port_attrs)
    find_port port_attrs
    Path.find { |each| each.slice == @name }.select do |each|
      each.port?(Topology::Port.create(port_attrs))
    end.each(&:destroy)
    @ports.delete Port.new(port_attrs)

    # added by t-kitagawa
    Slice.maybe_send_handler :delete_port_in_slice
  end

  def find_port(port_attrs)
    mac_addresses port_attrs
    Port.new(port_attrs)
  end

  def each(&block)
    @ports.keys.each do |each|
      block.call each, @ports[each]
    end
  end

  def ports
    @ports.keys
  end

  def get_ports
    @ports
  end

  def add_mac_address(mac_address, port_attrs)
    port = Port.new(port_attrs)
    if @ports[port].include? Pio::Mac.new(mac_address)
      fail(MacAddressAlreadyExistsError,
           "MAC address #{mac_address} already exists")
    end
    @ports[port] += [Pio::Mac.new(mac_address)]

    # added by t-kitagawa
    Slice.maybe_send_handler :add_mac_address
  end

  def delete_mac_address(mac_address, port_attrs)
    find_mac_address port_attrs, mac_address
    @ports[Port.new(port_attrs)] -= [Pio::Mac.new(mac_address)]

    Path.find { |each| each.slice == @name }.select do |each|
      each.endpoints.include? [Pio::Mac.new(mac_address),
                               Topology::Port.create(port_attrs)]
    end.each(&:destroy)

    # added by t-kitagawa
    Slice.maybe_send_handler :delete_mac_address
  end

  def find_mac_address(port_attrs, mac_address)
    find_port port_attrs
    mac = Pio::Mac.new(mac_address)
    if @ports[Port.new(port_attrs)].include? mac
      mac
    else
      fail MacAddressNotFoundError, "MAC address #{mac_address} not found"
    end
  end

  def mac_addresses(port_attrs)
    port = Port.new(port_attrs)
    @ports.fetch(port)
  rescue KeyError
    raise PortNotFoundError, "Port #{port.name} not found"
  end

  def member?(host_id)
    @ports[Port.new(host_id)].include? host_id[:mac]
  rescue
    false
  end

  def to_s
    @name
  end

  def to_json(*_)
    %({"name": "#{@name}"})
  end

  def method_missing(method, *args, &block)
    @ports.__send__ method, *args, &block
  end

  # added by t-kitagawa
  def self.maybe_send_handler(method)
    @@observers.each do |each|
      if each.respond_to?(:slice_update)
        each.__send__ :slice_update, method
      end
    end
  end

end
# rubocop:enable ClassLength
