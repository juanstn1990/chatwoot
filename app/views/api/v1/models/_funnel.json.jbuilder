json.id funnel.id
json.name funnel.name
json.description funnel.description
json.currency funnel.currency
json.position funnel.position
json.account_id funnel.account_id

json.stages do
  json.array! funnel.funnel_stages do |stage|
    json.partial! 'api/v1/models/funnel_stage', formats: [:json], stage: stage
  end
end
