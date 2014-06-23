require 'automat/base'
require 'automat/cloudformation/errors'
require 'wait'

module Automat::Cloudformation
  class Replacer < Automat::Base
    add_option :name

    def initialize(options=nil)
      @wait = Wait.new({
        delay: 60,
        attempts: 20, # 20 x 60s == 20m
        debug: true,
        logger: @logger
      })
      super
    end

    # potential states
    # stack does not exist
    # CREATE_IN_PROGRESS | CREATE_FAILED | CREATE_COMPLETE
    # ROLLBACK_IN_PROGRESS | ROLLBACK_FAILED | ROLLBACK_COMPLETE
    # DELETE_IN_PROGRESS | DELETE_FAILED | DELETE_COMPLETE
    # UPDATE_IN_PROGRESS | UPDATE_COMPLETE_CLEANUP_IN_PROGRESS | UPDATE_COMPLETE
    # UPDATE_ROLLBACK_IN_PROGRESS | UPDATE_ROLLBACK_FAILED | UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS | UPDATE_ROLLBACK_COMPLETE

    # so we want:
    # when CREATE_COMPLETE | UPDATE_COMPLETE then continue
    # when CREATE_FAILED | .*ROLLBACK_.* | ^DELETE_.* then raise error
    # else try again
    #
    def ok_to_replace_instances?(stack_status)
      case stack_status
      when 'CREATE_COMPLETE', 'UPDATE_COMPLETE'
        true
      when 'CREATE_FAILED', /^.*ROLLBACK.*$/, /^DELETE.*/
        raise StackBrokenError, "Stack is in broken state #{stack_status}"
      else
        false
      end
    end

    def stack_exists?(stack_name)
      cfn.stacks[stack_name].exists?
    end

    def stack_asg
      resources = cfn.stacks[name].resources
      asgs = resources.select {|i| i.resource_type == "AWS::AutoScaling::AutoScalingGroup"}
      if asgs.nil? || asgs.empty?
        return nil
      end
      asg_id = asgs.first.physical_resource_id
      as.groups[asg_id]
    end

    # terminate all running instances in the ASG so that new
    # machines with the latest build will be started
    def replace_instances
      log_options

      unless stack_exists?(name)
        raise StackDoesNotExistError, "Stack #{name} does not exist."
      end

      ex = WaitTimedOutError.new "Timed out waiting to replace instances."
      wait_until(ex) do

        ok_to_replace_instances?(cfn.stacks[name].status)

      end

      logger.info "replacing all auto-scaling instances in #{name}"

      if stack_asg.nil?
        raise MissingAutoScalingGroupError, "No ASG found for stack #{name}"
      end

      stack_asg.ec2_instances.each do |i|
        if i.status == :running
          logger.info "terminating instance #{i.id}"
          i.terminate
        else
          logger.info "Not terminating #{i.id} due to status: #{i.status}"
        end
      end
    end

  end
end