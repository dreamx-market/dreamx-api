class MarketChartDataRelayJob < ApplicationJob
  queue_as :default

  def perform(chart_datum)
    locals = { channel: 'MarketChartData', payload: [chart_datum] }
    json = JSON.parse(ApplicationController.render('chart_data/socket', locals: locals))
    ActionCable.server.broadcast("market_chart_data:#{chart_datum.market_symbol}:#{chart_datum.period}", json)
  end
end
