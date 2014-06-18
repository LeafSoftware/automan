require 'automat'

describe Automat::Beanstalk::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
end