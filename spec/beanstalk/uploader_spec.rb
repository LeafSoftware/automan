require 'automan'

describe Automan::Beanstalk::Uploader do
  subject(:u) do
    AWS.stub!
    u = Automan::Beanstalk::Uploader.new
    u.logger = Logger.new('/dev/null')
    u.template_files = 'foo'
    u.stub(:config_templates).and_return(['foo'])
    u
  end

  it { should respond_to :template_files }
  it { should respond_to :s3_path }
  it { should respond_to :upload_config_templates }
  it { should respond_to :config_templates_valid? }

  describe '#config_templates_valid?' do

    it 'raises error if config templates do not exist' do
      u.stub(:config_templates).and_return([])
      expect {
        u.config_templates_valid?
      }.to raise_error(Automan::Beanstalk::NoConfigurationTemplatesError)
    end

    it 'returns true if config templates are valid json' do
      u.stub(:read_config_template).and_return('[{}]')
      u.config_templates_valid?.should be_true
    end

    it 'returns false if config templates are invalid json' do
      u.stub(:read_config_template).and_return('@#$%#')
      u.config_templates_valid?.should be_false
    end
  end

  describe '#upload_config_templates' do
    it 'raises error if any config template fails validation' do
      u.stub(:config_templates_valid?).and_return(false)
      expect {
        u.upload_config_templates
      }.to raise_error(Automan::Beanstalk::InvalidConfigurationTemplateError)
    end

    it 'uploads files if they are valid' do
      u.stub(:config_templates).and_return(%w[a b c])
      u.stub(:config_templates_valid?).and_return(true)
      u.should_receive(:upload_file).exactly(3).times
      u.upload_config_templates
    end
  end
end