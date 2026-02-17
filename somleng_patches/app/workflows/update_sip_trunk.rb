class UpdateSIPTrunk < ApplicationWorkflow
  attr_reader :sip_trunk, :call_service_client, :switch_host

  delegate :region, :username, :password, :previous_changes, to: :sip_trunk

  def initialize(sip_trunk, **options)
    @sip_trunk = sip_trunk
    @call_service_client = options.fetch(:call_service_client) { CallService::Client.new }
    @switch_host = options.fetch(:switch_host) { Rails.configuration.app_settings.fetch(:call_service_default_host) }
  end

  def call
    if authentication_mode_changed?
      handle_authentication_mode_change
    elsif sip_trunk.authentication_mode.outbound_registration?
      recreate_gateway if gateway_params_changed?
    elsif sip_trunk.authentication_mode.client_credentials?
      update_subscriber if attribute_changed?(:username)
    end
  end

  private

  def handle_authentication_mode_change
    old_mode = previous_changes[:authentication_mode]&.first

    # Clean up old mode
    case old_mode
    when "client_credentials"
      old_username = previous_changes[:username]&.first
      call_service_client.delete_subscriber(username: old_username) if old_username.present?
    when "outbound_registration"
      delete_gateway
    end

    # Set up new mode
    if sip_trunk.authentication_mode.outbound_registration?
      create_gateway
    elsif sip_trunk.authentication_mode.client_credentials? && username.present?
      call_service_client.create_subscriber(username:, password:)
    end
  end

  def gateway_params_changed?
    %i[username password outbound_host].any? { |attr| attribute_changed?(attr) }
  end

  def recreate_gateway
    delete_gateway
    create_gateway
  end

  def create_gateway
    host, port = parse_host_and_port(sip_trunk.outbound_host)

    connection = Faraday.new(url: switch_host)
    connection.post("/gateways") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        name: sip_trunk.id,
        username: username,
        password: password,
        realm: host,
        proxy: port ? "#{host}:#{port}" : host
      }.to_json
    end
  end

  def delete_gateway
    connection = Faraday.new(url: switch_host)
    connection.delete("/gateways/#{sip_trunk.id}")
  end

  def update_subscriber
    previous_username = previous_changes[:username].first
    call_service_client.delete_subscriber(username: previous_username) if previous_username.present?
    call_service_client.create_subscriber(username:, password:) if username.present?
  end

  def authentication_mode_changed?
    attribute_changed?(:authentication_mode)
  end

  def attribute_changed?(attribute)
    previous_value, new_value = previous_changes[attribute]
    previous_value != new_value
  end

  def parse_host_and_port(host_string)
    return [nil, nil] if host_string.blank?

    parts = host_string.split(":")
    [parts[0], parts[1]]
  end
end
