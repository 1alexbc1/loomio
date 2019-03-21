class GroupBaseController < BaseController
  before_filter :authenticate_user!, except: :show

  private
    def check_group_read_permissions
      unless group.can_be_viewed_by? current_user
        render 'groups/private_or_not_found'
      end
    end
end
