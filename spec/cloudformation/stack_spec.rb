require 'spec_helper'

describe Automan::Cloudformation::Stack do
  it { is_expected.to respond_to :exists? }
  it { is_expected.to respond_to :status }
  it { is_expected.to respond_to :launch_complete? }
  it { is_expected.to respond_to :update_complete? }
  it { is_expected.to respond_to :update }
  it { is_expected.to respond_to :launch }
  it { is_expected.to respond_to :delete }

  describe '#exists?' do
    it 'is true when stack has a valid id' do
      subject.cfn = double(stack: double(stack_id: 'foo'))
      expect(subject.exists?).to be_truthy
    end
  end

  describe '#launch_complete?' do
    it 'returns true when the stack completes' do
      allow(subject).to receive(:status).and_return('CREATE_COMPLETE')
      expect(subject.launch_complete?).to be_truthy
    end

    it 'raises an error when the stack fails' do
      allow(subject).to receive(:status).and_return('CREATE_FAILED')
      expect {
        subject.launch_complete?
      }.to raise_error Automan::Cloudformation::StackCreationError
    end

    rollback_states = %w[ROLLBACK_COMPLETE ROLLBACK_FAILED ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack goes into #{state} state" do
        allow(subject).to receive(:status).and_return(state)
        expect {
          subject.launch_complete?
        }.to raise_error Automan::Cloudformation::StackCreationError
      end
    end

    it 'returns false for any other state' do
      allow(subject).to receive(:status).and_return('foo')
      expect(subject.launch_complete?).to be_falsey
    end
  end

  describe '#update_complete?' do
    it 'returns true when the stack completes' do
      allow(subject).to receive(:status).and_return('UPDATE_COMPLETE')
      expect(subject.update_complete?).to be_truthy
    end

    rollback_states = %w[UPDATE_ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_IN_PROGRESS]
    rollback_states.each do |state|
      it "raises an error when the stack enters #{state} state" do
        allow(subject).to receive(:status).and_return(state)
        expect {
          subject.update_complete?
        }.to raise_error Automan::Cloudformation::StackUpdateError
      end
    end

    it 'returns false for any other state' do
      allow(subject).to receive(:status).and_return('foo')
      expect(subject.update_complete?).to be_falsey
    end
  end

  describe '#delete_complete?' do
    before(:each) do
      allow(subject).to receive(:exists?).and_return(true)
    end

    it 'returns true if the stack does not exist' do
      allow(subject).to receive(:exists?).and_return(false)
      expect(subject.delete_complete?).to be_truthy
    end

    it 'returns true when status is DELETE_COMPLETE' do
      allow(subject).to receive(:status).and_return('DELETE_COMPLETE')
      expect(subject.delete_complete?).to be_truthy
    end

    it 'raises an error when the delete fails' do
      allow(subject).to receive(:status).and_return('DELETE_FAILED')
      expect {
        subject.delete_complete?
      }.to raise_error Automan::Cloudformation::StackDeletionError
    end

    it 'returns false for any other status' do
      allow(subject).to receive(:status).and_return('foo')
      expect(subject.delete_complete?).to be_falsey
    end
  end

end
