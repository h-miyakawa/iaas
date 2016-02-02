require 'json_api'
require 'control_sender'

class ControlManager

  def initialize(options)
    @ack_waitings = []
    @options = options
  end

  def handle_ack(pairs)
    @ack_waitings.each_with_index do |ack_waiting, i|
      match = true
      pairs.each do |key, value|
        unless (key == 'function' && ack_waiting[key] == value) || ack_waiting['field'][key] == value
          match = false
          break
        end
      end
      next if !match
      @ack_waitings.delete_at(i)
      return ack_waiting['field']
    end
    return nil
  end

end
