require 'automan/mixins/utils'

describe Automan::Mixins::Utils do
  subject() { (Class.new { include Automan::Mixins::Utils }).new }

  it "adds String#underscore" do
    expect(String.new).to respond_to :underscore
  end

  describe "String#underscore" do
    it "underscore's like a boss" do
      expect("Namespace".underscore).to eq "namespace"
      expect("OptionName".underscore).to eq "option_name"
      expect("Value".underscore).to eq "value"
    end
  end

  it { is_expected.to respond_to :region_from_az }

  it "returns az properly" do
    expect(subject.region_from_az("us-east-1a")).to eq 'us-east-1'
    expect(subject.region_from_az("us-east-1b")).to eq 'us-east-1'
    expect(subject.region_from_az("us-east-1c")).to eq 'us-east-1'
    expect(subject.region_from_az("us-east-1d")).to eq 'us-east-1'
    expect(subject.region_from_az("ap-northeast-1a")).to eq 'ap-northeast-1'
    expect(subject.region_from_az("ap-northeast-1b")).to eq 'ap-northeast-1'
    expect(subject.region_from_az("ap-northeast-1c")).to eq 'ap-northeast-1'
    expect(subject.region_from_az("sa-east-1a")).to eq 'sa-east-1'
    expect(subject.region_from_az("sa-east-1b")).to eq 'sa-east-1'
    expect(subject.region_from_az("ap-southeast-1a")).to eq 'ap-southeast-1'
    expect(subject.region_from_az("ap-southeast-1b")).to eq 'ap-southeast-1'
    expect(subject.region_from_az("ap-southeast-2a")).to eq 'ap-southeast-2'
    expect(subject.region_from_az("ap-southeast-2b")).to eq 'ap-southeast-2'
    expect(subject.region_from_az("us-west-2a")).to eq 'us-west-2'
    expect(subject.region_from_az("us-west-2b")).to eq 'us-west-2'
    expect(subject.region_from_az("us-west-2c")).to eq 'us-west-2'
    expect(subject.region_from_az("us-west-1a")).to eq 'us-west-1'
    expect(subject.region_from_az("us-west-1c")).to eq 'us-west-1'
    expect(subject.region_from_az("eu-west-1a")).to eq 'eu-west-1'
    expect(subject.region_from_az("eu-west-1b")).to eq 'eu-west-1'
    expect(subject.region_from_az("eu-west-1c")).to eq 'eu-west-1'
  end
end