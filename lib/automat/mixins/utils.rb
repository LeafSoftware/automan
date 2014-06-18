module Automat::Mixins
  module Utils

    def parse_s3_path(path)

      if !path.start_with? 's3://'
        raise ArgumentError, "s3 path must start with 's3://'"
      end

      rel_path = path[5..-1]
      bucket = rel_path.split('/').first
      key = rel_path.split('/')[1..-1].join('/')

      return bucket, key

    end
  end
end
