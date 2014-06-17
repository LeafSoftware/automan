require 'thor'
require 'automat'

module Automat::Cli
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
      Automat::BeanstalkRouter.new(options).run
    end

    desc "deploy", "deploy a beanstalk service"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the service"

    option :environment,
      required: true,
      aliases: "-e",
      desc: "environment tag (e.g. dev, stage, prd)"

    option :version_label,
      required: true,
      aliases: "-l",
      desc: "beanstalk application version label"

    option :bucket,
      required: true,
      aliases: "-b",
      desc: "s3 bucket containing version package"

    option :configuration_template,
      required: true,
      aliases: "-t",
      desc: "beanstalk configuration template name"

    def deploy
      Automat::BeanstalkDeployer.new(options).deploy
    end

    desc "terminate", "terminate a beanstalk service"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the service"

    option :environment,
      required: true,
      aliases: "-e",
      desc: "environment tag (e.g. dev, stage, prd)"

    def terminate
      Automat::BeanstalkDeployer.new(options).terminate
    end
  end
end