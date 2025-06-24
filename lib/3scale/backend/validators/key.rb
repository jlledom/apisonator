module ThreeScale
  module Backend
    module Validators
      class Key < Base
        def apply
          case service.backend_version.to_i
          when 1 # Auth by user_key
            return succeed! if params.has_key?(:user_key)

            fail!(UserKeyInvalid.new(params[:user_key]))
          when 2, 0  # 2 -> Auth by app_id. 0 -> not defined or invalid, must behave like 2
            return succeed! if params.has_key?(:app_id) && (application.has_no_keys? || application.has_key?(params[:app_key]))

            fail!(ApplicationKeyInvalid.new(params[:app_key]))
          else
            # This should never happen
            fail!(Error.new("Invalid backend version: #{service.backend_version.to_i}"))
          end
        end
      end
    end
  end
end
