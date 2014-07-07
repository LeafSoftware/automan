require 'automat'
require 'logger'

describe Automat::Ec2::Image do
  it { should respond_to :ec2 }
  it { should respond_to :create }
  it { should respond_to :prune }
  it { should respond_to :default_image_name }
  it { should respond_to :image_snapshot_exists? }
  it { should respond_to :image_snapshot }

  describe '#default_image_name' do
    subject(:s) do
      AWS.stub!
      s = Automat::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s.stub(:name).and_return('skee-lo')
      s
    end

    it "never returns nil" do
      s.default_image_name().should_not be_nil
    end

    it "returns name dash iso8601 string" do
      name = s.default_image_name()
      name.should match /^skee-lo-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})[+-](\d{2})-(\d{2})/
    end

  end

  describe '#image_snapshot' do
    subject(:s) do
      AWS.stub!
      s = Automat::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it "returns id if the snapshot exists" do
      fake_ami = double("ami")
      fake_ami.stub(:block_devices) { [ { ebs: {snapshot_id: 'foo' } } ] }
      s.image_snapshot(fake_ami).should eq('foo')
    end

    it "returns nil if the snapshot is nil" do
      fake_ami = double("ami")
      fake_ami.stub(:block_devices) { [ { ebs: {snapshot_id: nil } } ] }
      s.image_snapshot(fake_ami).should be_nil
    end

    it "returns nil if the ebs is nil" do
      fake_ami = double("ami")
      fake_ami.stub(:block_devices) { [ { ebs: nil } ] }
      s.image_snapshot(fake_ami).should be_nil
    end

    it "returns nil if the device is nil" do
      fake_ami = double("ami")
      fake_ami.stub(:block_devices) { [ nil ] }
      s.image_snapshot(fake_ami).should be_nil
    end
  end
end
