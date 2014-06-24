require 'automat/mixins/utils'

describe Automat::Mixins::Utils do
  let(:s) { (Class.new { include Automat::Mixins::Utils }).new }

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

  it "adds String#underscore" do
    s = String.new
    s.should respond_to :underscore
  end

  describe "String#underscore" do
    it "underscore's like a boss" do
      "Namespace".underscore.should eq "namespace"
      "OptionName".underscore.should eq "option_name"
      "Value".underscore.should eq "value"
    end
  end

  it { s.should respond_to :region_from_az }

  it "returns az properly" do
    s.region_from_az("us-east-1a").should eq 'us-east-1'
    s.region_from_az("us-east-1b").should eq 'us-east-1'
    s.region_from_az("us-east-1c").should eq 'us-east-1'
    s.region_from_az("us-east-1d").should eq 'us-east-1'
    s.region_from_az("ap-northeast-1a").should eq 'ap-northeast-1'
    s.region_from_az("ap-northeast-1b").should eq 'ap-northeast-1'
    s.region_from_az("ap-northeast-1c").should eq 'ap-northeast-1'
    s.region_from_az("sa-east-1a").should eq 'sa-east-1'
    s.region_from_az("sa-east-1b").should eq 'sa-east-1'
    s.region_from_az("ap-southeast-1a").should eq 'ap-southeast-1'
    s.region_from_az("ap-southeast-1b").should eq 'ap-southeast-1'
    s.region_from_az("ap-southeast-2a").should eq 'ap-southeast-2'
    s.region_from_az("ap-southeast-2b").should eq 'ap-southeast-2'
    s.region_from_az("us-west-2a").should eq 'us-west-2'
    s.region_from_az("us-west-2b").should eq 'us-west-2'
    s.region_from_az("us-west-2c").should eq 'us-west-2'
    s.region_from_az("us-west-1a").should eq 'us-west-1'
    s.region_from_az("us-west-1c").should eq 'us-west-1'
    s.region_from_az("eu-west-1a").should eq 'eu-west-1'
    s.region_from_az("eu-west-1b").should eq 'eu-west-1'
    s.region_from_az("eu-west-1c").should eq 'eu-west-1'
  end
end