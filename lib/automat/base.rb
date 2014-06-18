require 'automat'
require 'automat/mixins/aws_caller'
require 'logger'

module Automat
  class Base
    @@options = []

    attr_accessor :logger

    include Automat::Mixins::AwsCaller

    def initialize(options=nil)
      @logger = Logger.new(STDOUT)
      @log_aws_calls = false

      if !options.nil?
        options.each_pair do |k,v|
          accessor = (k.to_s + '=').to_sym
          send(accessor, v)
        end
      end
    end

    def self.add_option(*args)
      args.each do |arg|
        self.class_eval("def #{arg};@#{arg};end")
        self.class_eval("def #{arg}=(val);@#{arg}=val;end")
        @@options << arg
      end
    end

    def log_options
      biggest_opt_name_length = @@options.max_by(&:length).length
      message = "called with:\n"
      @@options.sort.each do |opt|
        opt_name = opt.to_s.concat(':').ljust(biggest_opt_name_length)
        message += "#{opt_name} #{send(opt)}"
      end
      logger.info message
    end
  end
end