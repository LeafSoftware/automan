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
end
