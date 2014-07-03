require 'automat'

describe Automat::Beanstalk::Terminator do
  it { should respond_to :name }
  it { should respond_to :terminate }
  it { should respond_to :environment_exists? }

  describe '#environment_exists?' do
    subject(:t) do
      AWS.stub!
      t = Automat::Beanstalk::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it "returns false if environment does not exist" do
      resp = t.eb.stub_for :describe_environments
      resp.data[:environments] = [{}]
      t.environment_exists?('foo').should be_false
    end

    it "returns false if environment is in Terminated state" do
      resp = t.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Terminated'}]
      t.environment_exists?('foo').should be_false
    end

    it "returns false if environment is in Terminating state" do
      resp = t.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Terminating'}]
      t.environment_exists?('foo').should be_false
    end

    it "returns true if environment does exist" do
      resp = t.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo'}]
      t.environment_exists?('foo').should be_true
    end

    it "returns true if environment is in Ready state" do
      resp = t.eb.stub_for :describe_environments
      resp.data[:environments] = [{environment_name: 'foo', status: 'Ready'}]
      t.environment_exists?('foo').should be_true
    end
  end

  describe '#terminate' do
    subject(:t) do
      AWS.stub!
      t = Automat::Beanstalk::Terminator.new
      t.logger = Logger.new('/dev/null')
      t
    end

    it 'should call #terminate_environment if the environment exists' do
      t.stub(:environment_exists?).and_return(true)
      t.should_receive :terminate_environment
      t.terminate
    end

    it 'should not call #terminate_environment if the environment does not exist' do
      t.stub(:environment_exists?).and_return(false)
      t.should_not_receive :terminate_environment
      t.terminate
    end
  end
end