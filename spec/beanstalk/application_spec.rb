require 'spec_helper'

describe Automan::Beanstalk::Application do
  before(:each) do
    subject.name = 'foo'
  end

  let(:successful_resp) { double(successful?: true) }
  let(:failed_resp)     { double(successful?: false, error: 'foo') }

  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :exists? }
  it { is_expected.to respond_to :create }
  it { is_expected.to respond_to :delete }
  it { is_expected.to respond_to :versions }
  it { is_expected.to respond_to :create_version }
  it { is_expected.to respond_to :delete_version }
  it { is_expected.to respond_to :cull_versions }

  describe '#exists?' do
    it 'is true when application appears in response' do
      subject.eb.stub_responses(:describe_applications, applications:[{application_name: 'foo'}])
      expect(subject.exists?).to be_truthy
    end

    it 'is false when application does not appear in response' do
      subject.eb.stub_responses(:describe_applications, applications:[])
      expect(subject.exists?).to be_falsey
    end
  end

  describe '#create' do
    it "raises exception if create fails" do
      subject.eb = double(create_application: failed_resp)
      expect {
        subject.create
      }.to raise_error(Automan::Beanstalk::RequestFailedError)
    end
  end

  describe '#delete' do
    it "raises exception if delete fails" do
      subject.eb = double(delete_application: failed_resp)
      expect {
        subject.delete
      }.to raise_error(Automan::Beanstalk::RequestFailedError)
    end
  end
end