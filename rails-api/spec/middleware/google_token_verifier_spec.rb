require 'rails_helper'

RSpec.describe GoogleTokenVerifier, type: :middleware do
  let(:app) { ->(env) { [200, env, "app"] } }
  let(:middleware) { GoogleTokenVerifier.new(app) }
  let(:env) { Rack::MockRequest.env_for('/') }
  let(:validator) { instance_double(GoogleIDToken::Validator) }

  before do
    allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
  end

  context 'when no Authorization header is present' do
    it 'returns unauthorized response' do
      response = middleware.call(env)
      expect(response[0]).to eq(401)
      expect(response[1]['Content-Type']).to eq('application/json')
      expect(response[2]).to eq([{ error: 'Unauthorized' }.to_json])
    end
  end

  context 'when Authorization header is present' do
    let(:token) { 'fake_token' }
    let(:payload) { { 'sub' => '12345' } }

    before do
      env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
    end

    context 'when token is valid' do
      it 'calls the app and sets google_user_id in env' do
        allow(validator).to receive(:check).with(token, ENV['GOOGLE_CLIENT_ID']).and_return(payload)
        response = middleware.call(env)
        expect(response[1]['google_user_id']).to eq('12345')
        expect(response[2]).to eq("app")
      end
    end

    context 'when token is invalid' do
      it 'returns unauthorized response' do
        allow(validator).to receive(:check).with(token, ENV['GOOGLE_CLIENT_ID']).and_raise(GoogleIDToken::ValidationError)
        response = middleware.call(env)
        expect(response[0]).to eq(401)
        expect(response[1]['Content-Type']).to eq('application/json')
        expect(response[2]).to eq([{ error: 'Unauthorized' }.to_json])
      end
    end
  end
end
