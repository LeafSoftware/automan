module Automat::Cloudformation
  class MissingParametersError < StandardError
  end

  class BadTemplateError < StandardError
  end

  class StackExistsError < StandardError
  end

  class StackDoesNotExistError < StandardError
  end

  class StackBrokenError < StandardError
  end

  class WaitTimedOutError < StandardError
  end

  class MissingAutoScalingGroupError < StandardError
  end

  class MissingManifestError < StandardError
  end

  class NoTemplatesError < StandardError
  end

  class InvalidTemplateError < StandardError
  end
end