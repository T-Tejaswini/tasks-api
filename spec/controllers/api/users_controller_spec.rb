# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller, dbclean: :after_each do
  describe '#tasks' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:task) { FactoryBot.create(:task, user: user) }

    context 'with invalid user id' do
      it 'raises error' do
        expect do
          get :tasks, params: { id: 'abc' }
        end.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'with valid user id' do
      before do
        get :tasks, params: { id: user.id }
      end
      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).present?).to eq true
      end
    end
  end
end
