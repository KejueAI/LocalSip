require "fileutils"
require "socket"

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

        freeswitch_command("sofia profile nat_gateway rescan")

        status 201
        json(name: name, status: "created")
      end

      delete "/gateways/:name" do
        name = params[:name]
        file_path = File.join(GATEWAY_DIR, "#{name}.xml")

        if File.exist?(file_path)
          File.delete(file_path)
          freeswitch_command("sofia profile nat_gateway killgw #{name}")
        end

        status 204
      end

      private

      def freeswitch_command(command)
        socket = TCPSocket.new(FS_ESL_HOST, FS_ESL_PORT)
        # Read auth request
        socket.gets until socket.gets&.strip&.empty?
        # Authenticate
        socket.write("auth #{FS_ESL_PASSWORD}\n\n")
        socket.gets until socket.gets&.strip&.empty?
        # Send command
        socket.write("api #{command}\n\n")
        # Read response
        response = ""
        while (line = socket.gets)
          break if line.strip.empty? && response.include?("Content-Length")
          response += line
        end
        if response.include?("Content-Length")
          content_length = response.match(/Content-Length: (\d+)/)[1].to_i
          result = socket.read(content_length)
          logger.info("FreeSWITCH response: #{result.strip}")
        end
        socket.close
      rescue => e
        logger.warn("FreeSWITCH ESL command failed: #{e.message}")
      ensure
        socket&.close rescue nil
      end
    end
  end
end
