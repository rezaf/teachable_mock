require 'net/http'
require 'json'

class TeachableMock
  attr_reader :host, :token, :email

  # Takes host address e.g.: https://fast-bayou-75985.herokuapp.com
  def initialize(host = 'localhost:3000')
    @host = host
  end

  # Authenticates user with email and password. Logs in user.
  def authenticate_user(email, password)
    uri = URI.join(@host, 'users/sign_in.json')
    data = { user: { email: email, password: password } }.to_json

    res = Net::HTTP.post(uri, data, 'Content-Type' => 'application/json')

    if res.is_a?(Net::HTTPSuccess)
      @token = JSON.parse(res.body)['tokens']
      @email = email
      puts "\nAuthentication successful!\n\n"
      puts res.body
    else
      raise "Authentication not successful! Response code: #{res.code}"
    end
  end

  # Creates new user. Logs in user.
  def register_user(email, password, password_confirmation)
    uri = URI.join(@host, 'users.json')
    data = {
      user: {
        email: email,
        password: password,
        password_confirmation: password_confirmation
      }
    }.to_json

    res = Net::HTTP.post(uri, data, 'Content-Type' => 'application/json')

    if res.is_a?(Net::HTTPCreated)
      @token = JSON.parse(res.body)['tokens']
      @email = email
      puts "\nRegistration successful!\n\n"
      puts res.body
    else
      raise "Registration not successful! Response code: #{res.code}"
    end
  end

  # Prints current logged in user's info.
  def current_user
    uri = URI.join(@host, 'api/users/current_user/edit.json')
    uri.query = URI.encode_www_form({ user_email: @email, user_token: @token })

    res = Net::HTTP.get_response(uri)

    puts res.body
  end

  # Prints current user's orders
  def current_user_orders
    uri = URI.join(@host, 'api/orders.json')
    uri.query = URI.encode_www_form({ user_email: @email, user_token: @token })

    res = Net::HTTP.get_response(uri)

    puts res.body
  end

  # Creates new order.
  def create_order(total, total_quantity, email, instructions = '')
    uri = URI.join(@host, 'api/orders.json')
    uri.query = URI.encode_www_form({ user_email: @email, user_token: @token })

    req = Net::HTTP::Post.new(uri)
    req.content_type='application/json'
    req.body = {
      order: {
        total: total,
        total_quantity: total_quantity,
        email: email,
        special_instructions: instructions
      }
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPOK)
      puts "Order number #{JSON.parse(res.body)['id']} created!"
    else
      puts res.body
    end
  end

  # Destroys order with given order ID.
  def destroy_order!(order_id)
    uri = URI.join(@host, "api/orders/#{order_id}.json")
    uri.query = URI.encode_www_form({ user_email: @email, user_token: @token })

    req = Net::HTTP::Delete.new(uri)
    req.content_type='application/json'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPNoContent)
      puts "Order number #{order_id} deleted!"
    else
      puts res.body
    end
  end
end
