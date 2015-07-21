require 'spec_helper'

describe Automan::Cloudformation::Uploader do
  before(:each) do
    allow(subject).to receive(:glob_templates).and_return(%w[a b c])
  end

  it { should respond_to :template_files }
  it { should respond_to :s3_path }
  it { should respond_to :upload_templates }

  describe '#upload_templates' do
    it 'raises error if any template fails validation' do
      allow_any_instance_of(Automan::Cloudformation::Template).to receive(:valid?).and_return(false)
      expect {
        subject.upload_templates
      }.to raise_error(Automan::Cloudformation::InvalidTemplateError)
    end

    it 'uploads files if all are valid' do
      allow_any_instance_of(Automan::Cloudformation::Template).to receive(:valid?).and_return(true)
      expect(subject).to receive(:upload).exactly(3).times
      subject.upload_templates
    end
  end
end