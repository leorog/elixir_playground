defmodule Mix.Tasks.Parallel do
  alias Experimental.Flow
  use Mix.Task

  def run(_) do
    n_core = System.cmd("nproc", []) |> elem(0) |> Integer.parse |> elem(0)
    to_ms = &( &1 |> elem(0) |> Kernel./(1_000) )

    tc_flow = fn(n) -> fn -> flow_run(n) end |> tc end
    tc_async = fn(n) -> fn -> async_run(n) end |> tc end
    tc_stream = fn(n) -> fn -> stream_run(n) end |> tc end

    IO.puts("Flow: #{tc_flow.(n_core) |> to_ms.()}ms")
    IO.puts("Async: #{tc_async.(n_core) |> to_ms.()}ms")
    IO.puts("Stream: #{tc_stream.(n_core) |> to_ms.()}ms")
  end

  def tc(fun) do
    :timer.tc(fun)
  end

  def async_run(n_proc) do
    sleep = fn -> :timer.sleep(1_000) end
    1..n_proc
    |> Enum.map(fn(_x) -> Task.async(sleep) end)
    |> Task.yield_many
  end

  def stream_run(n_proc) do
    1..n_proc
    |> Stream.each(fn(_x) ->
      :timer.sleep(1_000)
    end)
    |> Stream.run
  end

  def flow_run(n_proc) do
    1..n_proc
    |> Flow.from_enumerable
    |> Map.put(:options, [max_demand: 1])
    |> Flow.each(fn(_x) ->
      :timer.sleep(1_000)
    end)
    |> Flow.run
  end

end
