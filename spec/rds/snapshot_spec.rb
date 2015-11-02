require 'automan'
require 'logger'

ENV['MAX_SNAPSHOTS'] = "50"

describe Automan::RDS::Snapshot do
  it { is_expected.to respond_to :rds }
  it { is_expected.to respond_to :create }
  it { is_expected.to respond_to :delete }
  it { is_expected.to respond_to :prune }
  it { is_expected.to respond_to :latest }
  it { is_expected.to respond_to :default_snapshot_name }

  describe '#default_snapshot_name' do
    subject() do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      allow(s).to receive(:db_environment).and_return('dev1')
      s
    end

    it "never returns nil" do
      expect(subject.default_snapshot_name('somedb')).to_not be_nil
    end

    it "returns environment dash time string" do
      name = subject.default_snapshot_name('somedb')
      expect(name).to match /^dev1-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})/
    end

  end

  describe '#create' do
    subject() do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it "raises error if could not find database" do
      allow(subject).to receive(:find_db).and_return(nil)
      expect {
        subject.create
      }.to raise_error Automan::RDS::DatabaseDoesNotExistError
    end

    it "raises error if RDS says database does not exist" do
      db = double(:db)
      allow(db).to receive(:exists?).and_return(false)
      allow(subject).to receive(:find_db).and_return(db)

      expect {
        subject.create
      }.to raise_error Automan::RDS::DatabaseDoesNotExistError
    end

  end

  describe '#available?' do
    subject() do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true if status is "available"' do
      snap = double(status: 'available')
      expect(subject.available?(snap)).to be_truthy
    end

    it 'returns false if status is foo' do
      snap = double(status: 'foo')
      expect(subject.available?(snap)).to be_falsey
    end
  end
end
