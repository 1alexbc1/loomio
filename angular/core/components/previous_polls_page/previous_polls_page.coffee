angular.module('loomioApp').controller 'PreviousPollsPageController', ($scope, $rootScope, $routeParams, Records, AbilityService, TranslationService, LoadingService) ->
  $rootScope.$broadcast('currentComponent', { page: 'previousPollsPage'})

  Records.groups.findOrFetchById($routeParams.key).then (group) =>
    @group = group
    @loadMore()
  , throwPageError

  throwPageError = (error) ->
    $rootScope.$broadcast('pageError', error)

  from = 0
  per = 10

  @loadMore = =>
    Records.polls.fetchClosedByGroup(@group.key, from: from, per: per).then =>
      from += per
      Records.stances.fetchMyStances(@group.key) if AbilityService.isLoggedIn()
  LoadingService.applyLoadingFunction @, 'loadMore'

  @searchPolls = =>
    Records.polls.search(@group.key, @fragment, per: 10)
  LoadingService.applyLoadingFunction @, 'searchPolls'

  @pollCollection =
    polls: =>
      return [] unless @group?
      _.sortBy(
        _.filter(@group.closedPolls(), (poll) =>
          _.isEmpty(@fragment) or poll.title.match(@fragment)), '-closedAt')


  @translations = TranslationService.eagerTranslate @,
    searchPlaceholder: 'previous_polls_page.search_activities'

  @canLoadMore = ->
    @group and !@fragment and from < @group.closedPollsCount

  return
