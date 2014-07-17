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

  class NoConfigurationTemplatesError < StandardError
  end

  class InvalidConfigurationTemplateError < StandardError
  end
end