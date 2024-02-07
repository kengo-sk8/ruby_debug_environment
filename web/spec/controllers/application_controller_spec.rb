require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#cat_fact' do
    it 'returns a cat fact when the request is successful' do
      allow(Faraday).to receive(:get).and_return(double(success?: true, body: '{"fact":"Cats are great!"}'))

      get :cat_fact

      expect(response.body).to eq('Cats are great!')
    end

    it 'returns an error when the request is unsuccessful' do
      allow(Faraday).to receive(:get).and_return(double(success?: false, status: 500))

      get :cat_fact

      expect(response.body).to eq('Error: 500')
    end

    it 'returns an error when the connection fails' do
      allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed.new('Connection failed'))

      get :cat_fact

      expect(response.body).to eq('Error: Connection failed')
    end
  end
end
