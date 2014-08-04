require 'thor'
require 'automan'

module Automan::Cli
  class Baker < Thor
    def self.exit_on_failure?
        return true
    end

    desc "create", "create an image"

    option :instance,
      aliases: "-i",
      desc: "instance to image",
      required: true

    option :name,
      aliases: "-n",
      desc: "what to name the image",
      required: true

    option :prune,
      aliases: "-p",
      type: :boolean,
      default: true,
      desc: "delete AMIs older than 30 days"

    def create

      s = Automan::Ec2::Image.new(options)
      s.create
      s.prune_amis if options[:prune]
    end

    desc "upload", "upload a chef repo"

    option :repopath,
      aliases: "-r",
      desc: "path to chef repo",
      required: true

    option :s3path,
      aliases: "-s",
      desc: "s3 path to chef artifacts",
      required: true

    option :chefver,
      aliases: "-c",
      desc: "chef version",
      required: true

    option :tempdir,
      aliases: "-t",
      desc: "temporary directory",
      required: true

    def upload

      s = Automan::Chef::Uploader.new(options)
      s.upload
    end
  end
end
