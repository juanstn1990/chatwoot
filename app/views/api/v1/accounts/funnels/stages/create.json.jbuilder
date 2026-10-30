json.payload do
  json.partial! 'api/v1/models/funnel_stage', formats: [:json], stage: @stage
end
