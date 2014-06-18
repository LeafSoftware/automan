module Automat::Cloudformation
  class MissingParametersError < StandardError
  end

  class BadTemplateError < StandardError
  end

  class StackExistsError < StandardError
  end

  class MissingAutoScalingGroupError < StandardError
  end
end