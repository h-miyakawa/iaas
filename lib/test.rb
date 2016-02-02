$LOAD_PATH.unshift File.dirname(__FILE__)

require 'control_receiver'

class Test

  class Options
    attr_reader :slicing

    def initialize
      @slicing = false
    end
  end

	def initialize
    @opt = Options.new
		@cr = ControlReceiver.new(@opt)
	end

	def start
		@cr.start_server
	end

end

p = Test.new
p.start
