require "automan"

describe Automan::Beanstalk::Deployer do

  it { should respond_to :name }
  it { should respond_to :version_label }
  it { should respond_to :package }
  it { should respond_to :environment }
  it { should respond_to :manifest }
  it { should respond_to :read_manifest }
  it { should respond_to :manifest_exists? }
  it { should respond_to :package_exists? }
  it { should respond_to :environment_status }
  it { should respond_to :configuration_template }
  it { should respond_to :deploy }
  it { should respond_to :update_environment }
  it { should respond_to :create_environment }

  # Constraint: Must be from 4 to 23 characters in length.
  # The name can contain only letters, numbers, and hyphens.
  # It cannot start or end with a hyphen.
  describe '#eb_environment_name' do
    subject(:bd) { Automan::Beanstalk::Deployer.new }

    it "is at least 4 characters" do
      bd.name = "a"
      bd.environment = "a"
      bd.eb_environment_name.length.should be >= 4
    end

    it "is no more than 23 characters" do
      bd.name = "a" * 23
      bd.environment = "dev"
      bd.eb_environment_name.length.should be <= 23
    end

    it "contains only letters, numbers, and hyphens" do
      bd.name = '@#$%^foo_bar!$%&&E.'
      bd.environment = 'prod.baz'
      bd.eb_environment_name.should match(/[a-z0-9-]+/)
    end

    it "cannot start or end with a hyphen" do
      bd.name = '--foo'
      bd.environment = 'bar--'
      bd.eb_environment_name.should match(/^[^-].*[^-]$/)
    end

    it "is still at least 4 characters even after removing restricted strings" do
      bd.name = '--f'
      bd.environment = '-'
      bd.eb_environment_name.length.should be >= 4
    end
  end

  describe '#read_manifest' do
    subject(:d) do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'raises MissingManifestError if the manifest is missing' do
      d.stub(:manifest_exists?).and_return(false)
      expect {
        d.read_manifest
      }.to raise_error(Automan::Beanstalk::MissingManifestError)
    end

    it 'sets version_label and package properly' do
      d.stub(:manifest_exists?).and_return(true)
      d.stub(:s3_read).and_return('{"version_label": "foo", "package": "bar"}')
      d.read_manifest
      d.version_label.should eq('foo')
      d.package.should eq('bar')
    end
  end

  describe '#deploy' do
    subject(:d) do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'raises MissingPackageError if the package does not exist' do
      d.stub(:package_exists?).and_return(false)
      expect {
        d.deploy
      }.to raise_error(Automan::Beanstalk::MissingPackageFileError)
    end

    it 'makes sure the application version and environment exists' do
      d.stub(:package_exists?).and_return(true)
      d.should_receive(:ensure_version_exists)
      d.should_receive(:create_or_update_environment)
      d.deploy
    end
  end

  describe '#ensure_version_exists' do
    subject(:d) do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'creates version if it does not exist' do
      version = double(:version)
      version.stub(:exists?).and_return(false)
      version.should_receive(:create)
      d.stub(:get_version).and_return(version)
      d.ensure_version_exists
    end

    it 'does not create version if it exists' do
      version = double(:version)
      version.stub(:exists?).and_return(true)
      version.should_not_receive(:create)
      d.stub(:get_version).and_return(version)
      d.ensure_version_exists
    end
  end

  describe '#create_or_update_environment' do
    subject(:d) do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d.stub(:ensure_version_exists)
      d
    end

    [nil, 'Terminated'].each do |state|
      it "creates environment if state is #{state.nil? ? 'nil' : state}" do
        d.stub(:environment_status).and_return(state)
        d.should_receive(:create_environment)
        d.create_or_update_environment
      end
    end

    ['Ready'].each do |state|
      it "updates environment if state is #{state.nil? ? 'nil' : state}" do
        d.stub(:environment_status).and_return(state)
        d.should_receive(:update_environment)
        d.create_or_update_environment
      end
    end

    it 'raises error if environment state is anything else' do
      d.stub(:environment_status).and_return('foo')
      expect {
        d.create_or_update_environment
      }.to raise_error(Automan::Beanstalk::InvalidEnvironmentStatusError)
    end
  end

end

