require "spec_helper"

describe Automan::Beanstalk::Configuration do
  before(:each) do
    subject.application = 'foo'
    subject.name        = 'foo-template'
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
      error = Aws::ElasticBeanstalk::Errors::InvalidParameterValue.new(nil,'No Configuration Template named')
      subject.eb.stub_responses(:describe_configuration_settings, error )
      expect(subject.config_template_exists?).to be_falsey
    end

    it 'returns true if application and template name exists in response' do
      resp = {
        configuration_settings: [
          {
            application_name: subject.application,
            template_name:    subject.name
          }
        ]
      }
      subject.eb.stub_responses(:describe_configuration_settings, resp)
      expect(subject.config_template_exists?).to be_truthy
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

      expect(subject.fix_config_keys(config_before)).to eq(config_after)
    end
  end

  describe '#create' do
    it 'does not create if configuration exists' do
      allow(subject).to receive(:config_template_exists?).and_return(true)
      expect(subject).to_not receive(:create_config_template)
      subject.create
    end

    it 'does create if configuration does not exist' do
      allow(subject).to receive(:config_template_exists?).and_return(false)
      expect(subject).to receive(:create_config_template)
      subject.create
    end
  end

  describe '#delete' do
    it 'does delete if configuration exists' do
      allow(subject).to receive(:config_template_exists?).and_return(true)
      expect(subject).to receive(:delete_config_template)
      subject.delete
    end

    it 'does not delete if configuration does not exist' do
      allow(subject).to receive(:config_template_exists?).and_return(false)
      expect(subject).to_not receive(:delete_config_template)
      subject.delete
    end
  end

  describe '#update' do
    it 'deletes configuration and recreates it if it exists' do
      allow(subject).to receive(:config_template_exists?).and_return(true)
      expect(subject).to receive(:delete_config_template)
      expect(subject).to receive(:create_config_template)
      subject.update
    end

    it 'does not try to delete configuration if it does not exist' do
      allow(subject).to receive(:config_template_exists?).and_return(false)
      expect(subject).to_not receive(:delete_config_template)
      expect(subject).to receive(:create_config_template)
      subject.update
    end
  end
end