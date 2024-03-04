FactoryBot.define do
  factory :user do
    name { "name #{rand(1..100)}" }
  end
end
