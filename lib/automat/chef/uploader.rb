require 'automat/base'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Automat::Chef
  class Uploader < Automat::Base
    add_option :repopath, :s3path, :chefver, :tempdir

    def upload
      log_options

      logger.info "packaging #{repopath} to #{tempdir}"
      tgz = Zlib::GzipWriter.new(File.open("#{tempdir}/chef-repo.tgz", 'wb'))
      Minitar.pack(repopath, tgz)

      versions=[ "#{chefver}","latest"]
      versions.each do |myver|
        options={ :localfile => "#{tempdir}/chef-repo.tgz", :s3file => "#{s3path}/#{myver}/chef-repo.tgz" }
        s = Automat::S3::Uploader.new(options)
        s.upload
      end

    end

  end
end