json.payload do
  json.partial! 'api/v1/models/funnel', formats: [:json], funnel: @funnel
end
