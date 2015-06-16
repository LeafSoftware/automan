require 'automan'

describe Automan::Beanstalk::Uploader do
  subject(:u) do
    AWS.stub!
    u = Automan::Beanstalk::Uploader.new
    u.logger = Logger.new('/dev/null')
    u.template_files = 'foo'
    allow(u).to receive(:config_templates).and_return(['foo'])
    u
  end

  it { should respond_to :template_files }
  it { should respond_to :s3_path }
  it { should respond_to :upload_config_templates }
  it { should respond_to :config_templates_valid? }

  describe '#config_templates_valid?' do

    it 'raises error if config templates do not exist' do
      allow(subject).to receive(:config_templates).and_return([])
      expect {
        subject.config_templates_valid?
      }.to raise_error(Automan::Beanstalk::NoConfigurationTemplatesError)
    end

    it 'returns true if config templates are valid json' do
      allow(subject).to receive(:read_config_template).and_return('[{}]')
      expect(subject.config_templates_valid?).to be_truthy
    end

    it 'returns false if config templates are invalid json' do
      allow(subject).to receive(:read_config_template).and_return('@#$%#')
      expect(subject.config_templates_valid?).to be_falsey
    end
  end

  describe '#upload_config_templates' do
    it 'raises error if any config template fails validation' do
      allow(subject).to receive(:config_templates_valid?).and_return(false)
      expect {
        subject.upload_config_templates
      }.to raise_error(Automan::Beanstalk::InvalidConfigurationTemplateError)
    end

    it 'uploads files if they are valid' do
      allow(subject).to receive(:config_templates).and_return(%w[a b c])
      allow(subject).to receive(:config_templates_valid?).and_return(true)
      expect(subject).to receive(:upload_file).exactly(3).times
      subject.upload_config_templates
    end
  end
end