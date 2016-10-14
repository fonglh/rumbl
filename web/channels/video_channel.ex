defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # Clients can join topics on a channel
  # Return {:ok, socket} to authorize a join attempt or {:error, socket} to deny one.
  def join("videos:" <> video_id, _params, socket) do
    {:ok, socket}
  end

  # handles all incoming messages to the channel pushed from the remote client.
  # not persisting to the database yet, so just broadcast new_annotation events
  # to all clients on this topic.
  def handle_in("new_annotation", params, socket) do
    # the payload is an arbitrary map.
    # we can send as many messages as we like.
    # DO NOT forward along the raw payload.
    broadcast! socket, "new_annotation", %{
      user: %{username: "anon"},
      body: params["body"],
      at: params["at"]
    }

    # sends reply back to the client with status and socket
    # can also use :noreply
    {:reply, :ok, socket}
  end
end
