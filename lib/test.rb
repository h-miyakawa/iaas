$LOAD_PATH.unshift File.dirname(__FILE__)

require 'control_receiver'
require 'ip_address_manager'

class Test

	def initialize
		@iam = IPAddressManager.new
	end

	def start
		@iam.start_manager
	end

end

p = Test.new
p.start

