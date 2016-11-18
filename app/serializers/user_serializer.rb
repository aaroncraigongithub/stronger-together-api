# frozen_string_literal: true
class UserSerializer < ActiveModel::Serializer
  attributes :id,
             :email,
             :name,
             :confirmed_at,
             :created_at,
             :updated_at

  def id
    object.uuid
  end
end