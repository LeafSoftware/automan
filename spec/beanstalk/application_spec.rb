require "automat"

describe Automat::Beanstalk::Application do
  it { should respond_to :name }
  it { should respond_to :create }
  it { should respond_to :delete }
end