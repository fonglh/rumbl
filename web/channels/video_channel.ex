defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  # Clients can join topics on a channel
  # Return {:ok, socket} to authorize a join attempt or {:error, socket} to deny one.
  #
  # Add video ID from topic to socket.assigns, which typically holds a map.
  def join("videos:" <> video_id, _params, socket) do
    {:ok, assign(socket, :video_id, String.to_integer(video_id))}
  end
end
