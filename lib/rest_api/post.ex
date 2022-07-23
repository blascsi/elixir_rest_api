defmodule RestApi.Post do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :title, :body]}
  schema "posts" do
    field :title, :string
    field :body, :string
  end

  def changeset(post, params \\ %{}) do
    post
    |> Ecto.Changeset.cast(params, [:title, :body])
    |> Ecto.Changeset.validate_required([:title, :body])
  end
end
