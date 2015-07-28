require "automan"

describe Automan::Ec2::Instance do

  it { is_expected.to respond_to :windows_password }
  it { is_expected.to respond_to :windows_name }
  it { is_expected.to respond_to :show_env }

  describe '#windows_name' do
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