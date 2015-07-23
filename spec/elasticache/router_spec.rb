require 'spec_helper'

describe Automan::ElastiCache::Router do
  it { is_expected.to respond_to :run }
  it { is_expected.to respond_to :environment }
  it { is_expected.to respond_to :hosted_zone_name }
  it { is_expected.to respond_to :redis_host }

  describe '#run' do
    before(:each) do
      subject.environment = 'foo'
      subject.hosted_zone_name = 'foo.com'
      subject.redis_host = 'redis.foo.com'
    end

    it "raises error if it never finds a name" do
      allow(subject).to receive(:node_name_from_elasticache_environment).and_return(nil)
      expect {
        subject.run
      }.not_to raise_error
    end

  end
end
