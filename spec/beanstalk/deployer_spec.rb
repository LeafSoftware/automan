require "automan"

describe Automan::Beanstalk::Deployer do

  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :version_label }
  it { is_expected.to respond_to :package }
  it { is_expected.to respond_to :environment }
  it { is_expected.to respond_to :manifest }
  it { is_expected.to respond_to :read_manifest }
  it { is_expected.to respond_to :manifest_exists? }
  it { is_expected.to respond_to :package_exists? }
  it { is_expected.to respond_to :environment_status }
  it { is_expected.to respond_to :configuration_template }
  it { is_expected.to respond_to :deploy }
  it { is_expected.to respond_to :update_environment }
  it { is_expected.to respond_to :create_environment }

  # Constraint: Must be from 4 to 23 characters in length.
  # The name can contain only letters, numbers, and hyphens.
  # It cannot start or end with a hyphen.
  describe '#eb_environment_name' do
    subject() { Automan::Beanstalk::Deployer.new }

    it "is at least 4 characters" do
      subject.name = "a"
      subject.environment = "a"
      expect(subject.eb_environment_name.length).to be >= 4
    end

    it "is no more than 23 characters" do
      subject.name = "a" * 23
      subject.environment = "dev"
      expect(subject.eb_environment_name.length).to be <= 23
    end

    it "contains only letters, numbers, and hyphens" do
      subject.name = '@#$%^foo_bar!$%&&E.'
      subject.environment = 'prod.baz'
      expect(subject.eb_environment_name).to match(/[a-z0-9-]+/)
    end

    it "cannot start or end with a hyphen" do
      subject.name = '--foo'
      subject.environment = 'bar--'
      expect(subject.eb_environment_name).to match(/^[^-].*[^-]$/)
    end

    it "is still at least 4 characters even after removing restricted strings" do
      subject.name = '--f'
      subject.environment = '-'
      expect(subject.eb_environment_name.length).to be >= 4
    end
  end

  describe '#read_manifest' do
    subject() do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'raises MissingManifestError if the manifest is missing' do
      expect(subject).to receive(:manifest_exists?).and_return(false)
      expect {
        subject.read_manifest
      }.to raise_error(Automan::Beanstalk::MissingManifestError)
    end

    it 'sets version_label and package properly' do
      allow(subject).to receive(:manifest_exists?).and_return(true)
      allow(subject).to receive(:s3_read).and_return('{"version_label": "foo", "package": "bar"}')
      subject.read_manifest
      expect(subject.version_label).to eq('foo')
      expect(subject.package).to eq('bar')
    end
  end

  describe '#deploy' do
    subject() do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'raises MissingPackageError if the package does not exist' do
      allow(subject).to receive(:package_exists?).and_return(false)
      expect {
        subject.deploy
      }.to raise_error(Automan::Beanstalk::MissingPackageFileError)
    end

    it 'makes sure the application version and environment exists' do
      allow(subject).to receive(:package_exists?).and_return(true)
      expect(subject).to receive(:ensure_version_exists)
      expect(subject).to receive(:create_or_update_environment)
      subject.deploy
    end
  end

  describe '#ensure_version_exists' do
    subject() do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      d
    end

    it 'creates version if it does not exist' do
      version = double()
      allow(version).to receive(:exists?).and_return(false)
      expect(version).to receive(:create)
      allow(subject).to receive(:get_version).and_return(version)
      subject.ensure_version_exists
    end

    it 'does not create version if it exists' do
      version = double()
      allow(version).to receive(:exists?).and_return(true)
      expect(version).to_not receive(:create)
      allow(subject).to receive(:get_version).and_return(version)
      subject.ensure_version_exists
    end
  end

  describe '#create_or_update_environment' do
    subject() do
      AWS.stub!
      d = Automan::Beanstalk::Deployer.new
      d.logger = Logger.new('/dev/null')
      allow(d).to receive(:ensure_version_exists)
      d
    end

    [nil, 'Terminated'].each do |state|
      it "creates environment if state is #{state.nil? ? 'nil' : state}" do
        allow(subject).to receive(:environment_status).and_return(state)
        expect(subject).to receive(:create_environment)
        subject.create_or_update_environment
      end
    end

    ['Ready'].each do |state|
      it "updates environment if state is #{state.nil? ? 'nil' : state}" do
        allow(subject).to receive(:environment_status).and_return(state)
        expect(subject).to receive(:update_environment)
        subject.create_or_update_environment
      end
    end

    it 'raises error if environment state is anything else' do
      allow(subject).to receive(:environment_status).and_return('foo')
      expect {
        subject.create_or_update_environment
      }.to raise_error(Automan::Beanstalk::InvalidEnvironmentStatusError)
    end
  end

end

