class Comment < ApplicationRecord
  include CustomCounterCache::Model
  include Translatable
  include Reactable
  include HasMentions
  include HasDrafts
  include HasCreatedEvent
  include HasEvents

  has_paper_trail only: [:body]

  is_translatable on: :body
  is_mentionable  on: :body

  belongs_to :discussion
  has_one :group, through: :discussion
  belongs_to :user
  belongs_to :parent, class_name: 'Comment'

  alias_attribute :author, :user
  alias_attribute :author_id, :user_id
  alias_method :draft_parent, :discussion

  has_many_attached :files
  has_many_attached :image_files

  has_many :documents, as: :model, dependent: :destroy

  validates_presence_of :user
  validate :has_body_or_document
  validate :parent_comment_belongs_to_same_discussion
  validate :documents_owned_by_author
  validates :body, {length: {maximum: Rails.application.secrets.max_message_length}}

  default_scope { includes(:user).includes(:documents).includes(:discussion) }

  scope :in_organisation, ->(group) { joins(:discussion).where("discussions.group_id": group.id) }
  scope :chronologically, -> { order('created_at asc') }

  delegate :name, to: :user, prefix: :user
  delegate :name, to: :user, prefix: :author
  delegate :email, to: :user, prefix: :user
  delegate :author, to: :parent, prefix: :parent, allow_nil: true
  delegate :participants, to: :discussion, prefix: :discussion
  delegate :group_id, to: :discussion, allow_nil: true
  delegate :full_name, to: :group, prefix: :group
  delegate :title, to: :discussion, prefix: :discussion
  delegate :locale, to: :user
  delegate :mailer, to: :discussion
  delegate :id, to: :group, prefix: :group
  delegate :groups, to: :discussion
  delegate :guest_group, to: :discussion
  delegate :guest_group_id, to: :discussion
  delegate :members, to: :discussion

  define_counter_cache(:versions_count) { |comment| comment.versions.count }
  after_save :update_attachments

  def self.always_versioned_fields
    [:body]
  end

  def created_event_kind
    :new_comment
  end

  def body=(content)
    # if body_format == "html"
    tags = %w[strong em b i p code pre big small hr br span h1 h2 h3 h4 h5 h6 ul ol li abbr a img blockquote]
    attributes = %w[href src alt title]
    self[:body] = Rails::Html::WhiteListSanitizer.new.sanitize(content, tags: tags, attributes: attributes)
    # end
  end

  def parent_event
    return discussion.created_event unless parent
    next_parent = parent
    while (next_parent.parent) do
      next_parent = next_parent.parent
    end
    next_parent.created_event
  end

  def purge_drafts_asynchronously?
    false
  end

  def created_event_kind
    :new_comment
  end

  def is_most_recent?
    discussion.comments.last == self
  end

  def is_edited?
    edited_at.present?
  end

  def can_be_edited?
    group.members_can_edit_comments? or is_most_recent?
  end

  def users_to_not_mention
    User.where(username: parent&.author&.username)
  end

  private
  def attachments
    files.map do |file|
      {name: file.name,
       preview_url: (file.previewable? ? file.preview(resize: "600x600>") : nil),
       download_url: Rails.application.routes.url_helpers.rails_blob_path(file)
      }
    end
  end
  
  def documents_owned_by_author
    return if documents.pluck(:author_id).select { |user_id| user_id != user.id }.empty?
    errors.add(:documents, "Attachments must be owned by author")
  end

  def parent_comment_belongs_to_same_discussion
    if self.parent.present?
      unless discussion_id == parent.discussion_id
        errors.add(:parent, "Needs to have same discussion id")
      end
    end
  end

  def has_body_or_document
    if body.blank? && documents.blank?
      errors.add(:body, "Comment cannot be empty")
    end
  end
end
