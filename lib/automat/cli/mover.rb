require 'thor'
require 'automat'

module Automat::Cli
  class Mover < Thor
    def self.exit_on_failure?
        return true
    end

    desc "upload", "upload a file"

    option :localfile,
      aliases: "-l",
      desc: "local file",
      required: true

    option :s3file,
      aliases: "-s",
      desc: "s3 file",
      required: true

    def upload

      s = Automat::S3::Uploader.new(options)
      s.upload
    end

  end
end
