module Automan::Ec2
  class RequestFailedError < StandardError
  end

  class TooManyRedisClusters < StandardError
  end

  class TooManyRedisNodes < StandardError
  end
end