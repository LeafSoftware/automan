require 'thor'
require 'automat'

module Automat::Cli
  class Stalker < Thor

    def self.exit_on_failure?
        return true
    end

    desc "alias", "point dns to elb"

    option :environment_name,
      required: true,
      aliases: "-e",
      desc: "Beanstalk environment containing target ELB"

    option :hosted_zone_name,
      required: true,
      aliases: "-z",
      desc: "Hosted zone for which apex will be routed to ELB"

    option :hostname,
      required: true,
      aliases: "-h",
      desc: "Alias to create (must be fqdn, e.g. 'dev1.dydev.me')"

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

    option :number_to_keep,
      aliases: "-n",
      type: :numeric,
      desc: "cull old versions and keep newest NUMBER_TO_KEEP"

    def deploy
      Automat::Beanstalk::Deployer.new(options).deploy
    end

    desc "terminate", "terminate a beanstalk environment"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the beanstalk environment"

    def terminate
      Automat::Beanstalk::Terminator.new(options).terminate
    end

    desc "create-app", "create beanstalk application"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the application"

    def create_app
      Automat::Beanstalk::Application.new(options).create
    end

    desc "delete-app", "delete beanstalk application"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the application"

    def delete_app
      Automat::Beanstalk::Application.new(options).delete
    end

    desc "create-config", "create beanstalk configuration template"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the configuration template"

    option :application,
      required: true,
      aliases: "-a",
      desc: "name of the application"

    option :template,
      required: true,
      aliases: "-t",
      desc: "file containing configuration options"

    option :platform,
      required: "true",
      aliases: "-p",
      default: "64bit Windows Server 2012 running IIS 8",
      desc: "beanstalk solution stack name"

    def create_config
      Automat::Beanstalk::Configuration.new(options).create
    end

    desc "delete-config", "delete beanstalk configuration template"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the configuration template"

    option :application,
      required: true,
      aliases: "-a",
      desc: "name of the application"

    def delete_config
      Automat::Beanstalk::Configuration.new(options).delete
    end

    desc "delete-version", "delete an application version"

    option :application,
      required: true,
      aliases: "-a",
      desc: "name of the application"

    option :label,
      required: true,
      aliases: "-l",
      desc: "version label to be deleted"

    def delete_version
      Automat::Beanstalk::Version.new(options).delete
    end

    desc "cull-versions", "delete oldest versions, keeping N newest"

    option :application,
      required: true,
      aliases: "-a",
      desc: "name of the application"

    option :number_to_keep,
      required: true,
      aliases: "-n",
      type: :numeric,
      desc: "keep newest NUMBER_TO_KEEP versions"

    def cull_versions
      Automat::Beanstalk::Version.new(options).cull_versions(options[:number_to_keep])
    end
  end
end
