require 'automat'

describe Automat::BeanstalkRouter do
  it { should respond_to :run }
  it { should respond_to :eb }
  it { should respond_to :r53 }
  it { should respond_to :elb }
  it { should respond_to :environment_name }
  it { should respond_to :hosted_zone_name }
end
