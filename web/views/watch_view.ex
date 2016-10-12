defmodule Rumbl.WatchView do
  use Rumbl.Web, :view

  def player_id(video) do
    # given the URL, extract the id field and return
    # a map of the id key and its value
    ~r{^.*(?:youtu\.be/|\w+/|v=)(?<id>[^#&?]*)}
    |> Regex.named_captures(video.url)
    |> get_in(["id"])
  end
end
