json.payload do
  json.partial! 'api/v1/models/opportunity', formats: [:json], opportunity: @opportunity
end
