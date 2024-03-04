FactoryBot.define do
  factory :task do
    title { "task #{rand(1..100)}" }
    description { 'desc' }
    due_date { Date.today + 3.months }

    trait :overdue do
      due_date { Date.today - 1.month }
    end
  end
end
