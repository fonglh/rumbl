defmodule Rumbl.Counter do
  use GenServer

  # Use GenServer.cast for async messages
  def inc(pid), do: GenServer.cast(pid, :inc)

  def dec(pid), do: GenServer.cast(pid, :dec)

  def val(pid) do
    GenServer.call(pid, :val)
  end

  def start_link(initial_val) do
    GenServer.start_link(__MODULE__, initial_val)
  end

  # Functions below run in the server
  def init(initial_val) do
    # send itself a :tick message every second
    Process.send_after(self, :tick, 1000)
    {:ok, initial_val}
  end

  # crash the counter when it goes negative
  def handle_info(:tick, val) when val <=0, do: raise "boom!"

  # process the :tick message
  def handle_info(:tick, val) do
    IO.puts "tick #{val}"
    Process.send_after(self, :tick, 1000)
    # count down
    {:noreply, val - 1}
  end

  def handle_cast(:inc, val) do
    {:noreply, val + 1}
  end

  def handle_cast(:dec, val) do
    {:noreply, val - 1}
  end

  def handle_call(:val, _from, val) do
    {:reply, val, val}
  end
end
