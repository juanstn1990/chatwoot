# Habla con la app de invitaciones (Invita) por sus rutas `/api/chatwoot/*`.
#
# Es el servidor de Chatwoot el que llama, con una llave que vive solo aqui:
# el navegador del agente nunca la ve. Apagado mientras no existan
# INVITA_URL e INVITA_TOKEN.
class Invita::Client
  include HTTParty

  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: 502, body: {})
      super(message)
      @status = status
      @body = body
    end
  end

  # Leer una conversacion larga con el modelo tarda; el resto es inmediato.
  TIMEOUT = 20
  SLOW_TIMEOUT = 150

  def self.configured?
    ENV['INVITA_URL'].present? && ENV['INVITA_TOKEN'].present?
  end

  def get(path, query = {})
    request(:get, path, query: query.compact)
  end

  def post(path, body = {}, slow: false)
    request(:post, path, body: body.to_json, timeout: slow ? SLOW_TIMEOUT : TIMEOUT)
  end

  def put(path, body = {})
    request(:put, path, body: body.to_json)
  end

  def delete(path)
    request(:delete, path)
  end

  private

  def request(method, path, options = {})
    raise Error.new('La integracion con Invita no esta configurada (INVITA_URL / INVITA_TOKEN).', status: 503) unless self.class.configured?

    response = self.class.send(
      method,
      "#{ENV.fetch('INVITA_URL').chomp('/')}/api/chatwoot/#{path}",
      { headers: headers, timeout: TIMEOUT }.merge(options)
    )
    body = parse(response)
    return body if response.success?

    raise Error.new(body['error'].presence || "Invita respondio #{response.code}", status: response.code, body: body)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    raise Error.new("No se pudo hablar con Invita: #{e.message}", status: 502)
  end

  def headers
    { 'Authorization' => "Bearer #{ENV.fetch('INVITA_TOKEN')}", 'Content-Type' => 'application/json' }
  end

  def parse(response)
    parsed = response.parsed_response
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end
end
