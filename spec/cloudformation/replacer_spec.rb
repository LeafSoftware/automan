require 'automan'

describe Automan::Cloudformation::Replacer do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :replace_instances }
  it { is_expected.to respond_to :ok_to_replace_instances? }
  it { is_expected.to respond_to :stack_exists? }

  describe '#ok_to_replace_instances?' do
    subject() do
      AWS.stub!
      Automan::Cloudformation::Replacer.new
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
        expect(subject.ok_to_replace_instances?(state, Time.now)).to be_truthy
      end
    end

    good_states.each do |state|
      it "returns false when stack is in the right state but has not been updated in the last 5m" do
        last_updated = Time.now - (5 * 60 + 1)
        expect(subject.ok_to_replace_instances?(state, last_updated)).to be_falsey
      end
    end

    bad_states.each do |state|
      it "raises error when stack is borked (state: #{state})" do
        expect {
          subject.ok_to_replace_instances?(state, Time.now)
        }.to raise_error Automan::Cloudformation::StackBrokenError
      end
    end

    wait_states.each do |state|
      it "returns false when it is not yet ok to replace (state: #{state})" do
        expect(subject.ok_to_replace_instances?(state, Time.now)).to be_falsey
      end
    end
  end
end