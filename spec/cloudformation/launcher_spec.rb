require 'automat'

describe Automat::Cloudformation::Launcher do
  it { should respond_to :cfn }
  it { should respond_to :name }
  it { should respond_to :template }
  it { should respond_to :parameters }
  it { should respond_to :disable_rollback }
  it { should respond_to :enable_iam }
  it { should respond_to :enable_update }
  it { should respond_to :parse_template_parameters }
  it { should respond_to :run }
  it { should respond_to :launch }
  it { should respond_to :update }

  describe '#parse_template_parameters' do
    subject(:s) do
      AWS.stub!
      s = Automat::Cloudformation::Launcher.new
      s.cfn = AWS::CloudFormation.new
      s.cfn.client.stub_for :validate_template
      s
    end

    it "returns a hash" do
      s.template = File.join(File.dirname(__FILE__), 'templates', 'worker_role.json')
      result = s.parse_template_parameters
      result.class.should eq(Hash)
    end

  end

  describe '#template_handle' do
    subject(:s) do
      AWS.stub!
      s = Automat::Cloudformation::Launcher.new
      s
    end

    it "returns an s3 key if it is an s3 path" do
      s.template_handle("s3://foo/bar/baz").should be_a AWS::S3::S3Object
    end

    it "returns a string if it is a local file" do
      s.template_handle(__FILE__).should be_a String
    end
  end

  describe '#validate_parameters' do
    subject(:s) do
      AWS.stub!
      s = Automat::Cloudformation::Launcher.new
      s.parameters = {}
      s
    end

    it "raises error if no parameters were specified" do
      s.parameters = nil
      expect {
        s.validate_parameters
      }.to raise_error Automat::Cloudformation::MissingParametersError
    end

    it "raises error if the template doesn't validate" do
      Automat::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return({code: 'foo', message: 'bar'})
      expect {
        s.validate_parameters
      }.to raise_error Automat::Cloudformation::BadTemplateError
    end

    it "raises error if a required parameter isn't present" do
      Automat::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      expect {
        s.validate_parameters
      }.to raise_error Automat::Cloudformation::MissingParametersError
    end

    it "raises no error if all required parameters are present" do
      Automat::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      s.parameters = {'foo' => 'bar'}
      expect {
        s.validate_parameters
      }.not_to raise_error
    end

    it "raises no error if there are no required parameters" do
      Automat::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo', default_value: 'bar'}])
      expect {
        s.validate_parameters
      }.not_to raise_error
    end
  end
end