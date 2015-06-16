require 'automan'

describe Automan::Cloudformation::Terminator do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :terminate }
  it { is_expected.to respond_to :stack_exists? }
  it { is_expected.to respond_to :stack_deleted? }
  it { is_expected.to respond_to :delete_stack }
  it { is_expected.to respond_to :wait_for_completion }

  describe '#terminate' do
    subject() do
      AWS.stub!
      t = Automan::Cloudformation::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'should call #delete_stack if the stack exists' do
      allow(subject).to receive(:stack_exists?).and_return(true)
      expect(subject).to receive :delete_stack
      subject.terminate
    end

    it 'should not call #delete_stack if the stack does not exist' do
      allow(subject).to receive(:stack_exists?).and_return(false)
      expect(subject).to_not receive :delete_stack
      subject.terminate
    end
  end

  describe '#stack_deleted?' do
    subject() do
      AWS.stub!
      t = Automan::Cloudformation::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'returns true if the stack does not exist' do
      allow(subject).to receive(:stack_exists?).and_return(false)
      allow(subject).to receive(:stack_status).and_raise StandardError
      expect(subject.stack_deleted?('foo')).to be_truthy
    end

    it 'returns true when status is DELETE_COMPLETE' do
      allow(subject).to receive(:stack_status).and_return('DELETE_COMPLETE')
      expect(subject.stack_deleted?('foo')).to be_truthy
    end

    it 'raises an error when the delete fails' do
      allow(subject).to receive(:stack_status).and_return('DELETE_FAILED')
      expect {
        subject.stack_deleted?('foo')
      }.to raise_error Automan::Cloudformation::StackDeletionError
    end

    it 'returns false for any other status' do
      allow(subject).to receive(:stack_status).and_return('foo')
      expect(subject.stack_deleted?('foo')).to be_falsey
    end
  end
end