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
    %i[username password outbound_host outbound_proxy auth_user].any? { |attr| attribute_changed?(attr) }
  end

  def recreate_gateway
    delete_gateway
    create_gateway
  end

  def create_gateway
    host, port = parse_host_and_port(sip_trunk.outbound_host)
    realm = host
    register_proxy = port ? "#{host}:#{port}" : host

    if sip_trunk.outbound_proxy.present?
      ob_host, ob_port = parse_host_and_port(sip_trunk.outbound_proxy)
      network_proxy = ob_port ? "#{ob_host}:#{ob_port}" : ob_host
    else
      network_proxy = register_proxy
    end

    connection = switch_connection
    connection.post("/gateways") do |req|
      req.headers["Content-Type"] = "application/json"
      body = {
        name: sip_trunk.id,
        username: username,
        password: password,
        realm: realm,
        proxy: network_proxy,
        outbound_proxy: network_proxy
      }
      body[:auth_username] = sip_trunk.auth_user if sip_trunk.auth_user.present?
      req.body = body.to_json
    end
  end

  def delete_gateway
    switch_connection.delete("/gateways/#{sip_trunk.id}")
  end

  def switch_connection
    Faraday.new(url: switch_host) do |f|
      f.request :authorization, :basic, CallService.configuration.username, CallService.configuration.password
    end
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
