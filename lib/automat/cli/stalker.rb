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
      Automat::Beanstalk::Router.new(options).run
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

    option :package,
      required: true,
      aliases: "-p",
      desc: "s3 path to version package (s3://bucket/package.zip)"

    option :configuration_template,
      required: true,
      aliases: "-t",
      desc: "beanstalk configuration template name"

    def deploy
      Automat::Beanstalk::Deployer.new(options).deploy
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
      Automat::Beanstalk::Deployer.new(options).terminate
    end

    desc "create-app", "create beanstalk application"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the application"

    def create_app
      Automat::Beanstalk::Application.new(options).create
    end
  end
end
