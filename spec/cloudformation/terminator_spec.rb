require 'automan'

describe Automan::Cloudformation::Terminator do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :terminate }
  it { is_expected.to respond_to :wait_for_completion }

  describe '#terminate' do
    subject() do
      AWS.stub!
      t = Automan::Cloudformation::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'should call stack.delete if the stack exists' do
      stack = double(exists?: true, name: 'foo')
      expect(stack).to receive :delete
      subject.terminate(stack)
    end

    it 'should not call stack.delete if the stack does not exist' do
      stack = double(exists?: false, name: 'foo')
      expect(stack).to_not receive :delete
      subject.terminate(stack)
    end
  end
end