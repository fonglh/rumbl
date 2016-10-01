defmodule Rumbl.Video do
  use Rumbl.Web, :model

  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :user, Rumbl.User
    belongs_to :category, Rumbl.Category

    timestamps()
  end

  @required_fields ~w(url title description)
  @optional_fields ~w(category_id)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields, @optional_fields)
    # validate_required was autogenerated, but the book's example of using a module
    # attribute and passing it to cast works too.
    # |> validate_required([:url, :title, :description])

    # converts foreign-key constraint errors into human readable error messages
    # guarantees that a video is only created if the categoryr exists in the db
    |> assoc_constraint(:category)
  end
end
