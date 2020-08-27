class PollOption < ApplicationRecord
  include FormattedDateHelper

  belongs_to :poll
  validates :name, presence: true

  has_many :stance_choices, dependent: :destroy
  has_many :stances, through: :stance_choices

  def total_score
    @total_score ||= stance_choices.latest.sum(:score)
  end

  def color
    AppConfig.colors.dig(poll.poll_type, self.priority % AppConfig.colors.length)
  end

  def has_time?
    super(self.name)
  end

  def display_name(zone: nil)
    if poll.dates_as_options
      formatted_datetime(name, zone || poll.time_zone)
    else
      name.humanize
    end
  end
end
