json.payload do
  json.array! @funnels do |funnel|
    json.partial! 'api/v1/models/funnel', formats: [:json], funnel: funnel
  end
end
