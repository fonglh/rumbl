defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel
  alias Rumbl.AnnotationView

  # Clients can join topics on a channel
  # Return {:ok, socket} to authorize a join attempt or {:error, socket} to deny one.
  def join("videos:" <> video_id, params, socket) do
    # 0 is for a fresh connection since a user has yet to see an annotation.
    last_seen_id = params["last_seen_id"] || 0

    # Fetch a video from the repo
    video_id = String.to_integer(video_id)
    video = Repo.get!(Rumbl.Video, video_id)

    # Fetch the video's annotations, to use data in an association, it must be fetched
    # explicitly, hence the preload.
    # Only grab annotations with IDs greater than last_seen_id
    annotations = Repo.all(
      from a in assoc(video, :annotations),
        where: a.id > ^last_seen_id,
        order_by: [asc: a.at, asc: a.id],
        limit: 200,
        preload: [:user]
    )

    # Compose a response by rendering an annotation.json view for every annotation
    # using the render_many function.
    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView,
                                                    "annotation.json")}
    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  # Ensure all incoming events have the current user.
  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # handles all incoming messages to the channel pushed from the remote client.
  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        # the payload is an arbitrary map.
        # we can send as many messages as we like.
        # DO NOT forward along the raw payload.
        #broadcast! socket, "new_annotation", %{
        #  id: annotation.id,
        #  user: Rumbl.UserView.render("user.json", %{user: user}),
        #  body: annotation.body,
        #  at: annotation.at
        #}
        broadcast_annotation(socket, annotation)
        # important to use a Task here so we don't block on any particular messages arriving
        # to the channel.
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)

        # sends reply back to the client with status and socket
        # can also use :noreply, but it's common practice to acknowledge the
        # result of the pushed message from the client.
        # This allows clients to implement UI features like loading statuses
        # and error notifications.
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end

  end

  # Reports annotation to all subscribers on this topic.
  defp broadcast_annotation(socket, annotation) do
    annotation = Repo.preload(annotation, :user)
    rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json",
                                       %{annotation: annotation})
    broadcast! socket, "new_annotation", rendered_ann
  end

  defp compute_additional_info(annotation, socket) do
    # call our info system for 1 result, maximum wait 10 secs.
    for result <- InfoSys.compute(annotation.body, limits: 1, timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: annotation.at}
      info_changeset =
        # query db for user matching each backend
        Repo.get_by!(Rumbl.User, username: result.backend)
        |> build_assoc(:annotations, video_id: annotation.video_id)
        |> Rumbl.Annotation.changeset(attrs)

      case Repo.insert(info_changeset) do
        {:ok, info_ann} -> broadcast_annotation(socket, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
end
