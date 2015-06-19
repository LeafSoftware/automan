require 'automan'

describe Automan::Cloudformation::Template do
  it { is_expected.to respond_to :template_contents }
  it { is_expected.to respond_to :validation_response }
  it { is_expected.to respond_to :valid? }
  it { is_expected.to respond_to :required_parameters }
  it { is_expected.to respond_to :capabilities }
end
