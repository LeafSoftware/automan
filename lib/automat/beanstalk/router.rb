require 'automat/base'
require 'automat/beanstalk/errors'

module Automat::Beanstalk
  class Router < Automat::Base

    add_option :environment_name, :hosted_zone_name

    def elb_cname_from_beanstalk_environment(env_name)
      opts = {
        environment_name: env_name
      }
      response = eb.describe_environment_resources opts

      unless response.successful?
        raise RequestFailedError, "describe_environment_resources failed: #{response.error}"
      end

      response.data[:environment_resources][:load_balancers].first[:name]
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

      elb_name = elb_cname_from_beanstalk_environment environment_name
      elb_data = elb.load_balancers[elb_name]

      targets = [
        hosted_zone_name,
        'www.'  + hosted_zone_name,
        '\052.' + hosted_zone_name
      ]

      targets.each do |target|

        update_dns_alias(
          hosted_zone_name,
          target,
          elb_data
        )
      end
    end
  end
end