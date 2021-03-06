FactoryBot.define do
  factory :chart_datum do
    market
    market_symbol { "ETH_ONE" }
    high { "0.03149999" }
    low { "0.031" }
    open { "0.03144307" }
    close { "0.03124064" }
    volume { "64.36480422" }
    quote_volume { "2055.56810329" }
    average { "0.03131241" }
    period { 1.hour }
    created_at { Time.now }

    trait :expired do
      created_at { 91.days.ago }
    end
  end
end
