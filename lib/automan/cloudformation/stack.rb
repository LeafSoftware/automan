require 'automan'

module Automan::Cloudformation
  class Stack < Automan::Base
    def initialize(options={})
      super
      @cfn = Aws::CloudFormation::Resource.new
    end

    add_option :name

    def exists?
      stack = cfn.stack(name)
      begin
        stack.stack_id
        true
      rescue Aws::CloudFormation::Errors::ValidationError
        false
      end
    end

    def status

    end

    def launch_complete?

    end

    def update_complete?

    end

    def update

    end

    def launch

    end

    def launch_or_update

    end

    def parse_template_parameters

    end

    def validate_template

    end
  end
end