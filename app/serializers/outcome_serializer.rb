class OutcomeSerializer < ActiveModel::Serializer
  embed :ids, include: true
  attributes :id, :statement

  has_one :poll, serializer: PollSerializer
  has_one :author, serializer: UserSerializer
end
