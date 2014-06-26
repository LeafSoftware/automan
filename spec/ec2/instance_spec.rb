require "automat"

describe Automat::Ec2::Instance do

  it { should respond_to :windows_password }
  it { should respond_to :password_data }
  it { should respond_to :decrypt_password }
  it { should respond_to :windows_name }
  it { should respond_to :show_env }

  describe '#windows_password' do
    subject(:i) do
      AWS.stub!
      i = Automat::Ec2::Instance.new
      i.logger = Logger.new('/dev/null')
      i
    end

    it "returns nil if password could not be found" do
      i.stub(:password_data).and_return nil
      i.windows_password('foo','bar').should be_nil
    end

    it "returns nil if the aws request fails" do
      i.stub(:password_data).and_raise Automat::Ec2::RequestFailedError
      i.windows_password('foo','bar').should be_nil
    end

    it "returns nil if the decrypt fails" do
      i.stub(:password_data).and_return 'foo'
      i.stub(:decrypt_password).and_return nil
      i.windows_password('foo','bar').should be_nil
    end
  end

  describe '#windows_name' do
    subject(:i) do
      AWS.stub!
      i = Automat::Ec2::Instance.new
      i.logger = Logger.new('/dev/null')
      i
    end

    it "returns nil if ip_address is nil" do
      i.windows_name(nil).should be_nil
    end

    it "returns nil if ip_address is empty" do
      i.windows_name("").should be_nil
    end

    it "converts ip_address to ip-xxxxxxxx" do
      i.windows_name('54.56.78.90').should eq 'ip-36384e5a'
    end
  end

end