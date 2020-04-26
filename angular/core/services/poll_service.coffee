angular.module('loomioApp').factory 'PollService', (AppConfig, Records, PollProposalForm, PollEngagementForm) ->
  new class PollService

    # NB: this is an intersection of data and code that's a little uncomfortable at the moment.
    # right now you can define polls in poll_templates.yml that won't come through in the interface unless
    # the right components are defined, or you could have components which don't have a matching poll type serverside.

    # Ideally, we write these proposal types as plugins, which say 'Hey, add these components,
    # and add this poll type to the yml data', at the same time.
    # This will also make it easier to switch poll types on and off per instance, and per group.

    pollForms =
      proposal:   PollProposalForm
      engagement: PollEngagementForm
      # poll:       PollPollForm

    activePollTemplates: ->
      # this could have group-specific logic later.
      AppConfig.pollTemplates

    fieldFromTemplate: (pollType, field) ->
      return unless template = @templateFor(pollType)
      template[field]

    templateFor: (pollType) ->
      @activePollTemplates()[pollType]

    formFor: (pollType) ->
      pollForms[pollType]
