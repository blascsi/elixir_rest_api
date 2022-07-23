defmodule RestApiTest.RouterTest do
  use RestApiTest.RepoCase
  use Plug.Test

  @opts RestApi.Router.init([])

  # Seed database before each test
  setup do
    posts = Enum.map(1..3, fn n ->
      post_data = %{title: "Post nr#{n}", body: "Post #{n}"}
      %RestApi.Post{}
        |> RestApi.Post.changeset(post_data)
        |> RestApi.Repo.insert!()
        # Encode and decode to get the same structure
        # As it is expected in the responses
        |> Jason.encode!()
        |> Jason.decode!()
    end)

    {:ok, %{posts: posts}}
  end

  test "health check route works" do
    conn = conn(:get, "/ping")

    conn = RestApi.Router.call(conn, @opts)

    expect_json_response(conn, 200, %{"message" => "pong"})
  end

  test "/posts GET returns the list of posts", %{posts: posts} do
    conn = conn(:get, "/posts")

    conn = RestApi.Router.call(conn, @opts)

    expect_json_response(conn, 200, posts)
  end

  test "/post GET returns the post", %{posts: posts} do
    [first_post | _] = posts
    first_post_id = Map.get(first_post, "id")

    conn = conn(:get, "/post/#{first_post_id}")

    conn = RestApi.Router.call(conn, @opts)

    expect_json_response(conn, 200, first_post)
  end

  test "/post GET returns 404 when id is not in database", %{posts: posts} do
    non_existing_post_id = get_non_existing_id(posts)

    conn = conn(:get, "/post/#{non_existing_post_id}")

    conn = RestApi.Router.call(conn, @opts)

    expect_not_found_response(conn)
  end

  test "/post POST is able to create posts" do
    new_post = %{"title" => "New Post", "body" => "New Post Body"}

    conn = conn(:post, "/post", new_post)

    conn = RestApi.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 201

    parsed_response = Jason.decode!(conn.resp_body)
    # ID should be there and should be an integer
    assert is_integer(Map.get(parsed_response, "id")) == true
    # We don't know the ID so we remove it from the check
    parsed_response = Map.delete(parsed_response, "id")
    assert parsed_response == new_post
  end

  test "/post POST returns correct errors" do
    missing_title = %{"title" => "", "body" => "Missing Title"}
    missing_body = %{"title" => "Missing Body", "body" => ""}
    empty_body = %{}

    missing_title_conn = conn(:post, "/post", missing_title)
    missing_body_conn = conn(:post, "/post", missing_body)
    empty_body_conn = conn(:post, "/post", empty_body)

    missing_title_conn = RestApi.Router.call(missing_title_conn, @opts)
    missing_body_conn = RestApi.Router.call(missing_body_conn, @opts)
    empty_body_conn = RestApi.Router.call(empty_body_conn, @opts)

    expect_json_response(
      missing_title_conn,
      400,
      %{"title" => ["can't be blank"]}
    )
    expect_json_response(
      missing_body_conn,
      400,
      %{"body" => ["can't be blank"]}
    )
    expect_json_response(
      empty_body_conn,
      400,
      %{"error" => "Invalid post"}
    )
  end

  test "/post DELETE deletes post", %{posts: posts} do
    [post_to_delete | _] = posts
    delete_id = Map.get(post_to_delete, "id")

    conn = conn(:delete, "/post/#{delete_id}")

    conn = RestApi.Router.call(conn, @opts)

    expect_json_response(conn, 200, post_to_delete)
  end

  test "/post DELETE returns correct errors", %{posts: posts} do
    non_existing_id = get_non_existing_id(posts)

    conn = conn(:delete, "/post/#{non_existing_id}")

    conn = RestApi.Router.call(conn, @opts)

    expect_not_found_response(conn)
  end

  test "/post PUT updates post", %{posts: posts} do
    [post_to_update | _] = posts
    post_to_update_id = Map.get(post_to_update, "id")
    update_body = %{"title" => "New Title", "body" => "New Body"}

    conn = conn(:put, "/post/#{post_to_update_id}", update_body)

    conn = RestApi.Router.call(conn, @opts)

    expect_json_response(
      conn,
      200,
      Map.merge(update_body, %{"id" => post_to_update_id})
    )
  end

  test "/post PUT returns correct errors", %{posts: posts} do
    [post_to_update | _] = posts
    non_existing_post_id = get_non_existing_id(posts)
    post_to_update_id = Map.get(post_to_update, "id")
    missing_title = %{"title" => "", "body" => "Missing Title"}
    missing_body = %{"title" => "Missing Body", "body" => ""}
    empty_body = %{}
    body_for_not_existing_post = %{
      "title" => "This Post does not exist",
      "body" => "Body either"
    }

    missing_title_conn = conn(:put, "/post/#{post_to_update_id}", missing_title)
    missing_body_conn = conn(:put, "/post/#{post_to_update_id}", missing_body)
    empty_body_conn = conn(:put, "/post/#{post_to_update_id}", empty_body)
    non_existing_post_conn = conn(
      :put,
      "/post/#{non_existing_post_id}",
      body_for_not_existing_post
    )

    missing_title_conn = RestApi.Router.call(missing_title_conn, @opts)
    missing_body_conn = RestApi.Router.call(missing_body_conn, @opts)
    empty_body_conn = RestApi.Router.call(empty_body_conn, @opts)
    non_existing_post_conn = RestApi.Router.call(non_existing_post_conn, @opts)

    expect_json_response(missing_title_conn, 400, %{"title" => ["can't be blank"]})
    expect_json_response(missing_body_conn, 400, %{"body" => ["can't be blank"]})
    expect_json_response(empty_body_conn, 400, %{"error" => "Invalid post"})
    expect_not_found_response(non_existing_post_conn)
  end

  defp expect_json_response(conn, status_code, body) do
    assert conn.state == :sent
    assert conn.status == status_code
    assert Jason.decode!(conn.resp_body) == body
  end

  defp expect_not_found_response(conn) do
    assert conn.state == :sent
    assert conn.status == 404
    assert Jason.decode!(conn.resp_body) == %{"error" => "Not Found"}
  end

  defp get_non_existing_id(posts) do
    max_existing_post_id = Enum.map(posts, fn post -> Map.get(post, "id") end)
      |> Enum.max()
    max_existing_post_id + 1
  end
end
