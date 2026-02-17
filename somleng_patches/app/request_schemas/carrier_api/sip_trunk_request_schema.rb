require "resolv"

module CarrierAPI
  class SIPTrunkRequestSchema < CarrierAPIRequestSchema
    params do
      required(:data).value(:hash).schema do
        required(:type).filled(:str?, eql?: "sip_trunk")
        required(:attributes).value(:hash).schema do
          required(:name).filled(:str?)
          required(:authentication_mode).filled(:str?, included_in?: SIPTrunk.authentication_mode.values)
          required(:region).filled(:str?)
          optional(:max_channels).filled(:int?, gt?: 0)
          optional(:inbound_country).filled(:str?, included_in?: ISO3166::Country.all.map(&:alpha2))
          optional(:inbound_source_ips).each(:str?)
          optional(:default_sender).filled(:str?)
          optional(:username).filled(:str?)
          optional(:password).filled(:str?)
          optional(:outbound_host).filled(:str?)
          optional(:outbound_proxy).maybe(:str?)
          optional(:auth_user).maybe(:str?)
          optional(:outbound_dial_string_prefix).filled(:str?)
          optional(:outbound_national_dialing).filled(:bool?)
          optional(:outbound_plus_prefix).filled(:bool?)
          optional(:outbound_route_prefixes).each(:str?)
        end
      end
    end

    attribute_rule(:username) do |attributes|
      if attributes[:authentication_mode] == "outbound_registration" && !key?
        key.failure("is required for outbound_registration mode")
      end
    end

    attribute_rule(:password) do |attributes|
      if attributes[:authentication_mode] == "outbound_registration" && !key?
        key.failure("is required for outbound_registration mode")
      end
    end

    attribute_rule(:outbound_host) do |attributes|
      if attributes[:authentication_mode] == "outbound_registration" && !key?
        key.failure("is required for outbound_registration mode")
      end
    end

    attribute_rule(:region) do
      if key?
        region = SomlengRegion::Region.find_by(alias: value)
        key.failure("is invalid") if region.nil?
      end
    end

    attribute_rule(:inbound_source_ips) do
      next unless key?

      Array(value).each do |ip|
        unless Resolv::IPv4::Regex.match?(ip)
          key.failure("contains invalid IP address: #{ip}")
          break
        end
      end
    end

    def output
      params = super
      result = {}
      result[:carrier] = params.fetch(:carrier)
      result[:name] = params.fetch(:name)
      result[:authentication_mode] = params.fetch(:authentication_mode)
      result[:region] = params.fetch(:region)
      result[:max_channels] = params.fetch(:max_channels) if params.key?(:max_channels)
      result[:inbound_country_code] = params.fetch(:inbound_country) if params.key?(:inbound_country)
      result[:inbound_source_ips] = params.fetch(:inbound_source_ips) if params.key?(:inbound_source_ips)
      result[:default_sender] = params.fetch(:default_sender) if params.key?(:default_sender)
      result[:username] = params.fetch(:username) if params.key?(:username)
      result[:password] = params.fetch(:password) if params.key?(:password)
      result[:outbound_host] = params.fetch(:outbound_host) if params.key?(:outbound_host)
      result[:outbound_proxy] = params.fetch(:outbound_proxy) if params.key?(:outbound_proxy)
      if params.fetch(:authentication_mode) == "outbound_registration"
        result[:auth_user] = params.key?(:auth_user) && params[:auth_user].present? ? params[:auth_user] : params[:username]
      end
      result[:outbound_dial_string_prefix] = params.fetch(:outbound_dial_string_prefix) if params.key?(:outbound_dial_string_prefix)
      result[:outbound_national_dialing] = params.fetch(:outbound_national_dialing) if params.key?(:outbound_national_dialing)
      result[:outbound_plus_prefix] = params.fetch(:outbound_plus_prefix) if params.key?(:outbound_plus_prefix)
      result[:outbound_route_prefixes] = params.fetch(:outbound_route_prefixes) if params.key?(:outbound_route_prefixes)
      result
    end

  end
end
