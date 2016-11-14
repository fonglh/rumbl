defmodule Rumbl.Channels.VideoChannelTest do
  use Rumbl.ChannelCase
  import Rumbl.TestHelpers

  # Prepare tests with user and video
  setup do
    user = insert_user(name: "Rebecca")
    video = insert_video(user, title: "Testing")
    token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    # start a simulated socket connection
    {:ok, socket} = connect(Rumbl.UserSocket, %{"token" => token})
    {:ok, socket: socket, user: user, video: video}
  end

  # match socket and video so it can use the work in the setup function
  test "join replies with video annotations", %{socket: socket, video: vid} do
    for body <- ~w(one two) do
      vid
      |> build_assoc(:annotations, %{body: body})
      |> Repo.insert!()
    end
    # subscribe_and_join is a test helper which attempts to join the channel responsible
    # for the "video:#{vid.id}" topic.
    {:ok, reply, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})

    # make sure we joined the right topic
    assert socket.assigns.video_id == vid.id

    # make sure the right annotations are in the reply by matching against reply.
    assert %{annotations: [%{body: "one"}, %{body: "two"}]} = reply
  end

  test "inserting new annotations", %{socket: socket, video: vid} do
    # the test works as a client of the channel
    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    # push helper function pushes a new event to the channel
    ref = push socket, "new_annotation", %{body: "the body", at: 0}

    # could also pass additional key/value pairs in the map
    assert_reply ref, :ok, %{}
    assert_broadcast "new_annotation", %{}
  end

  test "new annotations trigger InfoSys", %{socket: socket, video: vid} do
    # compute_additional_info function fetches a user by backend name, so it's needed
    # in the test.
    insert_user(username: "wolfram")

    {:ok, _, socket} = subscribe_and_join(socket, "videos:#{vid.id}", %{})
    # this triggers the stubbed "1 + 1" query
    ref = push socket, "new_annotation", %{body: "1 + 1", at: 123}

    assert_reply ref, :ok, %{}
    assert_broadcast "new_annotation", %{body: "1 + 1", at: 123}
    assert_broadcast "new_annotation", %{body: "2", at: 123}
  end
end
