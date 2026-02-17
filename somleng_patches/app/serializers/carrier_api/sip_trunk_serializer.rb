module CarrierAPI
  class SIPTrunkSerializer < ResourceSerializer
    attributes :name, :authentication_mode, :region, :max_channels, :default_sender,
               :outbound_host, :outbound_proxy, :auth_user,
               :outbound_dial_string_prefix, :outbound_national_dialing,
               :outbound_plus_prefix, :outbound_route_prefixes

    attribute :inbound_country do |object|
      object.inbound_country_code
    end

    attribute :inbound_source_ips do |object|
      object.inbound_source_ips
    end

    attribute :username, if: proc { |record|
      record.authentication_mode.client_credentials? || record.authentication_mode.outbound_registration?
    }
    attribute :password, if: proc { |record|
      record.authentication_mode.client_credentials? || record.authentication_mode.outbound_registration?
    }
  end
end
