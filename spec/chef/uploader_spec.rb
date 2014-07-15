require "automat"

describe Automat::Chef::Uploader do
  it { should respond_to :repopath }
  it { should respond_to :s3path }
  it { should respond_to :chefver }
  it { should respond_to :tempdir }
  it { should respond_to :upload }
end