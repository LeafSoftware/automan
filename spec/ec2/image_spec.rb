require 'automan'
require 'logger'

describe Automan::Ec2::Image do
  it { should respond_to :ec2 }
  it { should respond_to :create }
  it { should respond_to :prune }
  it { should respond_to :default_image_name }
  it { should respond_to :image_snapshot_exists? }
  it { should respond_to :image_snapshot }
  it { should respond_to :delete_snapshots }
  it { should respond_to :is_more_than_month_old? }

  describe '#default_image_name' do
    subject(:s) do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s.stub(:name).and_return('skee-lo')
      s
    end

    it "never returns nil" do
      s.default_image_name().should_not be_nil
    end

    it "returns name dash iso8601 string" do
      name = s.default_image_name()
      name.should match /^skee-lo-(\d{4})-(\d{2})-(\d{2})T(\d{2})(\d{2})(\d{2})Z/
    end

  end

  describe '#image_snapshot' do
    subject(:s) do
      AWS.stub!
      s = Automan::Ec2::Image.new
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

  describe '#delete_snapshots' do
    subject(:s) do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'does not delete snapshots with status != :completed' do
      snapshot = double(:snapshot)
      snapshot.stub(:status).and_return(:foo)
      snapshot.stub(:id)
      snapshot.should_not_receive(:delete)
      s.delete_snapshots( [ snapshot ])
    end

    it 'deletes snapshots with status == :completed' do
      snapshot = double(:snapshot)
      snapshot.stub(:status).and_return(:completed)
      snapshot.stub(:id)
      snapshot.should_receive(:delete)
      s.delete_snapshots( [ snapshot ])
    end
  end

  describe '#deregister_images' do
    subject(:s) do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s.stub(:image_snapshot).and_return('foo')
      s
    end

    before(:each) do
      @image = double(:image)
      @image.stub(:id)
      s.stub(:my_images).and_return( [ @image ] )
    end

    it 'does not deregister images with state != :available' do
      @image.stub(:state).and_return(:foo)
      @image.stub(:tags).and_return( {'CanPrune' => 'yes'} )
      @image.should_not_receive(:delete)
      s.deregister_images( [ 'foo' ] )
    end

    it 'does not deregister images w/o prunable tag' do
      @image.stub(:state).and_return(:available)
      @image.stub(:tags).and_return( Hash.new )
      @image.should_not_receive(:delete)
      s.deregister_images( [ 'foo' ] )
    end

    it 'does not deregister images whose snapshots are not in the list' do
      @image.stub(:state).and_return(:available)
      @image.stub(:tags).and_return( {'CanPrune' => 'yes'} )
      @image.should_not_receive(:delete)
      s.deregister_images( [ 'bar' ] )
    end

    it 'deletes available, prunable images on the list' do
      @image.stub(:state).and_return(:available)
      @image.stub(:tags).and_return( {'CanPrune' => 'yes'} )
      @image.should_receive(:delete)
      s.deregister_images( [ 'foo' ] )
    end
  end

  describe '#is_more_than_month_old?' do
    subject(:s) do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns false if argument is not a Time object' do
      s.is_more_than_month_old?(Object.new).should be_false
    end

    it 'returns true if time is more than 30 days in the past' do
      days_of_yore = Time.now - (60*60*24*30)
      s.is_more_than_month_old?(days_of_yore).should be_true
    end

    it 'returns false if time is in the last 30 days' do
      just_yesterday = Time.now - (60*60*24)
      s.is_more_than_month_old?(just_yesterday).should be_false
    end
  end
end
