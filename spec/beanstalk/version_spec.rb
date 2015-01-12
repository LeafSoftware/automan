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
      resp = v.eb.stub_for :describe_application_versions
      resp.data[:application_versions] = [
        {application_name: v.application, version_label: v.label}
      ]
      v.exists?.should be_true
    end

    it "is false when version is not in response" do
      resp = v.eb.stub_for :describe_application_versions
      resp.data[:application_versions] = [
        {application_name: '', version_label: ''}
      ]
      v.exists?.should be_false
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
      eb = double(:eb)
      eb.stub(:delete_application_version).and_raise(AWS::ElasticBeanstalk::Errors::SourceBundleDeletionFailure)
      v.eb = eb
      expect {
        v.delete_by_label('foo')
      }.not_to raise_error
    end

  end

end
