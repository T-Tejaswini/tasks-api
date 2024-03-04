class Task
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :due_date, type: Date
  field :completed_on, type: Date
  field :progress_pct, type: Float, default: 0.0
  field :status, type: String, default: 'initial'
  field :priority, type: String, default: 'medium'

  STATUS_KINDS = %w[initial completed]
  PRIORITY_KINDS = %w[low medium high]

  belongs_to :user, optional: true

  validates_presence_of :title, :description, :due_date
  validate :ensure_progress_pct_valid
  validates :status, inclusion: { in: STATUS_KINDS, message: '%{value} is not a valid status' }
  validates :priority, inclusion: { in: PRIORITY_KINDS, message: '%{value} is not a valid status' }

  index({ completed_on: 1 })
  index({ status: 1 })
  index({ due_date: 1 })

  scope :completed, -> { where(status: 'completed') }
  scope :high_tasks, -> { where(priority: 'high').order_by(:due_date.asc) }
  scope :medium_tasks, -> { where(priority: 'medium').order_by(:due_date.asc) }
  scope :low_tasks, -> { where(priority: 'low').order_by(:due_date.asc) }

  private

  def ensure_progress_pct_valid
    errors.add(:base, 'progress % should be in between 0 and 100') if progress_pct < 0 || progress_pct > 100
  end
end
