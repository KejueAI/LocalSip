require "fileutils"
require "socket"
require "timeout"

GATEWAY_DIR = ENV.fetch("SIP_GATEWAY_DIR", "/sip_gateways")
FS_ESL_HOST = ENV.fetch("FS_ESL_HOST", "freeswitch")
FS_ESL_PORT = ENV.fetch("FS_ESL_PORT", "8021").to_i
FS_ESL_PASSWORD = ENV.fetch("FS_ESL_PASSWORD", "secret")

module SomlengAdhearsion
  module Web
    class API < Application
      post "/gateways" do
        gateway_params = JSON.parse(request.body.read)

        name = gateway_params.fetch("name")
        username = gateway_params.fetch("username")
        password = gateway_params.fetch("password")
        realm = gateway_params.fetch("realm")
        proxy = gateway_params.fetch("proxy")

        gateway_xml = <<~XML
          <include>
            <gateway name="#{name}">
              <param name="username" value="#{username}"/>
              <param name="password" value="#{password}"/>
              <param name="realm" value="#{realm}"/>
              <param name="proxy" value="#{proxy}"/>
              <param name="register" value="true"/>
              <param name="register-transport" value="udp"/>
              <param name="expire-seconds" value="3600"/>
              <param name="retry-seconds" value="30"/>
            </gateway>
          </include>
        XML

        FileUtils.mkdir_p(GATEWAY_DIR)
        File.write(File.join(GATEWAY_DIR, "#{name}.xml"), gateway_xml)

        # Trigger rescan in background thread so it doesn't block the response
        Thread.new do
          freeswitch_command("sofia profile nat_gateway rescan")
        end

        status 201
        json(name: name, status: "created")
      end

      delete "/gateways/:name" do
        name = params[:name]
        file_path = File.join(GATEWAY_DIR, "#{name}.xml")

        if File.exist?(file_path)
          File.delete(file_path)
          Thread.new do
            freeswitch_command("sofia profile nat_gateway killgw #{name}")
          end
        end

        status 204
      end

      private

      def freeswitch_command(command)
        Timeout.timeout(5) do
          socket = TCPSocket.new(FS_ESL_HOST, FS_ESL_PORT)
          # Read until we get Content-Type header block
          read_until_blank_line(socket)
          # Authenticate
          socket.write("auth #{FS_ESL_PASSWORD}\n\n")
          read_until_blank_line(socket)
          # Send command
          socket.write("api #{command}\n\n")
          # Read response headers
          headers = read_until_blank_line(socket)
          if headers.include?("Content-Length")
            content_length = headers.match(/Content-Length:\s*(\d+)/)[1].to_i
            result = socket.read(content_length)
            logger.info("FreeSWITCH response: #{result.strip}")
          end
          socket.close
        end
      rescue => e
        logger.warn("FreeSWITCH ESL command failed: #{e.class}: #{e.message}")
      end

      def read_until_blank_line(socket)
        lines = ""
        while (line = socket.gets)
          lines += line
          break if line.strip.empty?
        end
        lines
      end
    end
  end
end
