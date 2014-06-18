require 'automat'

describe Automat::Cloudformation::Replacer do
  it { should respond_to :name }
  it { should respond_to :replace_instances }
end