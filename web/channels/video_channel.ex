defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # Clients can join topics on a channel
  # Return {:ok, socket} to authorize a join attempt or {:error, socket} to deny one.
  #
  # Add video ID from topic to socket.assigns, which typically holds a map.
  def join("videos:" <> video_id, _params, socket) do
    :timer.send_interval(5_000, :ping)
    {:ok, assign(socket, :video_id, String.to_integer(video_id))}
  end

  # callback for receiving direct channel events.
  # invoked whenever an elixir message reaches the channel.
  # match on :ping and increment counter when it arrives.
  # Takes a socket and returns a transformed socket.
  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1

    # push the ping event, picked up by client with the
    # channel.on(event, callback) API. See video.js.
    push socket, "ping", %{count: count}

    # return tagged tuple.
    # :noreply means not sending a reply, assign function transforms
    # the socket by adding the new count
    {:noreply, assign(socket, :count, count + 1)}
  end
end
