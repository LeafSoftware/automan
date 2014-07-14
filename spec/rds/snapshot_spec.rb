require 'automat'
require 'logger'

describe Automat::RDS::Snapshot do
  it { should respond_to :rds }
  it { should respond_to :create }
  it { should respond_to :delete }
  it { should respond_to :prune }
  it { should respond_to :latest }
  it { should respond_to :default_snapshot_name }

  describe '#default_snapshot_name' do
    subject(:s) do
      AWS.stub!
      s = Automat::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s.stub(:db_environment).and_return('dev1')
      s
    end

    it "never returns nil" do
      s.default_snapshot_name('somedb').should_not be_nil
    end

    it "returns environment dash iso8601 string" do
      name = s.default_snapshot_name('somedb')
      name.should match /^dev1-(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})[+-](\d{2})-(\d{2})/
    end

  end

  describe '#create' do
    subject(:s) do
      AWS.stub!
      s = Automat::RDS::Snapshot.new
      s.logger = Logger.new('/dev/null')
      s
    end

    it "raises error if could not find database" do
      s.stub(:find_db).and_return(nil)
      expect {
        s.create
      }.to raise_error Automat::RDS::DatabaseDoesNotExistError
    end

    it "raises error if RDS says database does not exist" do
      db = double(:db)
      db.stub(:exists?).and_return(false)
      s.stub(:find_db).and_return(db)

      expect {
        s.create
      }.to raise_error Automat::RDS::DatabaseDoesNotExistError
    end

  end
end