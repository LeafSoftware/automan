require "automat"

describe Automat::Beanstalk::Package do
  it { should respond_to :upload_package }
  it { should respond_to :source }
  it { should respond_to :destination }
  it { should respond_to :manifest }
  it { should respond_to :version_label }
end