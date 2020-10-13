svg = require 'svg.js'
AppConfig = require 'shared/services/app_config'

module.exports =
  props:
    stanceCounts: Array
    size: String # IK: seems bad
  data: ->
    svgEl: null
    shapes: []
  computed:
    scoreData: ->
      _.take(_.map(this.stanceCounts, (score, index) ->
        { color: AppConfig.pollColors.poll[index], index: index, score: score }), 5)
    scoreMaxValue: ->
      _.max _.map(this.scoreData, (data) -> data.score)
  methods:
    draw: ->
      if this.scoreData.length > 0 and this.scoreMaxValue > 0
        this.drawChart()
      else
        this.drawPlaceholder()
    drawPlaceholder: ->
      _.each this.shapes, (shape) -> shape.remove()
      barHeight = this.size / 3
      barWidths =
        0: this.size
        1: 2 * this.size / 3
        2: this.size / 3
      _.each barWidths, (width, index) =>
        this.svgEl.rect(width, barHeight - 2)
            .fill("#ebebeb")
            .x(0)
            .y(index * barHeight)
    drawChart: ->
      _.each this.shapes, (shape) -> shape.remove()
      barHeight = this.size / this.scoreData.length
      _.map this.scoreData, (scoreDatum) =>
        barWidth = _.max([(this.size * scoreDatum.score) / this.scoreMaxValue, 2])
        this.svgEl.rect(barWidth, barHeight-2)
            .fill(scoreDatum.color)
            .x(0)
            .y(scoreDatum.index * barHeight)
  watch:
    stanceCounts: ->
      console.log('watch stanceCounts', this.stanceCounts)
      this.draw()
  template: '<div class="bar-chart"></div>'
  mounted: ->
    this.svgEl = svg(this.$el).size('100%', '100%')
    this.draw()
