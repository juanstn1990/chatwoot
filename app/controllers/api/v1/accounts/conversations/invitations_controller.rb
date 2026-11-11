# Las invitaciones (Invita) vistas desde una conversacion: crear una partiendo
# de otra, enlazar una que ya existe, y pasar a limpio lo que el cliente pidio.
#
# Es un puente. La logica vive en Invita; aqui solo se anade lo que Chatwoot
# sabe y Invita no: quien es el agente, cual es la conversacion y que se dijo.
class Api::V1::Accounts::Conversations::InvitationsController < Api::V1::Accounts::Conversations::BaseController
  MESSAGE_LIMIT = 400

  before_action :ensure_linked, only: [:propose, :apply]
  rescue_from Invita::Client::Error, with: :render_invita_error

  def index
    render json: client.get('invitaciones', link_params)
  end

  # De que se puede partir: muestras del catalogo, plantillas y disenos.
  def sources
    render json: client.get('origenes', buscar: params[:q].presence)
  end

  # Para enlazar una que ya existe.
  def search
    render json: client.get('invitaciones', buscar: params[:q].to_s)
  end

  def create
    result = client.post(
      'invitaciones',
      link_params.merge(
        titulo: params[:title].to_s,
        origen: { tipo: params.dig(:origin, :type), id: params.dig(:origin, :id) }
      )
    )
    private_note("Invitación creada: #{result.dig('invitacion', 'titulo')} (parte de #{result['parteDe']})\n#{result.dig('invitacion', 'editor')}")
    render json: result, status: :created
  end

  def link
    result = client.put("invitaciones/#{invitation_id}/vinculo", link_params.merge(mover: params[:move].present?))
    render json: result
  end

  def unlink
    ensure_linked
    return if performed?

    render json: client.delete("invitaciones/#{invitation_id}/vinculo")
  end

  def propose
    render json: client.post(
      "invitaciones/#{invitation_id}/proponer",
      { mensajes: transcript, todo: params[:all].present?, nota: params[:note].to_s },
      slow: true
    )
  end

  def apply
    changes = Array(params[:changes]).map do |change|
      { seccion: change[:section], campo: change[:field], valor: change[:value], etiqueta: change[:label] }
    end
    result = client.post(
      "invitaciones/#{invitation_id}/aplicar",
      { cambios: changes.map { |change| change.except(:etiqueta) }, hasta: params[:until], reabrir: params[:reopen].present? }
    )
    note_applied(changes, result) if changes.any?
    render json: result
  end

  private

  def client
    @client ||= Invita::Client.new
  end

  def invitation_id
    # Solo el id: va dentro de la ruta que se le pide a Invita.
    params[:id].to_s.gsub(/[^A-Za-z0-9_-]/, '')
  end

  def link_params
    {
      cuenta: Current.account.id,
      conversacion: @conversation.display_id,
      contacto: @conversation.contact_id,
      telefono: @conversation.contact&.phone_number
    }
  end

  # Un agente con acceso a esta conversacion no debe poder escribir en la
  # invitacion de otra: solo se toca la que esta enlazada aqui.
  def ensure_linked
    linked = client.get('invitaciones', link_params).fetch('invitaciones', [])
    return if linked.any? { |invitation| invitation['id'] == invitation_id }

    render json: { error: 'Esa invitación no está enlazada a esta conversación.' }, status: :forbidden
  end

  # La conversacion tal como la necesita Invita. Las notas privadas van
  # tambien: es donde el agente apunta lo que se hablo por telefono.
  def transcript
    @conversation.messages
                 .where.not(message_type: :activity)
                 .includes(:attachments)
                 .reorder(id: :desc).limit(MESSAGE_LIMIT).to_a.reverse
                 .map do |message|
      {
        id: message.id,
        de: author_of(message),
        fecha: message.created_at.iso8601,
        texto: message.content.to_s,
        adjuntos: message.attachments.map { |attachment| { tipo: attachment.file_type } }
      }
    end
  end

  def author_of(message)
    return 'nota' if message.private?

    message.incoming? ? 'cliente' : 'agente'
  end

  def note_applied(changes, result)
    lines = changes.map do |change|
      "• #{change[:etiqueta].presence || "#{change[:seccion]}.#{change[:campo]}"} → #{change[:valor].to_s.truncate(120)}"
    end
    private_note("Cambios aplicados a «#{result.dig('invitacion', 'titulo')}»:\n#{lines.join("\n")}\n#{result['ver']}")
  end

  def private_note(content)
    Messages::MessageBuilder.new(Current.user, @conversation, { content: content, private: true }).perform
  rescue StandardError => e
    # La nota es un registro; que falle no debe deshacer lo que ya se escribio.
    Rails.logger.warn("Invita: no se pudo dejar la nota privada: #{e.message}")
  end

  def render_invita_error(error)
    status = error.status.to_i.between?(400, 599) ? error.status.to_i : 502
    # Un 401 de Invita es una llave mal puesta, no una sesion caducada del
    # agente: con 401 el panel lo mandaria a iniciar sesion.
    status = 502 if status == 401
    render json: error.body.merge('error' => error.message), status: status
  end
end
