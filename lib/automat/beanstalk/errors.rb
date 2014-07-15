module Automat::Beanstalk
  class RequestFailedError < StandardError
  end

  class ELBNameNotFoundError < StandardError
  end

  class MissingManifestError < StandardError
  end

  class MissingPackageFileError < StandardError
  end

  class InvalidEnvironmentStatusError < StandardError
  end
end