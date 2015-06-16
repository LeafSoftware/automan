require "automan"

describe Automan::Beanstalk::Application do
  it { is_expected.to respond_to :name }
  it { is_expected.to respond_to :create }
  it { is_expected.to respond_to :delete }

  describe '#create' do
    subject() do
      AWS.stub!
      a = Automan::Beanstalk::Application.new
      a.logger = Logger.new('/dev/null')
      a
    end

    it "does not create if the application already exists" do
      allow(subject).to receive(:application_exists?).and_return(true)
      expect(subject).to_not receive(:create_application)
      subject.create
    end

    it "does create if the application doesn't exist" do
      allow(subject).to receive(:application_exists?).and_return(false)
      expect(subject).to receive(:create_application)
      subject.create
    end
  end

  describe '#delete' do
    subject() do
      AWS.stub!
      a = Automan::Beanstalk::Application.new
      a.logger = Logger.new('/dev/null')
      a
    end

    it "does delete if the application already exists" do
      allow(subject).to receive(:application_exists?).and_return(true)
      expect(subject).to receive(:delete_application)
      subject.delete
    end

    it "does not delete if the application doesn't exist" do
      allow(subject).to receive(:application_exists?).and_return(false)
      expect(subject).to_not receive(:delete_application)
      subject.delete
    end
  end
end