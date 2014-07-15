require "automat"

describe Automat::Beanstalk::Configuration do
  subject(:c) do
    AWS.stub!
    c = Automat::Beanstalk::Configuration.new
    c.logger = Logger.new('/dev/null')
    c
  end

  it { should respond_to :name }
  it { should respond_to :application }
  it { should respond_to :template }
  it { should respond_to :platform }
  it { should respond_to :config_template_exists? }
  it { should respond_to :create_config_template }
  it { should respond_to :delete_config_template }
  it { should respond_to :fix_config_keys }
  it { should respond_to :create }
  it { should respond_to :delete }
  it { should respond_to :update }

  describe '#config_template_exists?' do

    it 'returns false if raises InvalidParameterValue with missing config template message' do
      c.eb = double(:eb)
      error = AWS::ElasticBeanstalk::Errors::InvalidParameterValue.new('No Configuration Template named')
      c.eb.stub(:describe_configuration_settings).and_raise(error)
      c.config_template_exists?.should be_false
    end
  end

  describe '#fix_config_keys' do
    it 'snake-cases the keys' do
      config_before = [
        {
          "Namespace" => "aws:elasticbeanstalk:application:environment",
          "OptionName" => "Environment",
          "Value" => "dev1"
        }
      ]

      config_after = [
        {
          "namespace" => "aws:elasticbeanstalk:application:environment",
          "option_name" => "Environment",
          "value" => "dev1"
        }
      ]

      c.fix_config_keys(config_before).should eq(config_after)
    end
  end

  describe '#create' do
    it 'does not create if configuration exists' do
      c.stub(:config_template_exists?).and_return(true)
      c.should_not_receive(:create_config_template)
      c.create
    end

    it 'does create if configuration does not exist' do
      c.stub(:config_template_exists?).and_return(false)
      c.should_receive(:create_config_template)
      c.create
    end
  end

  describe '#delete' do
    it 'does delete if configuration exists' do
      c.stub(:config_template_exists?).and_return(true)
      c.should_receive(:delete_config_template)
      c.delete
    end

    it 'does not delete if configuration does not exist' do
      c.stub(:config_template_exists?).and_return(false)
      c.should_not_receive(:delete_config_template)
      c.delete
    end
  end

  describe '#update' do
    it 'deletes configuration and recreates it if it exists' do
      c.stub(:config_template_exists?).and_return(true)
      c.should_receive(:delete_config_template)
      c.should_receive(:create_config_template)
      c.update
    end

    it 'does not try to delete configuration if it does not exist' do
      c.stub(:config_template_exists?).and_return(false)
      c.should_not_receive(:delete_config_template)
      c.should_receive(:create_config_template)
      c.update
    end
  end
end