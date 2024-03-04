Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :tasks do
      member do
        post :assign
        put :set_progress
      end

      collection do
        get :overdue
        get :status
        get :completed
        get :statistics
        get :task_queue
      end
    end

    resources :users, only: [] do
      member do
        get :tasks
      end
    end
  end
end
