require 'automan'
require 'wait'

describe Automan::Beanstalk::Router do
  it { should respond_to :run }
  it { should respond_to :environment_name }
  it { should respond_to :hosted_zone_name }
  it { should respond_to :hostname }

  describe '#run' do
    context 'waiting' do
      subject(:r) do
        AWS.stub!
        r = Automan::Beanstalk::Router.new
        r.eb = AWS::ElasticBeanstalk::Client.new
        r.elb = AWS::ELB.new
        r.environment_name = 'foo'
        r.hosted_zone_name = 'foo.com'
        r.hostname         = 'www.foo.com'
        r.log_aws_calls = false
        r.logger = Logger.new('/dev/null')
        r.wait = Wait.new(delay: 0.01, rescuer: WaitRescuer.new(AWS::Route53::Errors::InvalidChangeBatch))
        r
      end

      it "raises error if it never finds a name" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return(nil)
        expect {
          r.run
        }.to raise_error Wait::ResultInvalid
      end

      it "calls #update_dns_alias if it finds a name" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return('foo')
        r.should_receive(:update_dns_alias)
        r.run
      end

      it "ignores InvalidChangeBatch until last attempt" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return('foo')
        r.stub(:update_dns_alias).and_raise AWS::Route53::Errors::InvalidChangeBatch
        expect {
          r.run
        }.to raise_error AWS::Route53::Errors::InvalidChangeBatch
        r.attempts_made.should eq 5
      end

      it "ignores InvalidChangeBatch until it succeeds" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return('foo')

        @attempts = 0
        r.stub(:update_dns_alias) do
          @attempts += 1
          raise AWS::Route53::Errors::InvalidChangeBatch if @attempts < 3
        end

        expect {
          r.run
        }.not_to raise_error

        r.attempts_made.should eq 3
      end
    end
  end
end
