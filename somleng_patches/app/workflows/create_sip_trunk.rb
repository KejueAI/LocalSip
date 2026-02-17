class CreateSIPTrunk < ApplicationWorkflow
  attr_reader :sip_trunk, :call_service_client, :switch_host

  delegate :inbound_source_ips, :region, :username, :password, to: :sip_trunk

  def initialize(sip_trunk, **options)
    @sip_trunk = sip_trunk
    @call_service_client = options.fetch(:call_service_client) { CallService::Client.new }
    @switch_host = options.fetch(:switch_host) { Rails.configuration.app_settings.fetch(:call_service_default_host) }
  end

  def call
    if sip_trunk.authentication_mode.outbound_registration?
      create_gateway
    elsif username.present?
      create_subscriber
    end
  end

  private

  def create_subscriber
    call_service_client.create_subscriber(username:, password:)
  end

  def create_gateway
    host, port = parse_host_and_port(sip_trunk.outbound_host)

    connection = Faraday.new(url: switch_host) do |f|
      f.request :authorization, :basic, CallService.configuration.username, CallService.configuration.password
    end
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

  def parse_host_and_port(host_string)
    return [nil, nil] if host_string.blank?

    parts = host_string.split(":")
    [parts[0], parts[1]]
  end
end
