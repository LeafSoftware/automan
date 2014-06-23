require 'automat'
require 'automat/cloudformation/errors'

describe Automat::Cloudformation::Replacer do
  it { should respond_to :name }
  it { should respond_to :replace_instances }
  it { should respond_to :ok_to_replace_instances? }
  it { should respond_to :stack_exists? }

  describe '#ok_to_replace_instances?' do
    subject(:r) do
      AWS.stub!
      r = Automat::Cloudformation::Replacer.new
    end

    let(:good_states) do
      %w[CREATE_COMPLETE UPDATE_COMPLETE]
    end

    let(:bad_states) do
      %w[
        CREATE_FAILED ROLLBACK_IN_PROGRESS ROLLBACK_FAILED
        ROLLBACK_COMPLETE DELETE_IN_PROGRESS DELETE_FAILED
        DELETE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS
        UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
        UPDATE_ROLLBACK_COMPLETE
      ]
    end

    let(:wait_states) do
      %w[CREATE_IN_PROGRESS UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS]
    end

    it "returns true when stack is in good state" do
      good_states.each do |state|
        r.ok_to_replace_instances?(state).should be_true
      end
    end

    it "raises error when stack is borked" do
      bad_states.each do |state|
        expect {
          r.ok_to_replace_instances?(state)
        }.to raise_error Automat::Cloudformation::StackBrokenError
      end
    end

    it "returns false when is not yet in a good state" do
      wait_states.each do |state|
        r.ok_to_replace_instances?(state).should be_false
      end
    end
  end
end