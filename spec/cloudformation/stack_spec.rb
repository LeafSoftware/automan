require 'automan'

describe Automan::Cloudformation::Stack do
  it { should respond_to :exists? }
  it { should respond_to :status }
  it { should respond_to :launch_complete? }
  it { should respond_to :update_complete? }
  it { should respond_to :update }
  it { should respond_to :launch }
  it { should respond_to :launch_or_update }
  it { should respond_to :parse_template_parameters }
  it { should respond_to :validate_template }

  describe '#exists?' do
    it 'is true when stack has a valid id' do
      stack = double(stack_id: 'foo')
      subject.cfn = double(stack: stack)
      expect(subject.exists?).to be_true
    end
  end
end
