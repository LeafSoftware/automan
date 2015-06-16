require 'automan'

describe Automan::Cloudformation::Uploader do
  subject() do
    AWS.stub!
    u = Automan::Cloudformation::Uploader.new
    u.logger = Logger.new('/dev/null')
    allow(u).to receive(:templates).and_return(%w[a b c])
    u
  end

  it { should respond_to :template_files }
  it { should respond_to :s3_path }
  it { should respond_to :all_templates_valid? }
  it { should respond_to :upload_templates }

  describe '#all_templates_valid?' do
    it "raises error if there are no templates" do
      allow(subject).to receive(:templates).and_return([])
      expect {
        subject.all_templates_valid?
      }.to raise_error Automan::Cloudformation::NoTemplatesError
    end

    it 'returns true if templates are valid' do
      expect(subject).to receive(:template_valid?).exactly(3).times.and_return(true)
      expect(subject.all_templates_valid?).to be_truthy
    end

    it 'returns false if any templates are invalid' do
      allow(subject).to receive(:template_valid?).and_return(false)
      expect(subject.all_templates_valid?).to be_falsey
    end
  end

  describe '#upload_templates' do
    it 'raises error if any template fails validation' do
      allow(subject).to receive(:all_templates_valid?).and_return(false)
      expect {
        subject.upload_templates
      }.to raise_error(Automan::Cloudformation::InvalidTemplateError)
    end

    it 'uploads files if all are valid' do
      allow(subject).to receive(:all_templates_valid?).and_return(true)
      expect(subject).to receive(:upload_file).exactly(3).times
      subject.upload_templates
    end
  end
end