require 'aws-sdk'

module Automat
  module Mixins
    module AwsCaller

      def account
        ENV['AWS_ACCOUNT_ID']
      end

      attr_reader :log_aws_calls
      def log_aws_calls=(value)
        if value == true
          AWS.config(logger: @logger)
        else
          AWS.config(logger: nil)
        end
        @log_aws_calls = value
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