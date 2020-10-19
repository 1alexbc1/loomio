module.exports =
  props:
    poll: Object
    stance: Object
    outcome: Object
    stanceChoice: Object
    back: Object
    name: String
  methods:
    componentName: ->
      pollType = (@stance or @outcome or @stanceChoice or @poll).poll().pollType
      console.log "poll-#{pollType}-#{@name}"

      if Vue.options.components[_.upperFirst(_.camelCase("poll-#{pollType}-#{@name}"))]
        "poll-#{_.kebabCase(pollType)}-#{@name}"
      else
        "poll-common-#{@name}"
  template:
    """
    <component :is="componentName()" :poll='poll' :stance='stance' :stance-choice='stanceChoice' :outcome='outcome' :back='back'></component>
    """
