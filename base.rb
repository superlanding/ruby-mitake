module Mitake
  class Base
    class << self
      def define_message(message_name, message)
        # Message Template
        class_variable_set("@@#{message_name}".to_sym, message)

        define_singleton_method "send_#{message_name}" do |numbers, attrs={}|
          begin
            message_template = class_variable_get("@@#{message_name}".to_sym)
            replaced_message = replace_message_attrs(message_template, attrs)
            send_sms(numbers, replaced_message)
            return true
          rescue
            return false
          end
        end

        define_singleton_method "send_#{message_name}!" do |numbers, attrs={}|
          message_template = class_variable_get("@@#{message_name}".to_sym)
          replaced_message = replace_message_attrs(message, attrs)
          send_sms(numbers, replaced_message)
          return true
        end
      end

      def send_sms(numbers, message)
        ::Mitake::API.send_single_or_bulk!(numbers, message)
      end

      private
        def replace_message_attrs(send_message, attrs)
          attrs.each do |key, value|
            send_message = send_message.gsub("{#{key}}", value.to_s)
          end
          return send_message
        end
    end
  end
end