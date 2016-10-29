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
    |> await_results(opts)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, _opts) do
    await_result(children, [], :infinity)
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      # valid result, drop the monitor.
      # [:flush] guarantees that the :DOWN message is removed from the inbox
      # in case it's delivered before we drop the monitor.
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      # match on monitor_ref, because :DOWN messages come from the monitor
      # and not the GenServer.
      # Recurse without adding to the accumulator.
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
    end
  end

  # base case, ends recursion when list has been processed.
  defp await_result([], acc, _) do
    acc
  end
end
