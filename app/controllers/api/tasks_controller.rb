class Api::TasksController < ApplicationController
  # POST /api/tasks
  def create
    task = Task.new(create_params)

    response = if task.save
                 handle_success_response('Succesfully created task!')
               else
                 handle_error_response(task)
               end

    render json: response
  end

  # PUT /api/tasks/{taskId}
  def update
    task = Task.find(params[:id])

    response = if task.update_attributes(update_params)
                 handle_success_response('Succesfully updated task!')
               else
                 handle_error_response(task)
               end

    render json: response
  end

  # DELETE /api/tasks/{taskId}
  def destroy
    task = Task.find(params[:id])

    response = if task.destroy
                 handle_success_response('Succesfully deleted task!')
               else
                 handle_error_response(task)
               end

    render json: response
  end

  # GET /api/tasks
  def index
    tasks = Task.all
    render json: tasks
  end

  # POST /api/tasks/{taskId}/assign
  def assign
    task = Task.where(id: params[:id]).first
    render json: handle_error_response('Task not found') and return if task.blank?

    user = User.where(id: params[:user_id]).first
    render json: handle_error_response('User not found') and return if user.blank?

    response = if task.update_attributes(user_id: user.id)
                 handle_success_response('Succesfully assigned task!')
               else
                 handle_error_response(task)
               end

    render json: response
  end

  # PUT /api/tasks/{taskId}/set_progress
  def set_progress
    task = Task.find(params[:id])

    response = if task.update_attributes(progress_pct: params[:progress_pct].to_f)
                 handle_success_response('Succesfully set progress for task!')
               else
                 handle_error_response(task)
               end

    render json: response
  end

  # GET /api/tasks/overdue
  def overdue
    tasks = Task.where(:due_date.lt => Date.today)

    render json: tasks.only(:id, :title, :due_date)
  end

  # GET /api/tasks/status
  def status
    render json: handle_error_response('missing status key') and return if params[:status].blank?

    tasks = Task.where(status: params[:status])
    render json: tasks
  end

  # GET /api/tasks/completed
  def completed
    if params[:start_date].blank? || params[:end_date].blank?
      render json: handle_error_response('missing start/end date') and return
    end

    tasks = Task.completed.where('completed_on': { "$gte": params[:start_date], "$lte": params[:end_date] })
    render json: tasks
  end

  # GET /api/tasks/statistics
  def statistics
    tasks = Task.all

    total_count = tasks.count
    completed_count = tasks.completed.count

    render json: {
      total_tasks: total_count,
      total_completed_tasks: completed_count,
      completed_tasks_pct: completed_count / total_count
    }
  end

  # GET /api/tasks/task_queue
  def task_queue
    render json: (Task.high_tasks + Task.medium_tasks + Task.low_tasks)
  end

  private

  def create_params
    params.require(:task).permit(:title, :description, :due_date, :priority)
  end

  def update_params
    task_params = params.require(:task)
    task_params[:completed_on] = Date.today if task_params[:status] == 'completed'

    task_params.permit(:title, :description, :due_date, :status, :priority, :completed_on)
  end

  def handle_success_response(message)
    { status: 'success', message: message }
  end

  def handle_error_response(entity)
    message = entity.is_a?(Task) ? entity.errors.full_messages.join(', ') : entity

    { status: 'error', message: message }
  end
end
