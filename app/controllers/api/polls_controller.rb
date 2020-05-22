class API::PollsController < API::RestfulController
  include UsesFullSerializer

  def show
    self.resource = load_and_authorize(:poll)
    respond_with_resource
  end

  def index
    instantiate_collection do |collection|
      collection = collection.where(discussion: @discussion) if load_and_authorize(:discussion, optional: true)
      collection = collection.active                         if params[:active]
      collection = collection.where(author: current_user)    if params[:authored_only]
      collection = collection.send(params[:filter])          if Poll::FILTERS.include?(params[:filter].to_s)
      collection
    end
    respond_with_collection
  end

  def closed
    instantiate_collection do |collection|
      collection.closed.where(discussion_id: load_and_authorize(:group).discussion_ids)
    end
    respond_with_collection
  end

  def close
    @event = service.close(poll: load_resource, actor: current_user)
    respond_with_resource
  end

  def search
    params.require(:q)
    instantiate_collection do |collection|
      collection.where(discussion_id: load_and_authorize(:group).discussion_ids).search_for(params[:q])
    end
    respond_with_collection
  end

  private
  def default_scope
    super.merge my_stances_cache: MyStancesCache.new(participant: current_participant, polls: collection || Array(resource))
  end

  def accessible_records
    Queries::VisiblePolls.new(user: current_user).order(created_at: :desc)
  end
end
