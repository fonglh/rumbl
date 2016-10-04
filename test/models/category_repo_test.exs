defmodule Rumbl.CategoryRepoTest do
  use Rumbl.ModelCase
  alias Rumbl.Category

  # Inserts a few categories then queries against the Repo
  # to check that they're returned alphabetically as requested.
  #
  # Also test that alphabetical() can compose with an existing
  # queryable argument.
  test "alphabetical/1 orders by name" do
    Repo.insert!(%Category{name: "c"})
    Repo.insert!(%Category{name: "a"})
    Repo.insert!(%Category{name: "b"})

    query = Category |> Category.alphabetical()
    query = from c in query, select: c.name
    assert Repo.all(query) == ~w(a b c)
  end
end
