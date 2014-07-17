require 'automat/mixins/aws_caller'

describe Automat::Mixins::AwsCaller do
  let(:s) { (Class.new { include Automat::Mixins::AwsCaller }).new }

  services = [
    :s3, :cfn, :as, :eb, :r53, :elb, :rds, :ec2
  ]

  services.each do |svc|
    it { s.should respond_to svc }
  end

  it { s.should respond_to :parse_s3_path }

  describe '#parse_s3_path' do
    it "parses s3 path into bucket and key" do
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

  describe '#looks_like_s3_path?' do
    it 'returns true if it begins with "s3://"' do
      s.looks_like_s3_path?('s3://foo').should be_true
    end

    it 'returns false if it does not start with "s3://"' do
      s.looks_like_s3_path?('foobar').should be_false
    end
  end
end
