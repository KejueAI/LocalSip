module CarrierAPI
  module V1
    class SIPTrunksController < CarrierAPIController
      def index
        respond_with_resource(scope, serializer_options)
      end

      def create
        validate_request_schema(
          with: SIPTrunkRequestSchema, **serializer_options
        ) do |permitted_params|
          sip_trunk = scope.create!(permitted_params)
          CreateSIPTrunk.call(sip_trunk)
          sip_trunk
        end
      end

      def show
        sip_trunk = find_sip_trunk
        respond_with_resource(sip_trunk, serializer_options)
      end

      def update
        sip_trunk = find_sip_trunk

        validate_request_schema(
          with: UpdateSIPTrunkRequestSchema,
          schema_options: { resource: sip_trunk },
          **serializer_options
        ) do |permitted_params|
          sip_trunk.update!(permitted_params)
          UpdateSIPTrunk.call(sip_trunk)
          sip_trunk
        end
      end

      def destroy
        sip_trunk = find_sip_trunk
        DeleteSIPTrunk.call(sip_trunk) if sip_trunk.destroy
        respond_with_resource(sip_trunk)
      end

      private

      def scope
        current_carrier.sip_trunks
      end

      def find_sip_trunk
        scope.find(params[:id])
      end

      def serializer_options
        { serializer_class: SIPTrunkSerializer }
      end
    end
  end
end
