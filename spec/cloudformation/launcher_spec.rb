require 'automan'

describe Automan::Cloudformation::Launcher do
  it { should respond_to :name }
  it { should respond_to :template }
  it { should respond_to :parameters }
  it { should respond_to :disable_rollback }
  it { should respond_to :enable_iam }
  it { should respond_to :enable_update }
  it { should respond_to :parse_template_parameters }
  it { should respond_to :launch_or_update }
  it { should respond_to :launch }
  it { should respond_to :update }
  it { should respond_to :read_manifest }
  it { should respond_to :wait_for_completion }
  it { should respond_to :stack_launch_complete? }
  it { should respond_to :stack_update_complete? }

  describe '#read_manifest' do
    subject() do
      AWS.stub!
      Automan::Cloudformation::Launcher.new
    end

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

  describe '#parse_template_parameters' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.cfn = AWS::CloudFormation.new
      s.cfn.client.stub_for :validate_template
      s
    end

    it "returns a hash" do
      subject.template = File.join(File.dirname(__FILE__), 'templates', 'worker_role.json')
      result = subject.parse_template_parameters
      expect(result.class).to eq(Hash)
    end

  end

  describe '#template_handle' do
    subject() do
      AWS.stub!
      Automan::Cloudformation::Launcher.new
    end

    it "returns an s3 key if it is an s3 path" do
      expect(subject.template_handle("s3://foo/bar/baz")).to be_a AWS::S3::S3Object
    end

    it "returns a string if it is a local file" do
      expect(subject.template_handle(__FILE__)).to be_a String
    end
  end

  describe '#validate_parameters' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s.parameters = {}
      s
    end

    it "raises error if no parameters were specified" do
      subject.parameters = nil
      expect {
        subject.validate_parameters
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises error if the template doesn't validate" do
      allow(subject).to receive(:parse_template_parameters).and_return({code: 'foo', message: 'bar'})
      expect {
        subject.validate_parameters
      }.to raise_error Automan::Cloudformation::BadTemplateError
    end

    it "raises error if a required parameter isn't present" do
      allow(subject).to receive(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      expect {
        subject.validate_parameters
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises no error if all required parameters are present" do
      allow(subject).to receive(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      subject.parameters = {'foo' => 'bar'}
      expect {
        subject.validate_parameters
      }.not_to raise_error
    end

    it "raises no error if there are no required parameters" do
      allow(subject).to receive(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo', default_value: 'bar'}])
      expect {
        subject.validate_parameters
      }.not_to raise_error
    end
  end

  describe '#update' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      allow(s).to receive(:template_handle).and_return('foo')
      s
    end

    it "ignores AWS::CloudFormation::Errors::ValidationError when no updates are to be performed" do
      allow(subject).to receive(:update_stack).and_raise AWS::CloudFormation::Errors::ValidationError.new("No updates are to be performed.")
      expect {
        subject.update
      }.to_not raise_error
    end

    it 're-raises any other ValidationError' do
      allow(subject).to receive(:update_stack).and_raise AWS::CloudFormation::Errors::ValidationError.new("foo")
      expect {
        subject.update
      }.to raise_error AWS::CloudFormation::Errors::ValidationError
    end
  end

  describe '#launch_or_update' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      allow(s).to receive(:validate_parameters)
      s
    end

    it "launches a new stack if it does not exist" do
      allow(subject).to receive(:stack_exists?).and_return(false)
      expect(subject).to receive(:launch)
      subject.launch_or_update
    end

    it "updates an existing stack if update is enabled" do
      allow(subject).to receive(:stack_exists?).and_return(true)
      allow(subject).to receive(:enable_update).and_return(true)
      expect(subject).to receive(:update)
      subject.launch_or_update
    end

    it "raises an error when updating an existing stack w/o update enabled" do
      allow(subject).to receive(:stack_exists?).and_return(true)
      allow(subject).to receive(:enable_update).and_return(false)
      expect {
        subject.launch_or_update
      }.to raise_error Automan::Cloudformation::StackExistsError
    end
  end

  describe '#stack_launch_complete?' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true when the stack completes' do
      allow(subject).to receive(:stack_status).and_return('CREATE_COMPLETE')
      expect(subject.stack_launch_complete?).to be_truthy
    end

    it 'raises an error when the stack fails' do
      allow(subject).to receive(:stack_status).and_return('CREATE_FAILED')
      expect {
        subject.stack_launch_complete?
      }.to raise_error Automan::Cloudformation::StackCreationError
    end

    rollback_states = %w[ROLLBACK_COMPLETE ROLLBACK_FAILED ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack goes into #{state} state" do
        allow(subject).to receive(:stack_status).and_return(state)
        expect {
          subject.stack_launch_complete?
        }.to raise_error Automan::Cloudformation::StackCreationError
      end
    end

    it 'returns false for any other state' do
      allow(subject).to receive(:stack_status).and_return('foo')
      expect(subject.stack_launch_complete?).to be_falsey
    end
  end

  describe '#stack_update_complete?' do
    subject() do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true when the stack completes' do
      allow(subject).to receive(:stack_status).and_return('UPDATE_COMPLETE')
      expect(subject.stack_update_complete?).to be_truthy
    end

    rollback_states = %w[UPDATE_ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack enters #{state} state" do
        allow(subject).to receive(:stack_status).and_return(state)
        expect {
          subject.stack_update_complete?
        }.to raise_error Automan::Cloudformation::StackUpdateError
      end
    end

    it 'returns false for any other state' do
      allow(subject).to receive(:stack_status).and_return('foo')
      expect(subject.stack_update_complete?).to be_falsey
    end
  end
end