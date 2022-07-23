defmodule RestApi.PostActions do
  alias RestApi.Repo
  alias RestApi.Post

  def list_posts do
    posts = Post
      |> Repo.all

    {:ok, posts}
  end

  def get_post(id) do
    post = Post
      |> Repo.get(id)

    case post do
      nil -> not_found()
      post -> {:ok, post}
    end
  end

  def create_post(value = %{"title" => _title, "body" => _body}) do
    result = parse_user_input_as_changeset(value)
      |> Repo.insert

    case result do
      {:ok, post}
        -> {:created, post}
      {:error, changeset}
        -> invalid_request(get_errors(changeset))
      _
        -> invalid_request()
    end
  end

  def create_post(_) do
    invalid_request()
  end

  def delete_post(id) do
    post = Post
      |> Repo.get(id)


    result = case post do
      nil -> not_found()
      post -> Repo.delete(post)
    end

    case result do
      {:ok, post} -> {:ok, post}
      {:not_found, _} -> not_found()
      _ -> internal_error(%{error: "Unable to delete post"})
    end
  end

  def update_post(id, %{"title" => title, "body" => body}) do
    updated_values = %{title: title, body: body}
    post = Post
      |> Repo.get(id)

    result = case post do
      nil ->
        not_found()
      post -> post
        |> Post.changeset(updated_values)
        |> Repo.update()
    end

    case result do
      {:ok, post} -> {:ok, post}
      {:error, changeset} -> invalid_request(get_errors(changeset))
      {:not_found, _} -> not_found()
    end
  end

  def update_post(_, _) do
    invalid_request()
  end

  defp parse_user_input_as_changeset(%{"title" => title, "body" => body}) do
    %Post{}
      |> Post.changeset(%{title: title, body: body})
  end

  defp not_found do
    {:not_found, nil}
  end

  defp invalid_request(errors) do
    {:invalid_request, errors}
  end

  defp invalid_request do
    {:invalid_request, %{error: "Invalid post"}}
  end

  defp internal_error(error) do
    {:internal_error, error}
  end

  defp get_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

end
