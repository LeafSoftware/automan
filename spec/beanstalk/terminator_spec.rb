require 'spec_helper'

describe Automan::Beanstalk::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
  it { should respond_to :environment_exists? }

  describe '#environment_exists?' do
    it "returns false if environment does not exist" do
      subject.eb.stub_responses(:describe_environments, {environments: []})
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns false if environment is in Terminated state" do
      resp = {
        environments: [
          {
            environment_name: 'foo',
            status: 'Terminated'
          }
        ]
      }
      subject.eb.stub_responses(:describe_environments, resp)
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns false if environment is in Terminating state" do
      resp = {
        environments: [
          {
            environment_name: 'foo',
            status: 'Terminating'
          }
        ]
      }
      subject.eb.stub_responses(:describe_environments, resp)
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns true if environment does exist" do
      resp = {
        environments: [
          {
            environment_name: 'foo'
          }
        ]
      }
      subject.eb.stub_responses(:describe_environments, resp)
      expect(subject.environment_exists?('foo')).to be_truthy
    end

    it "returns true if environment is in Ready state" do
      resp = {
        environments: [
          {
            environment_name: 'foo',
            status: 'Ready'
          }
        ]
      }
      subject.eb.stub_responses(:describe_environments, resp)
      expect(subject.environment_exists?('foo')).to be_truthy
    end
  end

  describe '#terminate' do
    it 'should call #terminate_environment if the environment exists' do
      allow(subject).to receive(:environment_exists?).and_return(true)
      expect(subject).to receive :terminate_environment
      subject.terminate
    end

    it 'should not call #terminate_environment if the environment does not exist' do
      allow(subject).to receive(:environment_exists?).and_return(false)
      expect(subject).to_not receive :terminate_environment
      subject.terminate
    end
  end
end