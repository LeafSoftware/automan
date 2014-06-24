require 'automat'
require 'logger'

describe Automat::RDS::Snapshot do
  it {should respond_to :rds }
  it {should respond_to :create }
  it {should respond_to :delete }
  it {should respond_to :can_prune? }
end