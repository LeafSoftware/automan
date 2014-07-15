require 'automat/mixins/aws_caller'

describe Automat::Mixins::AwsCaller do
  let(:s) { (Class.new { include Automat::Mixins::AwsCaller }).new }

  it { s.should respond_to :s3 }
  it { s.should respond_to :cfn }
  it { s.should respond_to :as }
  it { s.should respond_to :eb }
  it { s.should respond_to :r53 }
  it { s.should respond_to :elb }
  it { s.should respond_to :rds }
  it { s.should respond_to :ec2 }

  it { s.should respond_to :parse_s3_path }
  it "parses correctly" do
    bucket, key = s.parse_s3_path('s3://foo/bar/baz')
    bucket.should eq('foo')
    key.should eq ('bar/baz')
  end

  it "raises error if it doesn't start with s3://" do
    expect {
      s.parse_s3_path 'foo'
    }.to raise_error ArgumentError
  end
end
