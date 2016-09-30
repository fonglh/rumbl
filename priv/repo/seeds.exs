# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Rumbl.Repo.insert!(%Rumbl.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Rumbl.Repo
alias Rumbl.Category

# Seed some categories, these won't change often so there's no need
# for to create controller and views to manage them.
for category <- ~w(Action Drama Romance Comedy Sci-fi) do
  # Check if the category exists before creating it
  Repo.get_by(Category, name: category) ||
    Repo.insert!(%Category{name: category})
end
