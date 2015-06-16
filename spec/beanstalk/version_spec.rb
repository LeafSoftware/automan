require "automan"

describe Automan::Beanstalk::Version do

  it { should respond_to :application }
  it { should respond_to :label }
  it { should respond_to :create }
  it { should respond_to :delete }
  it { should respond_to :cull_versions }
  it { should respond_to :delete_by_label }

  describe '#exists?' do
    subject(:v) do
      AWS.stub!
      v = Automan::Beanstalk::Version.new
      v.eb = AWS::ElasticBeanstalk::Client.new
      v.application = 'foo'
      v.label = 'v4'
      v.logger = Logger.new('/dev/null')
      v
    end

    it "is true when version exists in response" do
      resp = subject.eb.stub_for :describe_application_versions
      resp.data[:application_versions] = [
        {application_name: subject.application, version_label: subject.label}
      ]
      expect(subject.exists?).to be_truthy
    end

    it "is false when version is not in response" do
      resp = subject.eb.stub_for :describe_application_versions
      resp.data[:application_versions] = [
        {application_name: '', version_label: ''}
      ]
      expect(subject.exists?).to be_falsey
    end
  end

  describe '#delete_by_label' do
    subject(:v) do
      AWS.stub!
      v = Automan::Beanstalk::Version.new
      v.logger = Logger.new('/dev/null')
      v
    end

    it 'ignores AWS::ElasticBeanstalk::Errors::SourceBundleDeletionFailure' do
      subject.eb = double()
      allow(subject.eb).to receive(:delete_application_version).and_raise(AWS::ElasticBeanstalk::Errors::SourceBundleDeletionFailure)
      expect {
        subject.delete_by_label('foo')
      }.not_to raise_error
    end

  end

end
