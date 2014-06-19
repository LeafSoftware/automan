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
end