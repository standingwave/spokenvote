# == Schema Information
#
# Table name: proposals
#
#  id          :integer          not null, primary key
#  statement   :string(255)
#  user_id     :integer
#  parent_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  votes_count :integer          default(0)
#  ancestry    :string(255)
#  created_by  :integer
#

class Proposal < ActiveRecord::Base
  attr_accessible :parent_id, :parent, :statement, :user_id, :user, :votes, :votes_attributes

  # Associations
  belongs_to :user
  has_many :votes, inverse_of: :proposal
  has_many :hubs, through: :votes

  accepts_nested_attributes_for :votes, reject_if: :all_blank

  # Validations
  validates :user, :statement, presence: true

  # Other
  has_ancestry
  
  class << self
    def roots
      where({:ancestry => nil})
    end

    def by_hub
      Proposal.all#Hub.by_name.map {|gb| gb.proposals if gb.proposals }.reject {|gb| gb == []}.flatten
    end
  end

  def votes_in_tree
    Rails.cache.fetch("/proposal/#{self.root.id}/votes_in_tree/#{updated_at}", :expires_at => 5.minutes) do
      [self.root, self.root.descendants].flatten.map(&:votes_count).sum
    end
  end

  def related_proposals
    all_proposals_in_tree = [self.root, self.root.descendants].flatten
    all_proposals_in_tree.delete(self.clone)
    all_proposals_in_tree
  end
end
