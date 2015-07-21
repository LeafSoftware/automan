require 'automan'

# stub all calls to aws for v1 sdk
AWS.stub!

# stub all calls to aws for v2 sdk
Aws.config[:stub_responses] = true

# turn off logging for all Automan classes
module Automan
  class Base
    def logger
      Logger.new('/dev/null')
    end
  end
end


RSpec.configure do |config|
  # rspec configuration here.
end