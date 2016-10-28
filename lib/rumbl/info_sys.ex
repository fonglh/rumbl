# Generic module to spawn computations for queries.
# The backends are their own processes, but InfoSys isn't.
defmodule Rumbl.InfoSys do
  @backends [Rumbl.InfoSys.Wolfram]

  # Struct for holding each search result
  defmodule Result do
    # score is for relevance
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  # This is a proxy which calls `start_link` for the specific backend
  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends

    backends
    |> Enum.map(&spawn_query(&1, query, limit))
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)
    {pid, query_ref}
  end
end
