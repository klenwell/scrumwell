# rails g migration rename_scrum_contribution_model
class RenameScrumContributionModel < ActiveRecord::Migration[5.2]
  def change
    rename_table :scrum_contributions, :story_contributions
  end
end
