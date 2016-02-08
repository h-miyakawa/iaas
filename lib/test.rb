$LOAD_PATH.unshift File.dirname(__FILE__)

require 'control_receiver'
require 'ip_address_manager'

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
                @iam = IPAddressManager.new
	end

	def start
          Thread.start(@cr) do |cr|
            cr.start_server
          end
          @iam.start_manager
	end

end

p = Test.new
p.start
