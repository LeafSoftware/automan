require "automan"

describe Automan::Beanstalk::Application do
  it { should respond_to :name }
  it { should respond_to :create }
  it { should respond_to :delete }

  describe '#create' do
    subject(:a) do
      AWS.stub!
      a = Automan::Beanstalk::Application.new
      a.logger = Logger.new('/dev/null')
      a
    end

    it "does not create if the application already exists" do
      a.stub(:application_exists?).and_return(true)
      a.should_not_receive(:create_application)
      a.create
    end

    it "does create if the application doesn't exist" do
      a.stub(:application_exists?).and_return(false)
      a.should_receive(:create_application)
      a.create
    end
  end

  describe '#delete' do
    subject(:a) do
      AWS.stub!
      a = Automan::Beanstalk::Application.new
      a.logger = Logger.new('/dev/null')
      a
    end

    it "does delete if the application already exists" do
      a.stub(:application_exists?).and_return(true)
      a.should_receive(:delete_application)
      a.delete
    end

    it "does not delete if the application doesn't exist" do
      a.stub(:application_exists?).and_return(false)
      a.should_not_receive(:delete_application)
      a.delete
    end
  end
end