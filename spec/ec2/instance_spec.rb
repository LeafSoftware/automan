require "automan"

describe Automan::Ec2::Instance do

  it { is_expected.to respond_to :windows_password }
  it { is_expected.to respond_to :password_data }
  it { is_expected.to respond_to :decrypt_password }
  it { is_expected.to respond_to :windows_name }
  it { is_expected.to respond_to :show_env }

  describe '#windows_password' do
    subject() do
      AWS.stub!
      i = Automan::Ec2::Instance.new
      i.logger = Logger.new('/dev/null')
      i
    end

    it "returns nil if password could not be found" do
      allow(subject).to receive(:password_data).and_return nil
      expect(subject.windows_password('foo','bar')).to be_nil
    end

    it "returns nil if the aws request fails" do
      allow(subject).to receive(:password_data).and_raise Automan::Ec2::RequestFailedError
      expect(subject.windows_password('foo','bar')).to be_nil
    end

    it "returns nil if the decrypt fails" do
      allow(subject).to receive(:password_data).and_return 'foo'
      allow(subject).to receive(:decrypt_password).and_return nil
      expect(subject.windows_password('foo','bar')).to be_nil
    end
  end

  describe '#windows_name' do
    subject() do
      AWS.stub!
      i = Automan::Ec2::Instance.new
      i.logger = Logger.new('/dev/null')
      i
    end

    it "returns nil if ip_address is nil" do
      expect(subject.windows_name(nil)).to be_nil
    end

    it "returns nil if ip_address is empty" do
      expect(subject.windows_name("")).to be_nil
    end

    it "converts ip_address to ip-xxxxxxxx" do
      expect(subject.windows_name('54.56.78.90')).to eq 'ip-36384e5a'
    end
  end

end