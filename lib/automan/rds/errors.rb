module Automan::RDS
  class RequestFailedError < StandardError
  end

  class DatabaseDoesNotExistError < StandardError
  end
end