require 'automat'

describe Automat::Cloudformation::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
  it { should respond_to :stack_exists? }
  it { should respond_to :delete_stack }

  describe '#terminate' do
    subject(:t) do
      AWS.stub!
      t = Automat::Cloudformation::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'should call #delete_stack if the stack exists' do
      t.stub(:stack_exists?).and_return(true)
      t.should_receive :delete_stack
      t.terminate
    end

    it 'should not call #delete_stack if the stack does not exist' do
      t.stub(:stack_exists?).and_return(false)
      t.should_not_receive :delete_stack
      t.terminate
    end
  end
end