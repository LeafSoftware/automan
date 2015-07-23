require 'spec_helper'
require 'wait'

describe Automan::Beanstalk::Router do
  it { is_expected.to respond_to :run }
  it { is_expected.to respond_to :environment_name }
  it { is_expected.to respond_to :hosted_zone_name }
  it { is_expected.to respond_to :hostname }

  describe '#run' do
    context 'waiting' do
      subject() do
        AWS.stub!
        r = Automan::Beanstalk::Router.new
        r.eb = AWS::ElasticBeanstalk::Client.new
        r.elb = AWS::ELB.new
        r.environment_name = 'foo'
        r.hosted_zone_name = 'foo.com'
        r.hostname         = 'www.foo.com'
        r.logger = Logger.new('/dev/null')
        r.wait = Wait.new(delay: 0.01, rescuer: WaitRescuer.new(AWS::Route53::Errors::InvalidChangeBatch))
        r
      end

      it "raises error if it never finds a name" do
        allow(subject).to receive(:elb_cname_from_beanstalk_environment).and_return(nil)
        expect {
          subject.run
        }.to raise_error Wait::ResultInvalid
      end

      it "calls #update_dns_alias if it finds a name" do
        allow(subject).to receive(:elb_cname_from_beanstalk_environment).and_return('foo')
        expect(subject).to receive(:update_dns_alias)
        subject.run
      end

      it "ignores InvalidChangeBatch until last attempt" do
        allow(subject).to receive(:elb_cname_from_beanstalk_environment).and_return('foo')
        allow(subject).to receive(:update_dns_alias).and_raise AWS::Route53::Errors::InvalidChangeBatch
        expect {
          subject.run
        }.to raise_error AWS::Route53::Errors::InvalidChangeBatch
        expect(subject.attempts_made).to eq 5
      end

      it "ignores InvalidChangeBatch until it succeeds" do
        allow(subject).to receive(:elb_cname_from_beanstalk_environment).and_return('foo')

        @attempts = 0
        allow(subject).to receive(:update_dns_alias) do
          @attempts += 1
          raise AWS::Route53::Errors::InvalidChangeBatch if @attempts < 3
        end

        expect {
          subject.run
        }.not_to raise_error

        expect(subject.attempts_made).to eq 3
      end
    end
  end
end
