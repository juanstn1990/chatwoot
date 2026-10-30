json.id opportunity.id
json.name opportunity.name
json.description opportunity.description
json.value opportunity.value
json.status opportunity.status
json.position opportunity.position
json.expected_close_on opportunity.expected_close_on
json.account_id opportunity.account_id
json.funnel_id opportunity.funnel_id
json.funnel_stage_id opportunity.funnel_stage_id
json.funnel_stage_name opportunity.funnel_stage.name
json.currency opportunity.funnel.currency
json.conversation_display_id opportunity.conversation_to_resume&.display_id

if opportunity.contact.present?
  json.contact do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: opportunity.contact
  end
end

if opportunity.assignee.present?
  json.assignee do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: opportunity.assignee
  end
end
