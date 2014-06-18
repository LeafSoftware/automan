require 'automat'

describe Automat::Cloudformation::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
end