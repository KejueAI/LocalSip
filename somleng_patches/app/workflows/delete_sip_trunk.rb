class DeleteSIPTrunk < ApplicationWorkflow
  attr_reader :sip_trunk, :call_service_client, :switch_host

  delegate :username, to: :sip_trunk

  def initialize(sip_trunk, **options)
    @sip_trunk = sip_trunk
    @call_service_client = options.fetch(:call_service_client) { CallService::Client.new }
    @switch_host = options.fetch(:switch_host) { Rails.configuration.app_settings.fetch(:call_service_default_host) }
  end

  def call
    if sip_trunk.authentication_mode.outbound_registration?
      delete_gateway
    elsif username.present?
      delete_subscriber
    end
  end

  private

  def delete_subscriber
    call_service_client.delete_subscriber(username:)
  end

  def delete_gateway
    connection = Faraday.new(url: switch_host)
    connection.delete("/gateways/#{sip_trunk.id}")
  end
end
