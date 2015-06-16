require 'automan'
require 'logger'

describe Automan::Ec2::Image do
  it { is_expected.to respond_to :ec2 }
  it { is_expected.to respond_to :create }
  it { is_expected.to respond_to :prune }
  it { is_expected.to respond_to :default_image_name }
  it { is_expected.to respond_to :image_snapshot_exists? }
  it { is_expected.to respond_to :image_snapshot }
  it { is_expected.to respond_to :delete_snapshots }
  it { is_expected.to respond_to :is_more_than_month_old? }

  describe '#default_image_name' do
    subject() do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      allow(s).to receive(:name).and_return('skee-lo')
      s
    end

    it "never returns nil" do
      expect(subject.default_image_name()).to_not be_nil
    end

    it "returns name dash iso8601 string" do
      name = subject.default_image_name()
      expect(name).to match /^skee-lo-(\d{4})-(\d{2})-(\d{2})T(\d{2})(\d{2})(\d{2})Z/
    end

  end

  describe '#image_snapshot' do
    subject() do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it "returns id if the snapshot exists" do
      fake_ami = double("ami")
      allow(fake_ami).to receive(:block_devices) { [ { ebs: {snapshot_id: 'foo' } } ] }
      expect(subject.image_snapshot(fake_ami)).to eq('foo')
    end

    it "returns nil if the snapshot is nil" do
      fake_ami = double("ami")
      allow(fake_ami).to receive(:block_devices) { [ { ebs: {snapshot_id: nil } } ] }
      expect(subject.image_snapshot(fake_ami)).to be_nil
    end

    it "returns nil if the ebs is nil" do
      fake_ami = double("ami")
      allow(fake_ami).to receive(:block_devices) { [ { ebs: nil } ] }
      expect(subject.image_snapshot(fake_ami)).to be_nil
    end

    it "returns nil if the device is nil" do
      fake_ami = double("ami")
      allow(fake_ami).to receive(:block_devices) { [ nil ] }
      expect(subject.image_snapshot(fake_ami)).to be_nil
    end
  end

  describe '#delete_snapshots' do
    subject() do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'does not delete snapshots with status != :completed' do
      snapshot = double(:snapshot)
      allow(snapshot).to receive(:status).and_return(:foo)
      allow(snapshot).to receive(:id)
      expect(snapshot).to_not receive(:delete)
      subject.delete_snapshots( [ snapshot ])
    end

    it 'deletes snapshots with status == :completed' do
      snapshot = double(:snapshot)
      allow(snapshot).to receive(:status).and_return(:completed)
      allow(snapshot).to receive(:id)
      expect(snapshot).to receive(:delete)
      subject.delete_snapshots( [ snapshot ])
    end
  end

  describe '#deregister_images' do
    subject() do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      allow(s).to receive(:image_snapshot).and_return('foo')
      s
    end

    before(:each) do
      @image = double(:image)
      allow(@image).to receive(:id)
      allow(subject).to receive(:my_images).and_return( [ @image ] )
    end

    it 'does not deregister images with state != :available' do
      allow(@image).to receive(:state).and_return(:foo)
      allow(@image).to receive(:tags).and_return( {'CanPrune' => 'yes'} )
      expect(@image).to_not receive(:delete)
      subject.deregister_images( [ 'foo' ] )
    end

    it 'does not deregister images w/o prunable tag' do
      allow(@image).to receive(:state).and_return(:available)
      allow(@image).to receive(:tags).and_return( Hash.new )
      expect(@image).to_not receive(:delete)
      subject.deregister_images( [ 'foo' ] )
    end

    it 'does not deregister images whose snapshots are not in the list' do
      allow(@image).to receive(:state).and_return(:available)
      allow(@image).to receive(:tags).and_return( {'CanPrune' => 'yes'} )
      expect(@image).to_not receive(:delete)
      subject.deregister_images( [ 'bar' ] )
    end

    it 'deletes available, prunable images on the list' do
      allow(@image).to receive(:state).and_return(:available)
      allow(@image).to receive(:tags).and_return( {'CanPrune' => 'yes'} )
      expect(@image).to receive(:delete)
      subject.deregister_images( [ 'foo' ] )
    end
  end

  describe '#is_more_than_month_old?' do
    subject() do
      AWS.stub!
      s = Automan::Ec2::Image.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns false if argument is not a Time object' do
      expect(subject.is_more_than_month_old?(Object.new)).to be_falsey
    end

    it 'returns true if time is more than 30 days in the past' do
      days_of_yore = Time.now - (60*60*24*30)
      expect(subject.is_more_than_month_old?(days_of_yore)).to be_truthy
    end

    it 'returns false if time is in the last 30 days' do
      just_yesterday = Time.now - (60*60*24)
      expect(subject.is_more_than_month_old?(just_yesterday)).to be_falsey
    end
  end
end
