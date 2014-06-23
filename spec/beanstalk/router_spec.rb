require 'automat'
require 'wait'

describe Automat::Beanstalk::Router do
  it { should respond_to :run }
  it { should respond_to :eb }
  it { should respond_to :r53 }
  it { should respond_to :elb }
  it { should respond_to :environment_name }
  it { should respond_to :hosted_zone_name }

  describe '#run' do
    context 'waiting' do
      subject(:r) do
        AWS.stub!
        r = Automat::Beanstalk::Router.new
        r.eb = AWS::ElasticBeanstalk::Client.new
        r.elb = AWS::ELB.new
        r.environment_name = 'foo'
        r.hosted_zone_name = 'foo.com'
        r.target           = 'www.foo.com'
        r.log_aws_calls = false
        r.logger = Logger.new('/dev/null')
        r.wait = Wait.new(delay: 0.01, rescuer: WaitRescuer.new)
        r
      end

      it "raises error if it never finds a name" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return(nil)
        expect {
          r.run
        }.to raise_error Automat::Beanstalk::ELBNameNotFoundError
      end

      it "calls #update_dns_alias if it finds a name" do
        r.stub(:elb_cname_from_beanstalk_environment).and_return('foo')
        r.should_receive(:update_dns_alias)
        r.run
      end
    end
  end
end
