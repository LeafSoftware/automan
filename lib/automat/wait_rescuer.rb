require 'wait'

class ::WaitRescuer < Wait::BaseRescuer
  def initialize
    super(nil)
  end
  # Logs an exception.
  def log(exception)
    return if @logger.nil?

    klass = exception.class.name
    # We can omit the message if it's identical to the class name.
    message = exception.message unless exception.message == klass

    @logger.debug("Rescuer") { "rescued: #{klass}#{": #{message}" if message}" }
  end
end