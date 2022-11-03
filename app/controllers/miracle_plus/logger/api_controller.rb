# frozen_string_literal: true

module MiraclePlus
  module Logger
    class ApiController < ActionController::API
      include Concerns::Authentication

      def index
        page = (params['page'] || '1').to_i
        per = (params['per'] || '15').to_i
        render json: { entries: Entry.list(page: page, per: per) }
      end

      def show
        payload = target.get(params.require('id'))
        render json: { entry: payload }
      end

      def create
        res = target.persist(params.permit(permitted_attributes))
        render json: { error: res.in?([true, false]) ? !res : res }
      end

      def update
        id = params.require(:id)
        parameters = params.permit(permitted_attributes)
        res = target(id).persist(parameters)
        render json: { error: res.in?([true, false]) ? !res : res }
      end

      def destroy
        success = target(params.require(:id)).destroy
        render json: { error: !success }
      end

      private

      def permitted_attributes
        [:name, { statements: %i[class variable code method] }]
      end

      def request_ip
        request.remote_ip
      end

      def target(id = nil)
        @target ||= Entry.new(request_ip, id)
      end
    end
  end
end
