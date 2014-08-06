require 'automan'

describe Automan::Cloudformation::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
  it { should respond_to :stack_exists? }
  it { should respond_to :stack_deleted? }
  it { should respond_to :delete_stack }
  it { should respond_to :wait_for_completion }

  describe '#terminate' do
    subject(:t) do
      AWS.stub!
      t = Automan::Cloudformation::Terminator.new
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

  describe '#stack_deleted?' do
    subject(:t) do
      AWS.stub!
      t = Automan::Cloudformation::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'returns true when status is DELETE_COMPLETE' do
      t.stub(:stack_status).and_return('DELETE_COMPLETE')
      t.stack_deleted?('foo').should be_true
    end

    it 'raises an error when the delete fails' do
      t.stub(:stack_status).and_return('DELETE_FAILED')
      expect {
        t.stack_deleted?('foo')
      }.to raise_error Automan::Cloudformation::StackDeletionError
    end

    it 'returns false for any other status' do
      t.stub(:stack_status).and_return('foo')
      t.stack_deleted?('foo').should be_false
    end
  end
end