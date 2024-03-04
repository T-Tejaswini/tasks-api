# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::TasksController, type: :controller, dbclean: :after_each do
  let!(:task) { FactoryBot.build(:task) }

  describe '#create' do
    context 'with incorrect params' do
      it 'raises error' do
        expect do
          post :create, params: {}
        end.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'with missing params' do
      before do
        post :create, params: { task: { key: 'random' } }
      end

      it 'returns errors' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error',
                                                  'message' => "Title can't be blank, Description can't be blank, Due date can't be blank" })
      end
    end

    context 'with valid params' do
      before do
        post :create,
             params: { task: { title: 'task 24', description: 'desc', due_date: Date.today + 2.months } }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'success', 'message' => 'Succesfully created task!' })
      end
    end
  end

  describe '#update' do
    let(:task) { FactoryBot.create(:task) }

    context 'with invalid task id' do
      it 'raises error' do
        expect do
          put :update, params: { id: 'abc', task: { title: 'updated' } }
        end.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'with invalid params' do
      before do
        put :update, params: { id: task.id, task: { title: nil } }
      end

      it 'returns errors' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => "Title can't be blank" })
      end
    end

    context 'with valid params' do
      let(:params) do
        { id: task.id, task: { title: 'updated' } }
      end

      before do
        put :update, params: params
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'success', 'message' => 'Succesfully updated task!' })
      end

      context 'when status is completed' do
        let(:params) do
          { id: task.id, task: { title: 'updated', status: 'completed' } }
        end

        it 'sets completed on' do
          expect(task.reload.completed_on).to eq Date.today
        end
      end
    end
  end

  describe '#destroy' do
    context 'with invalid task id' do
      it 'raises error' do
        expect do
          delete :destroy, params: { id: 'abc' }
        end.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'with valid task id' do
      let(:task) { FactoryBot.create(:task) }

      before do
        delete :destroy, params: { id: task.id }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'success', 'message' => 'Succesfully deleted task!' })
      end
    end
  end

  describe '#index' do
    let(:task) { FactoryBot.create(:task) }

    before do
      get :index
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).present?).to eq true
    end
  end

  describe '#assign' do
    let(:task) { FactoryBot.create(:task) }
    let(:user) { FactoryBot.create(:user) }

    before do
      post :assign, params: { id: task_id, user_id: user_id }
    end

    context 'when task not found' do
      let(:task_id) { 'abc' }
      let(:user_id) { user.id }

      it 'returns error response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => 'Task not found' })
      end
    end

    context 'when user not found' do
      let(:task_id) { task.id }
      let(:user_id) { 'abc' }

      it 'returns error response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => 'User not found' })
      end
    end

    context 'with valid attributes' do
      let(:task_id) { task.id }
      let(:user_id) { user.id }

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'success', 'message' => 'Succesfully assigned task!' })
      end
    end
  end

  describe '#set_progress' do
    let(:task) { FactoryBot.create(:task) }

    context 'with invalid task id' do
      it 'raises error' do
        expect do
          put :set_progress, params: { id: 'abc', progress_pct: 25 }
        end.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'when given progress_pct is invalid' do
      let(:task_id) { task.id }

      before do
        put :set_progress, params: { id: task.id, progress_pct: 120.0 }
      end

      it 'returns error response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error',
                                                  'message' => 'progress % should be in between 0 and 100' })
      end
    end

    context 'with valid attributes' do
      let(:task_id) { task.id }
      let(:user_id) { user.id }

      before do
        put :set_progress, params: { id: task.id, progress_pct: 15.0 }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'success',
                                                  'message' => 'Succesfully set progress for task!' })
      end
    end
  end

  describe '#overdue' do
    let!(:task1) { FactoryBot.create(:task, due_date: Date.today - 1.month) }
    let!(:task2) { FactoryBot.create(:task, due_date: Date.today + 1.month) }

    before do
      get :overdue
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq 1
    end
  end

  describe '#status' do
    let!(:task) { FactoryBot.create(:task) }

    before do
      get :status, params: { status: status }
    end

    context 'without status' do
      let(:status) { nil }

      it 'returns error response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => 'missing status key' })
      end
    end

    context 'with status' do
      let(:status) { 'initial' }

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to be_an_instance_of(Array)
      end
    end
  end

  describe '#completed' do
    let!(:task) { FactoryBot.create(:task) }

    before do
      get :completed, params: params
    end

    context 'without start / end dates' do
      let(:params) { {} }

      it 'returns error response' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'error', 'message' => 'missing start/end date' })
      end
    end

    context 'with start and end dates' do
      let(:params) do
        { start_date: (Date.today - 3.months), end_date: Date.today }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to be_an_instance_of(Array)
      end
    end
  end

  describe '#statistics' do
    let!(:task) { FactoryBot.create(:task) }
    let!(:task) { FactoryBot.create(:task, status: 'completed', completed_on: Date.today) }

    before do
      get :statistics
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).present?).to eq true
    end
  end

  describe '#task_queue' do
    let!(:low_task1) { FactoryBot.create(:task, priority: 'low', due_date: Date.today + 2.months) }
    let!(:low_task2) { FactoryBot.create(:task, priority: 'low', due_date: Date.today + 3.months) }
    let!(:med_task1) { FactoryBot.create(:task, priority: 'medium', due_date: Date.today + 2.months) }
    let!(:med_task2) { FactoryBot.create(:task, priority: 'medium', due_date: Date.today + 3.months) }
    let!(:high_task1) { FactoryBot.create(:task, priority: 'high', due_date: Date.today + 2.months) }
    let!(:high_task2) { FactoryBot.create(:task, priority: 'high', due_date: Date.today + 3.months) }

    let(:resp) do
      [
        [high_task1.priority, high_task1.due_date.to_s],
        [high_task2.priority, high_task2.due_date.to_s],
        [med_task1.priority, med_task1.due_date.to_s],
        [med_task2.priority, med_task2.due_date.to_s],
        [low_task1.priority, low_task1.due_date.to_s],
        [low_task2.priority, low_task2.due_date.to_s]
      ]
    end

    before do
      get :task_queue
    end

    it 'returns tasks based on priority and due date' do
      expect(JSON.parse(response.body).map { |task| [task['priority'], task['due_date']] }).to eq resp
    end
  end
end
