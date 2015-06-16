require 'automan'

describe Automan::Beanstalk::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
  it { should respond_to :environment_exists? }

  describe '#environment_exists?' do
    subject(:t) do
      AWS.stub!
      t = Automan::Beanstalk::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it "returns false if environment does not exist" do
      resp = subject.eb.stub_for :describe_environments
      resp.data[:environments] = [{}]
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns false if environment is in Terminated state" do
      resp = subject.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Terminated'}]
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns false if environment is in Terminating state" do
      resp = subject.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Terminating'}]
      expect(subject.environment_exists?('foo')).to be_falsey
    end

    it "returns true if environment does exist" do
      resp = subject.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo'}]
      expect(subject.environment_exists?('foo')).to be_truthy
    end

    it "returns true if environment is in Ready state" do
      resp = subject.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Ready'}]
      expect(subject.environment_exists?('foo')).to be_truthy
    end
  end

  describe '#terminate' do
    subject(:t) do
      AWS.stub!
      t = Automan::Beanstalk::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

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