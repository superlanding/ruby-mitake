module Mitake
  class API
    cattr_accessor :username, :password, :debug, :logger

    # if Setting.mitake.present?
    #   self.username = (Setting.mitake.username || '')
    #   self.password = (Setting.mitake.password || '')
    #   self.debug = (Setting.mitake.debug || false)
    #   self.logger = (Setting.mitake.logger || false)
    # end

    DOMAIN = 'http://smexpress.mitake.com.tw:9600'
    GET_PATH = '/SmSendGet.asp'
    POST_PATH = '/SmSendPost.asp'

    CREDIT_FETCH_PATH = '/SmQueryGet.asp'

    class << self

      # 查詢點數餘額
      def fetch_credit!
        uri = api_uri(CREDIT_FETCH_PATH)
        request = Net::HTTP::Get.new(uri)
        http = Net::HTTP.new(request.uri.host, request.uri.port)
        response = http.request(request)
        tmp_result = response.body.split('=')
        unless tmp_result.first == 'AccountPoint'
          raise "API Fetch Faild!"
        end
        tmp_result.last.to_i
      end

      def api_uri(path)
        uri = URI("#{DOMAIN}#{path}")
        uri.query = URI.encode_www_form(auth_params)
        uri
      end

      # 送出簡訊 Examples:
      #   Mitake::API.send('09xxxxxxxx')
      #   Mitake::API.send(['09xxxxxxxx', '09xxxxxxxx', '09xxxxxxxx'])
      def send_single_or_bulk!(numbers, message)
        if debug
          log("Sending => [#{numbers}] => #{message}")
        end

        case numbers
        when Array
          if numbers.length == 1
            request = single_message_request(numbers.first, message)
          else
            request = bulk_message_request(numbers, message)
          end
        when String
          request = single_message_request(numbers, message)
        else
          return raise "Numbers Must Be Array or String"
        end
        http = Net::HTTP.new(request.uri.host, request.uri.port)
        response = http.request(request)
        response
      end

      def log(message)
        if logger
          Rails.logger.info("Mitake::API => #{message}")
        end
      end

      # API 帳號密碼 parameters
      def auth_params
        { username: username, password: password, encoding: 'UTF8' }
      end

      # 陣列則用一次性 POST
      def bulk_message_request(numbers, message)
        log("Bulk Sending => [#{numbers.to_json}] => #{message}")
        request = Net::HTTP::Post.new(bulk_api_uri)

        post_data = bluk_messages_post_data(numbers, message)

        request.body = post_data
        request.content_length = post_data.length
        request.content_type = 'text/xml'
        return request
      end

      # 單比發送使用 GET API
      def single_message_request(number, message)
        log("Single Sending => [#{number}] => #{message}")
        uri = single_api_uri(number, message)
        request = Net::HTTP::Get.new(uri)
        return request
      end

      # 多筆發送 URI generator
      def bulk_api_uri
        uri = URI("#{DOMAIN}#{POST_PATH}")
        uri.query = URI.encode_www_form(auth_params)
        return uri
      end

      # 單筆發送 URI generator
      def single_api_uri(number, message)
        params = auth_params.merge(dstaddr: number, smbody: hack_message_encode(message))
        query_string = CGI.unescape(params.to_query)
        return URI("#{DOMAIN}#{GET_PATH}?#{query_string}")
      end

      # 三竹設計有問題的 hack 法
      def hack_message_encode(message)
        CGI.escape(message).gsub('+', '%20')
      end

      # 多筆發送 POST Data 格式產生
      def bluk_messages_post_data(numbers, message)
        data = %w()
        numbers.each_with_index do |number, index|
          data.push "[#{index}]\r\n"
          data.push "dstaddr=#{number}\r\n"
          data.push "smbody=#{message}\r\n"
        end
        return data.join('')
      end
    end
  end
end