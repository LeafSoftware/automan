require 'aws-sdk'

module Automan
  module Mixins
    module AwsCaller

      def account
        ENV['AWS_ACCOUNT_ID']
      end

      def configure_aws(options={})
        if ENV['AWS_ROLE']
          sts = AWS::STS.new

          @logger.info "Assuming role #{ENV['AWS_ROLE']}"
          provider = AWS::Core::CredentialProviders::AssumeRoleProvider.new(
            sts: sts,
            role_arn: ENV['AWS_ROLE'],
            role_session_name: "automan-aws-sdk"
          )
          options[:credential_provider] = provider
        end

        AWS.config(options)
      end

      attr_writer :eb
      def eb
        if @eb.nil?
          @eb = AWS::ElasticBeanstalk.new.client
        end
        @eb
      end

      attr_writer :s3
      def s3
        if @s3.nil?
          @s3 = AWS::S3.new
        end
        @s3
      end

      S3_PROTO = 's3://'

      def looks_like_s3_path?(path)
        path.start_with? S3_PROTO
      end

      def parse_s3_path(path)
        if !looks_like_s3_path? path
          raise ArgumentError, "s3 path must start with '#{S3_PROTO}'"
        end

        rel_path = path[S3_PROTO.length..-1]
        bucket = rel_path.split('/').first
        key = rel_path.split('/')[1..-1].join('/')

        return bucket, key
      end

      def s3_object_exists?(s3_path)
        bucket, key = parse_s3_path s3_path
        s3.buckets[bucket].objects[key].exists?
      end

      def s3_read(s3_path)
        bucket, key = parse_s3_path s3_path
        s3.buckets[bucket].objects[key].read
      end

      attr_writer :r53
      def r53
        if @r53.nil?
          @r53 = AWS::Route53.new
        end
        @r53
      end

      attr_writer :elb
      def elb
        if @elb.nil?
          @elb = AWS::ELB.new
        end
        @elb
      end

      attr_writer :cfn
      def cfn
        if @cfn.nil?
          @cfn = AWS::CloudFormation.new
        end
        @cfn
      end

      attr_writer :as
      def as
        if @as.nil?
          @as = AWS::AutoScaling.new
        end
        @as
      end

      attr_writer :rds
      def rds
        if @rds.nil?
          @rds = AWS::RDS.new
        end
        @rds
      end

      attr_writer :ec2
      def ec2
        if @ec2.nil?
          @ec2 = AWS::EC2.new
        end
        @ec2
      end

    end
  end
end