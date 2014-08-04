require 'automan'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Automan::Chef
  class Uploader < Automan::Base
    add_option :repopath, :s3path, :chefver, :tempdir

    def upload
      log_options

      logger.info "packaging #{repopath} to #{tempdir}"
      tgz = Zlib::GzipWriter.new(File.open("#{tempdir}/chef-repo.tgz", 'wb'))
      Minitar.pack(repopath, tgz)

      versions = ["#{chefver}", "latest"]
      versions.each do |version|
        options = {
          localfile: "#{tempdir}/chef-repo.tgz",
          s3file: "#{s3path}/#{version}/chef-repo.tgz"
        }
        s = Automan::S3::Uploader.new options
        s.upload
      end

    end

  end
end