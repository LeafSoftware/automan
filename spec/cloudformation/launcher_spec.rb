require 'spec_helper'

describe Automan::Cloudformation::Launcher do
  it { should respond_to :name }
  it { should respond_to :template }
  it { should respond_to :parameters }
  it { should respond_to :disable_rollback }
  it { should respond_to :enable_iam }
  it { should respond_to :enable_update }
  it { should respond_to :launch_or_update }
  it { should respond_to :launch }
  it { should respond_to :update }
  it { should respond_to :read_manifest }
  it { should respond_to :wait_for_completion }

  describe '#read_manifest' do
    it 'raises MissingManifestError if manifest does not exist' do
      allow(subject).to receive(:manifest_exists?).and_return(false)
      expect {
        subject.read_manifest
      }.to raise_error(Automan::Cloudformation::MissingManifestError)
    end

    it 'merges manifest contents into parameters hash' do
      allow(subject).to receive(:manifest_exists?).and_return(true)
      allow(subject).to receive(:s3_read).and_return('{"foo": "bar", "big": "poppa"}')
      subject.parameters = {'foo'=> 'baz', 'fo'=> 'shizzle'}
      subject.read_manifest
      expect(subject.parameters).to eq({'foo' => 'bar', 'fo' => 'shizzle', 'big' => 'poppa'})
    end
  end

  describe '#validate_parameters' do
    before(:each) do
      subject.parameters = {}
    end

    let(:template) do
      double(
        valid?: true,
        capabilities: [],
        required_parameters: [ double(parameter_key: 'foo') ]
      )
    end

    it "raises error if no parameters were specified" do
      subject.parameters = nil
      expect {
        subject.validate_parameters(template)
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises error if the template doesn't validate" do
      allow(template).to receive(:valid?).and_return(false)
      expect {
        subject.validate_parameters(template)
      }.to raise_error Automan::Cloudformation::BadTemplateError
    end

    it "raises error if a required parameter isn't present" do
      expect {
        subject.validate_parameters(template)
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises no error if all required parameters are present" do
      subject.parameters = {'foo' => 'bar'}
      expect {
        subject.validate_parameters(template)
      }.not_to raise_error
    end

    it "raises no error if there are no required parameters" do
      allow(template).to receive(:required_parameters).and_return([])
      expect {
        subject.validate_parameters(template)
      }.not_to raise_error
    end
  end

  describe '#update' do
    let(:stack) { double() }

    it "ignores Aws::CloudFormation::Errors::ValidationError when no updates are to be performed" do
      allow(stack).to receive(:update).and_raise Aws::CloudFormation::Errors::ValidationError.new(nil, "No updates are to be performed.")
      expect {
        subject.update(stack, '')
      }.to_not raise_error
    end

    it 're-raises any other ValidationError' do
      allow(stack).to receive(:update).and_raise Aws::CloudFormation::Errors::ValidationError.new(nil, "foo")
      expect {
        subject.update(stack, '')
      }.to raise_error Aws::CloudFormation::Errors::ValidationError
    end
  end

  describe '#launch_or_update' do
    before(:each) do
      allow(subject).to receive(:validate_parameters)
    end

    let(:stack)    { double(exists?: true) }
    let(:template) { double(template_contents: '') }

    it "launches a new stack if it does not exist" do
      allow(stack).to receive(:exists?).and_return(false)
      expect(subject).to receive(:launch)
      subject.launch_or_update(stack, template)
    end

    it "updates an existing stack if update is enabled" do
      allow(subject).to receive(:enable_update).and_return(true)
      expect(subject).to receive(:update)
      subject.launch_or_update(stack, template)
    end

    it "raises an error when updating an existing stack w/o update enabled" do
      allow(subject).to receive(:enable_update).and_return(false)
      expect {
        subject.launch_or_update(stack, template)
      }.to raise_error Automan::Cloudformation::StackExistsError
    end
  end

end