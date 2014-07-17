require 'automat'

describe Automat::Cloudformation::Uploader do
  subject(:u) do
    AWS.stub!
    u = Automat::Cloudformation::Uploader.new
    u.logger = Logger.new('/dev/null')
    u.stub(:templates).and_return(%w[a b c])
    u
  end

  it { should respond_to :template_files }
  it { should respond_to :s3_path }
  it { should respond_to :all_templates_valid? }
  it { should respond_to :upload_templates }

  describe '#all_templates_valid?' do
    it "raises error if there are no templates" do
      u.stub(:templates).and_return([])
      expect {
        u.all_templates_valid?
      }.to raise_error Automat::Cloudformation::NoTemplatesError
    end

    it 'returns true if templates are valid' do
      u.should_receive(:template_valid?).exactly(3).times.and_return(true)
      u.all_templates_valid?.should be_true
    end

    it 'returns false if any templates are invalid' do
      u.stub(:template_valid?).and_return(false)
      u.all_templates_valid?.should be_false
    end
  end

  describe '#upload_templates' do
    it 'raises error if any template fails validation' do
      u.stub(:all_templates_valid?).and_return(false)
      expect {
        u.upload_templates
      }.to raise_error(Automat::Cloudformation::InvalidTemplateError)
    end

    it 'uploads files if all are valid' do
      u.stub(:all_templates_valid?).and_return(true)
      u.should_receive(:upload_file).exactly(3).times
      u.upload_templates
    end
  end
end