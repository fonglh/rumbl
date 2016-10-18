# Implements a Counter server as well as functions for interacting
# with it as a client.
#
# Client is the API, only sends messages to the process that does the work.
# It's the interface for the counter.
#
# Server is a process that recursively loops, processing a message and sending
# updated state to itself. It's the implementation.
defmodule Rumbl.Counter do

  # send inc message to the server process
  # asynchronous, send and don't wait for reply
  def inc(pid), do: send(pid, :inc)

  # send dec message to the server process
  # asynchronous, send and don't wait for reply
  def dec(pid), do: send(pid, :dec)

  def val(pid, timeout \\ 5000) do
    ref = make_ref()
    send(pid, {:val, self(), ref})
    receive do
      {^ref, val} -> val
    after timeout -> exit(:timeout)
    end
  end

  def start_link(initial_val) do
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

  defp listen(val) do
    receive do
      :inc -> listen(val + 1)
      :dec -> listen(val - 1)
      {:val, sender, ref} ->
        send sender, {ref, val}
        # tail recursive, so it optimizes to a loop
        listen(val)
    end
  end
end
