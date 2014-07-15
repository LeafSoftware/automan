require 'automat'
require 'wait'

module Automat::Beanstalk
  class Router < Automat::Base

    add_option :environment_name,
               :hosted_zone_name,
               :hostname

    attr_accessor :attempts_made

    def initialize(options=nil)
      super
      @wait = Wait.new({
        attempts: 10,
        delay:    60,   # 10 x 60s == 10m
        debug:    true,
        logger:   @logger,

        # rescue from InvalidChangeBatch
        # just because we've found the elb cname doesn't
        # mean it is immediately available as a route53 alias
        rescuer:  WaitRescuer.new(AWS::Route53::Errors::InvalidChangeBatch)
      })
    end

    def elb_cname_from_beanstalk_environment(env_name)
      opts = {
        environment_name: env_name
      }
      response = eb.describe_environment_resources opts

      unless response.successful?
        raise RequestFailedError, "describe_environment_resources failed: #{response.error}"
      end

      balancers = response.data[:environment_resources][:load_balancers]
      if balancers.empty?
        return nil
      end

      balancers.first[:name]
    end

    # be sure alias_name ends in period
    def update_dns_alias(zone_name, alias_name, elb_data)
      zone = r53.hosted_zones.select {|z| z.name == zone_name}.first
      rrset = zone.rrsets[alias_name, 'A']

      target = elb_data.dns_name.downcase

      if rrset.exists?
        if rrset.alias_target[:dns_name] == target + '.'
          logger.info "record exists: #{alias_name} -> #{rrset.alias_target[:dns_name]}"
          return
        else
          logger.info "removing old record #{alias_name} -> #{rrset.alias_target[:dns_name]}"
          rrset.delete
        end
      end

      logger.info "creating record #{alias_name} -> #{target}"
      zone.rrsets.create(
        alias_name,
        'A',
        alias_target: {
          hosted_zone_id: elb_data.canonical_hosted_zone_name_id,
          dns_name:       target,
          evaluate_target_health: false
        }
      )
    end

    def run
      log_options

      wait.until do |attempt|

        self.attempts_made = attempt

        logger.info "waiting for elb cname..."
        elb_name = elb_cname_from_beanstalk_environment environment_name

        if elb_name.nil?
          false
        else

          elb_data = elb.load_balancers[elb_name]

          update_dns_alias(
            hosted_zone_name,
            hostname,
            elb_data
          )
          true
        end

      end
    end
  end
end
