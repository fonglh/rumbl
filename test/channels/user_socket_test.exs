defmodule Rumbl.Channels.UserSocketTest do
  # no db calls, so async can be true and tests can run concurrently.
  use Rumbl.ChannelCase, async: true
  alias Rumbl.UserSocket

  test "socket authentication with valid token" do
    token = Phoenix.Token.sign(@endpoint, "user socket", "123")

    # connect helper simulates a UserSocket connection
    # Test that connection succeeds and the user_id is placed in the socket.
    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.user_id == "123"
  end

  test "socket authentication with invalid token" do
    # test with invalid token and empty token
    assert :error = connect(UserSocket, %{"token" => "1313"})
    assert :error = connect(UserSocket, %{})
  end
end
