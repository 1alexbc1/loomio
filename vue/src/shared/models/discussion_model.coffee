import BaseModel        from '@/shared/record_store/base_model'
import AppConfig        from '@/shared/services/app_config'
import Session          from '@/shared/services/session'
import RangeSet         from '@/shared/services/range_set'
import HasDocuments     from '@/shared/mixins/has_documents'
import HasTranslations  from '@/shared/mixins/has_translations'
import { isAfter } from 'date-fns'
import dateIsEqual from 'date-fns/isEqual'
import { map, compact, flatten, isEqual, isEmpty, filter, some, head, last, sortBy, find, min, max, isArray, throttle, without } from 'lodash'
import I18n from '@/i18n'

export default class DiscussionModel extends BaseModel
  @singular: 'discussion'
  @plural: 'discussions'
  @uniqueIndices: ['id', 'key']
  @indices: ['groupId', 'authorId']

  afterConstruction: ->
    @private = @privateDefaultValue() if @isNew()
    HasDocuments.apply @, showTitle: true
    HasTranslations.apply @

  defaultValues: ->
    id: null
    key: null
    private: true
    lastItemAt: null
    title: ''
    description: ''
    descriptionFormat: 'html'
    forkedEventIds: []
    ranges: []
    readRanges: []
    newestFirst: false
    files: []
    imageFiles: []
    attachments: []
    linkPreviews: []
    tags: []
    recipientMessage: null
    recipientAudience: null
    recipientUserIds: []
    recipientChatbotIds: []
    recipientEmails: []
    notifyRecipients: true
    groupId: null
    usersNotifiedCount: null
    discussionReaderUserId: null
    pinnedAt: null
    poll_template_keys_or_ids: []

  cloneTemplate: ->
    clone = @clone()
    clone.id = null
    clone.key = null
    clone.title = I18n.t('templates.copy_of_title', {title: clone.title})
    clone.sourceTemplateId = @id
    clone.authorId = Session.user().id
    clone.pinnedAt = null
    clone.forkedEventIds = []
    clone.groupId = null
    clone.closedAt = null
    clone.createdAt = null
    clone.updatedAt = null
    clone.template = false
    clone

  pollTemplates: ->
    compact @pollTemplateKeysOrIds.map (keyOrId) =>
      @recordStore.pollTemplates.find(keyOrId)

  audienceValues: ->
    name: @group().name

  privateDefaultValue: =>
    @group().discussionPrivacyOptions != 'public_only'

  relationships: ->
    @hasMany 'polls', sortBy: 'createdAt', sortDesc: true, find: {discardedAt: null}
    @belongsTo 'group'
    @belongsTo 'author', from: 'users'
    @belongsTo 'closer', from: 'users'
    @hasMany 'discussionReaders'

  discussion: -> @
  
  template: ->
    @recordStore.discussionTemplates.find(@discussionTemplateId)

  tags: ->
    @recordStore.tags.collection.chain().find(id: {$in: @tagIds}).simplesort('priority').data()

  members: ->
    @recordStore.users.find(@group().memberIds().concat(map(@discussionReaders(), 'userId')))

  membersInclude: (user) ->
    (@inviterId && !@revokedAt && Session.user().id == user.id) ||
    @group().membersInclude(user)

  adminsInclude: (user) ->
    @authorId == user.id ||
    (@inviterId && @admin && !@revokedAt && AppConfig.currentUserId == user.id) ||
    @group().adminsInclude(user)

  # known current participants for quick mentioning
  participantIds: ->
    compact flatten(
      map(@recordStore.comments.find(discussionId: @id), 'authorId'),
      map(@recordStore.polls.find(discussionId: @id), (p) -> p.participantIds()),
      [@authorId]
    )

  bestNamedId: ->
    ((@id && @) || (@groupId && @group()) || {namedId: ->}).namedId()

  createdEvent: ->
    res = @recordStore.events.find(kind: 'new_discussion', eventableId: @id)
    res[0] unless isEmpty(res)

  forkedEvent: ->
    res = @recordStore.events.find(kind: 'discussion_forked', eventableId: @id)
    res[0] unless isEmpty(res)

  reactions: ->
    @recordStore.reactions.find(reactableId: @id, reactableType: "Discussion")

  translationOptions: ->
    title: @title
    groupName: @groupName()

  authorName: ->
    @author().nameWithTitle(@group())

  isBlank: ->
    @description == '' or @description == null or @description == '<p></p>'

  groupName: ->
    (@group() || {}).name

  activePolls: ->
    filter @polls(), (poll) ->
      poll.isVotable()

  hasActivePoll: ->
    some @activePolls()

  hasDecision: ->
    @hasActivePoll()

  closedPolls: ->
    filter @polls(), (poll) ->
      !poll.isVotable()

  activePoll: ->
    head @activePolls()

  isUnread: ->
    !@isDismissed() and (!@lastReadAt? or @unreadItemsCount() > 0)

  isDismissed: ->
    @discussionReaderId? and @dismissedAt? and
    (dateIsEqual(@dismissedAt, @lastActivityAt) or isAfter(@dismissedAt, @lastActivityAt))

  hasUnreadActivity: ->
    @isUnread() && @unreadItemsCount() > 0

  membership: ->
    @recordStore.memberships.find(userId: AppConfig.currentUserId, groupId: @groupId)[0]

  volume: -> @discussionReaderVolume

  saveVolume: (volume, applyToAll = false) =>
    @processing = true
    if applyToAll
      @membership().saveVolume(volume).finally => @processing = false
    else
      @discussionReaderVolume = volume if volume?
      @remote.patchMember(@keyOrId(), 'set_volume', { volume: @discussionReaderVolume }).finally =>
        @processing = false

  isMuted: ->
    @volume() == 'mute'

  markAsSeen: ->
    return if @lastReadAt
    @remote.patchMember @keyOrId(), 'mark_as_seen'
    @update(lastReadAt: new Date)

  markAsRead: (id) ->
    return if @hasRead(id)
    @readRanges.push([id,id])
    @readRanges = RangeSet.reduce(@readRanges)
    @updateReadRanges()

  update: (attributes) ->
    if isArray(@readRanges) && isArray(attributes.readRanges) && !isEqual(attributes.readRanges, @readRanges)
      attributes.readRanges = RangeSet.reduce(@readRanges.concat(attributes.readRanges))
    @baseUpdate(attributes)
    @readRanges = RangeSet.intersectRanges(@readRanges, @ranges)

  updateReadRanges: throttle ->
    @remote.patchMember @keyOrId(), 'mark_as_read', ranges: RangeSet.serialize(@readRanges)
  , 2000

  hasRead: (id) ->
    RangeSet.includesValue(@readRanges, id)

  unreadItemsCount: ->
    @itemsCount - @readItemsCount()

  readItemsCount: ->
    RangeSet.length(@readRanges)

  firstSequenceId: ->
    (head(@ranges) || [])[0]

  lastSequenceId: ->
    (last(@ranges) || [])[1]

  lastReadSequenceId: ->
    (last(@readRanges) || [])[1]

  firstUnreadSequenceId: ->
    (@unreadRanges()[0] || [])[0]

  readSequenceIds: ->
    RangeSet.rangesToArray(@readRanges)

  unreadRanges: ->
    RangeSet.subtractRanges(@ranges, @readRanges)

  unreadSequenceIds: ->
    RangeSet.rangesToArray(@unreadRanges())

  dismiss: ->
    @update(dismissedAt: new Date)
    @processing = true
    @remote.patchMember(@keyOrId(), 'dismiss').finally => @processing = false

  recall: ->
    @update(dismissedAt: null)
    @processing = true
    @remote.patchMember(@keyOrId(), 'recall').finally => @processing = false

  move: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'move', { group_id: @groupId }).finally => @processing = false

  savePin: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'pin').finally => @processing = false

  saveUnpin: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'unpin').finally => @processing = false

  close: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'close').finally => @processing = false

  reopen: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'reopen').finally => @processing = false

  moveComments: =>
    @processing = true
    @remote.patchMember(@keyOrId(), 'move_comments', { forked_event_ids: @forkedEventIds }).finally => @processing = false

  fetchUsersNotifiedCount: ->
    @recordStore.fetch
      path: 'announcements/users_notified_count'
      params:
        discussion_id: @id
    .then (data) =>
      @usersNotifiedCount = data.count

  forkedEvents: ->
    sortBy(@recordStore.events.find(@forkedEventIds), 'sequenceId')

  forkTarget: ->
    @forkedEvents()[0].model() if some @forkedEvents()
