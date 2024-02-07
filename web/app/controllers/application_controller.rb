require 'faraday'
require 'json'

class ApplicationController < ActionController::Base
  def cat_fact
    url = 'https://catfact.ninja/fact'
    response = Faraday.get(url)

    if response.success?
      data = JSON.parse(response.body)
      render plain: data['fact']
    else
      render plain: "Error: #{response.status}"
    end
  rescue Faraday::ConnectionFailed => e
    render plain: "Error: #{e.message}"
  end
end
