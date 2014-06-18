require 'automat/base'
require 'automat/cloudformation/errors'

module Automat::Cloudformation
  class Replacer < Automat::Base
    add_option :name

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
      logger.info "replacing all auto-scaling instances in #{name}"

      if stack_asg.nil?
        raise MissingAutoScalingGroupError, "No ASG found for stack #{name}"
      end

      stack_asg.ec2_instances.each do |i|
        logger.info "terminating instance #{i.id}"
        i.terminate
      end
    end

  end
end