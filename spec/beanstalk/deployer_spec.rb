require "automat"

describe Automat::Beanstalk::Deployer do

  it { should respond_to :name }
  it { should respond_to :version_label }
  it { should respond_to :package }
  it { should respond_to :environment }
  it { should respond_to :configuration_template }
  it { should respond_to :logger }
  it { should respond_to :eb }
  it { should respond_to :s3 }
  it { should respond_to :log_aws_calls }
  it { should respond_to :deploy }

  # Constraint: Must be from 4 to 23 characters in length.
  # The name can contain only letters, numbers, and hyphens.
  # It cannot start or end with a hyphen.
  describe '#eb_environment_name' do
    subject(:bd) { Automat::Beanstalk::Deployer.new }

    it "is at least 4 characters" do
      bd.name = "a"
      bd.environment = "a"
      bd.eb_environment_name.length.should be >= 4
    end

    it "is no more than 23 characters" do
      bd.name = "a" * 23
      bd.environment = "dev"
      bd.eb_environment_name.length.should be <= 23
    end

    it "contains only letters, numbers, and hyphens" do
      bd.name = '@#$%^foo_bar!$%&&E.'
      bd.environment = 'prod.baz'
      bd.eb_environment_name.should match(/[a-z0-9-]+/)
    end

    it "cannot start or end with a hyphen" do
      bd.name = '--foo'
      bd.environment = 'bar--'
      bd.eb_environment_name.should match(/^[^-].*[^-]$/)
    end

    it "is still at least 4 characters even after removing restricted strings" do
      bd.name = '--f'
      bd.environment = '-'
      bd.eb_environment_name.length.should be >= 4
    end
  end

end

