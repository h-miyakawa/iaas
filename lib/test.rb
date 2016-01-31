$LOAD_PATH.unshift File.dirname(__FILE__)

require 'control_receiver'

class Test

	def initialize
		@cr = ControlReceiver.new
	end

	def start
		@cr.start_server
	end

end

p = Test.new
p.start

