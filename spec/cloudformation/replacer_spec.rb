require 'automat'

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

    good_states = %w[UPDATE_COMPLETE]

    bad_states =
      %w[
        CREATE_FAILED ROLLBACK_IN_PROGRESS ROLLBACK_FAILED
        ROLLBACK_COMPLETE DELETE_IN_PROGRESS DELETE_FAILED
        DELETE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS
        UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
        UPDATE_ROLLBACK_COMPLETE
        ]

    wait_states =
      %w[CREATE_COMPLETE CREATE_IN_PROGRESS
         UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
        ]

    good_states.each do |state|
      it "returns true when stack is in the right state (state: #{state})" do
        r.ok_to_replace_instances?(state, Time.now).should be_true
      end
    end

    good_states.each do |state|
      it "returns false when stack is in the right state but has not been updated in the last 5m" do
        last_updated = Time.now - (5 * 60 + 1)
        r.ok_to_replace_instances?(state, last_updated).should be_false
      end
    end

    bad_states.each do |state|
      it "raises error when stack is borked (state: #{state})" do
        expect {
          r.ok_to_replace_instances?(state, Time.now)
        }.to raise_error Automat::Cloudformation::StackBrokenError
      end
    end

    wait_states.each do |state|
      it "returns false when it is not yet ok to replace (state: #{state})" do
        r.ok_to_replace_instances?(state, Time.now).should be_false
      end
    end
  end
end