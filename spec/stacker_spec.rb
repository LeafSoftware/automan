require 'automat'

describe Automat::Stacker do
  it { should respond_to :cfn }
  it { should respond_to :template_file }
  it { should respond_to :parse_template_parameters }
  it { should respond_to :run }

  describe '#parse_template_parameters' do
    subject(:s) do
      AWS.stub!
      s = Automat::Stacker.new
      s.cfn = AWS::CloudFormation.new
      s.cfn.client.stub_for :validate_template
      s
    end

    it "returns a hash" do
      s.template_file = File.join(File.dirname(__FILE__), 'templates', 'worker_role.json')
      result = s.parse_template_parameters
      result.class.should eq(Hash)
    end

    it "raises MissingAttributeError if template_file is nil" do
      expect {
        s.parse_template_parameters
      }.to raise_error(Automat::MissingAttributeError)
    end
  end
end