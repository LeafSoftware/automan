require 'automat'

module Automat::Cli
  class Stalker < Base

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
      aliases: "-l",
      desc: "beanstalk application version label"

    option :package,
      aliases: "-p",
      desc: "s3 path to version package (s3://bucket/package.zip)"

    option :manifest,
      aliases: "-m",
      desc: "s3 path to manifest file containing version label and package location"

    option :configuration_template,
      required: true,
      aliases: "-t",
      desc: "beanstalk configuration template name"

    option :beanstalk_name,
      aliases: "-b",
      desc: "alternate beanstalk environment name"

    option :number_to_keep,
      aliases: "-n",
      type: :numeric,
      desc: "cull old versions and keep newest NUMBER_TO_KEEP"

    def deploy
      # you must specify either a manifest file or both package and version label
      if options[:manifest].nil? &&
        (options[:version_label].nil? || options[:package].nil?)
        puts "Must specify either manifest or both version_label and package"
        help "deploy"
        exit 1
      end

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

    desc "update-config", "update beanstalk configuration template"

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

    def update_config
      Automat::Beanstalk::Configuration.new(options).update
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

    desc "upload-config", "validate and upload beanstalk configuration template files to s3"

    option :template_files,
      required: true,
      aliases: "-t",
      desc: "File system glob of configuration templates to upload"

    option :s3_path,
      required: true,
      aliases: "-p",
      desc: "S3 path to destination"

    def upload_config
      Automat::Beanstalk::Uploader.new(options).upload_config_templates
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

    desc "show-versions", "show all versions for an application"

    option :application,
      required: true,
      aliases: "-a",
      desc: "name of the application"

    def show_versions
      versions = Automat::Beanstalk::Version.new(options).versions
      versions.each do |v|
        tokens = [
          v[:application_name],
          v[:version_label],
          v[:date_created].iso8601
        ]
        say tokens.join("\t")
      end
    end

    desc "package", "upload a zip file to s3 to be deployed to beanstalk"

    option :destination,
      required: true,
      aliases: "-d",
      desc: "full s3 path of uploaded package"

    option :source,
      required: true,
      aliases: "-s",
      desc: "path to local zip file to be uploaded"

    option :manifest,
      aliases: "-m",
      desc: "if set, also upload a manifest file with full s3 path MANIFEST"

    option :version_label,
      aliases: "-l",
      desc: "version_label for manifest, required if -m"

    def package

      if !options[:manifest].nil? && options[:version_label].nil?
        puts "Must specify version_label when uploading manifest file"
        help "package"
        exit 1
      end

      Automat::Beanstalk::Package.new(options).upload_package
    end
  end
end
