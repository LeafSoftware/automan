require 'automan/mixins/aws_caller'

describe Automan::Mixins::AwsCaller do
  subject() { (Class.new { include Automan::Mixins::AwsCaller }).new }

  services = [
    :s3, :cfn, :as, :eb, :r53, :elb, :rds, :ec2
  ]

  services.each do |svc|
    it { is_expected.to respond_to svc }
  end

  it { is_expected.to respond_to :parse_s3_path }

  describe '#parse_s3_path' do
    it "parses s3 path into bucket and key" do
      bucket, key = subject.parse_s3_path('s3://foo/bar/baz')
      expect(bucket).to eq('foo')
      expect(key).to eq ('bar/baz')
    end

    it "raises error if it doesn't start with s3://" do
      expect {
        subject.parse_s3_path 'foo'
      }.to raise_error ArgumentError
    end
  end

  describe '#looks_like_s3_path?' do
    it 'returns true if it begins with "s3://"' do
      expect(subject.looks_like_s3_path?('s3://foo')).to be_truthy
    end

    it 'returns false if it does not start with "s3://"' do
      expect(subject.looks_like_s3_path?('foobar')).to be_falsey
    end
  end
end
