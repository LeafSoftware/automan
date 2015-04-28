require 'automan'
require 'logger'

ENV['MAX_SNAPSHOTS'] = "50"

describe Automan::RDS::Snapshot do
  it { should respond_to :rds }
  it { should respond_to :create }
  it { should respond_to :delete }
  it { should respond_to :prune }
  it { should respond_to :latest }
  it { should respond_to :default_snapshot_name }

  describe '#default_snapshot_name' do
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s.stub(:db_environment).and_return('dev1')
      s
    end

    it "never returns nil" do
      s.default_snapshot_name('somedb').should_not be_nil
    end

    it "returns environment dash time string" do
      name = s.default_snapshot_name('somedb')
      name.should match /^dev1-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})/
    end

  end

  describe '#create' do
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it "raises error if could not find database" do
      s.stub(:find_db).and_return(nil)
      expect {
        s.create
      }.to raise_error Automan::RDS::DatabaseDoesNotExistError
    end

    it "raises error if RDS says database does not exist" do
      db = double(:db)
      db.stub(:exists?).and_return(false)
      s.stub(:find_db).and_return(db)

      expect {
        s.create
      }.to raise_error Automan::RDS::DatabaseDoesNotExistError
    end

  end

  describe '#tagged_can_prune?' do
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s.stub(:snapshot_arn)
      s
    end

    it 'returns true if snapshot is tagged with CanPrune=yes' do
      s.stub(:tags).and_return( {'CanPrune' => 'yes'} )
      s.tagged_can_prune?( double() ).should be_true
    end

    it 'returns false if snapshot is missing CanPrune tag' do
      s.stub(:tags).and_return( {} )
      s.tagged_can_prune?( double() ).should be_false
    end

    it 'returns false if snapshot is tagged with CanPrune=nil' do
      s.stub(:tags).and_return( {'CanPrune' => nil} )
      s.tagged_can_prune?( double() ).should be_false
    end

    it 'returns false if snapshot is tagged with CanPrune=foo' do
      s.stub(:tags).and_return( {'CanPrune' => 'foo'} )
      s.tagged_can_prune?( double() ).should be_false
    end
  end

  describe '#available?' do
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true if status is "available"' do
      snap = double(:snap)
      snap.stub(:status).and_return('available')
      s.available?(snap).should be_true
    end

    it 'returns false if status is foo' do
      snap = double(:snap)
      snap.stub(:status).and_return('foo')
      s.available?(snap).should be_false
    end
  end

  describe '#manual?' do
    let(:snap) { double }
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it 'returns true if type is "manual"' do
      snap.stub(:snapshot_type).and_return('manual')
      s.manual?(snap).should be_true
    end

    it 'returns false if type is foo' do
      snap.stub(:snapshot_type).and_return('foo')
      s.manual?(snap).should be_false
    end
  end

  describe '#prunable_snapshots' do
    let(:snap) { double }
    subject(:s) do
      AWS.stub!
      s = Automan::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s.stub(:get_all_snapshots).and_return( [ snap ] )
      s
    end

    it 'includes snapshots which can be pruned' do
      s.stub(:can_prune?).and_return(true)
      s.prunable_snapshots.should include(snap)
    end

    it 'excludes snapshots which should not be pruned' do
      s.stub(:can_prune?).and_return(false)
      s.prunable_snapshots.should_not include(snap)
    end
  end
end