defmodule RestApi.Router do
  alias RestApi.PostActions

  use Plug.Router

  plug(Plug.Logger)

  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/ping" do
    send_json(conn, 200, %{message: "pong"})
  end

  get "/posts" do
    PostActions.list_posts()
      |> send_posts(conn)
  end

  get "/post/:id" do
    PostActions.get_post(id)
      |> send_post(conn)
  end

  post "/post" do
    PostActions.create_post(conn.body_params)
      |> send_post(conn)
  end

  delete "/post/:id" do
    PostActions.delete_post(id)
      |> send_post(conn)
  end

  put "post/:id" do
    PostActions.update_post(id, conn.body_params)
      |> send_post(conn)
  end

  match _ do
    send_json(conn, 404, %{error: "Not Found"})
  end

  defp send_posts({:ok, post}, conn) when is_list(post) do
    send_json(conn, 200, post)
  end

  defp send_post({:ok, post = %RestApi.Post{}}, conn) do
    send_json(conn, 200, post)
  end

  defp send_post({:created, post = %RestApi.Post{}}, conn) do
    send_json(conn, 201, post)
  end

  defp send_post({:not_found, _}, conn) do
    send_json(conn, 404, %{error: "Not Found"})
  end

  defp send_post({:invalid_request, error}, conn) do
    send_json(conn, 400, error)
  end

  defp send_post({:internal_error, error}, conn) do
    send_json(conn, 500, error)
  end

  defp send_post(_, conn) do
    send_json(conn, 500, %{error: "Internal Server Error"})
  end

  defp send_json(conn, status_code, data) do
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(status_code, Jason.encode!(data))
  end
end
