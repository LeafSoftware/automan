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
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s
    end

    it 'raises MissingManifestError if manifest does not exist' do
      s.stub(:manifest_exists?).and_return(false)
      expect {
        s.read_manifest
      }.to raise_error(Automan::Cloudformation::MissingManifestError)
    end

    it 'merges manifest contents into parameters hash' do
      s.stub(:manifest_exists?).and_return(true)
      s.stub(:s3_read).and_return('{"foo": "bar", "big": "poppa"}')
      s.parameters = {'foo'=> 'baz', 'fo'=> 'shizzle'}
      s.read_manifest
      s.parameters.should eq({'foo' => 'bar', 'fo' => 'shizzle', 'big' => 'poppa'})
    end
  end

  describe '#parse_template_parameters' do
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
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
      s = Automan::Cloudformation::Launcher.new
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
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s.parameters = {}
      s
    end

    it "raises error if no parameters were specified" do
      s.parameters = nil
      expect {
        s.validate_parameters
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises error if the template doesn't validate" do
      Automan::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return({code: 'foo', message: 'bar'})
      expect {
        s.validate_parameters
      }.to raise_error Automan::Cloudformation::BadTemplateError
    end

    it "raises error if a required parameter isn't present" do
      Automan::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      expect {
        s.validate_parameters
      }.to raise_error Automan::Cloudformation::MissingParametersError
    end

    it "raises no error if all required parameters are present" do
      Automan::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo'}])
      s.parameters = {'foo' => 'bar'}
      expect {
        s.validate_parameters
      }.not_to raise_error
    end

    it "raises no error if there are no required parameters" do
      Automan::Cloudformation::Launcher.any_instance.stub(:parse_template_parameters).and_return(parameters: [{parameter_key: 'foo', default_value: 'bar'}])
      expect {
        s.validate_parameters
      }.not_to raise_error
    end
  end

  describe '#update' do
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s.stub(:template_handle).and_return('foo')
      s
    end

    it "ignores AWS::CloudFormation::Errors::ValidationError when no updates are to be performed" do
      s.stub(:update_stack).and_raise AWS::CloudFormation::Errors::ValidationError.new("No updates are to be performed.")
      expect {
        s.update
      }.to_not raise_error
    end

    it 're-raises any other ValidationError' do
      s.stub(:update_stack).and_raise AWS::CloudFormation::Errors::ValidationError.new("foo")
      expect {
        s.update
      }.to raise_error AWS::CloudFormation::Errors::ValidationError
    end
  end

  describe '#launch_or_update' do
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s.stub(:validate_parameters)
      s
    end

    it "launches a new stack if it does not exist" do
      s.stub(:stack_exists?).and_return(false)
      s.should_receive(:launch)
      s.launch_or_update
    end

    it "updates an existing stack if update is enabled" do
      s.stub(:stack_exists?).and_return(true)
      s.stub(:enable_update).and_return(true)
      s.should_receive(:update)
      s.launch_or_update
    end

    it "raises an error when updating an existing stack w/o update enabled" do
      s.stub(:stack_exists?).and_return(true)
      s.stub(:enable_update).and_return(false)
      expect {
        s.launch_or_update
      }.to raise_error Automan::Cloudformation::StackExistsError
    end
  end

  describe '#stack_launch_complete?' do
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true when the stack completes' do
      s.stub(:stack_status).and_return('CREATE_COMPLETE')
      s.stack_launch_complete?.should be_true
    end

    it 'raises an error when the stack fails' do
      s.stub(:stack_status).and_return('CREATE_FAILED')
      expect {
        s.stack_launch_complete?
      }.to raise_error Automan::Cloudformation::StackCreationError
    end

    rollback_states = %w[ROLLBACK_COMPLETE ROLLBACK_FAILED ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack goes into #{state} state" do
        s.stub(:stack_status).and_return(state)
        expect {
          s.stack_launch_complete?
        }.to raise_error Automan::Cloudformation::StackCreationError
      end
    end

    it 'returns false for any other state' do
      s.stub(:stack_status).and_return('foo')
      s.stack_launch_complete?.should be_false
    end
  end

  describe '#stack_update_complete?' do
    subject(:s) do
      AWS.stub!
      s = Automan::Cloudformation::Launcher.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true when the stack completes' do
      s.stub(:stack_status).and_return('UPDATE_COMPLETE')
      s.stack_update_complete?.should be_true
    end

    rollback_states = %w[UPDATE_ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack enters #{state} state" do
        s.stub(:stack_status).and_return(state)
        expect {
          s.stack_update_complete?
        }.to raise_error Automan::Cloudformation::StackUpdateError
      end
    end

    it 'returns false for any other state' do
      s.stub(:stack_status).and_return('foo')
      s.stack_update_complete?.should be_false
    end
  end
end