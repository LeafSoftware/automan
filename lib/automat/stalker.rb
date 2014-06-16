require 'thor'

module Automat

  class Stalker < Thor

    desc "alias", "point dns to elb"

    option :environment_name,
      required: true,
      aliases: "-e",
      desc: "Beanstalk environment containing target ELB"

    option :hosted_zone_name,
      required: true,
      aliases: "-z",
      desc: "Hosted zone for which apex will be routed to ELB"
    def alias
      br = Automat::BeanstalkRouter.new
      br.environment_name = options[:environment_name]
      br.hosted_zone_name = options[:hosted_zone_name]
      br.run
    end


  end
end