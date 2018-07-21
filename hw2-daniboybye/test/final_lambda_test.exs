defmodule Helpers do
  def add_to_agent(agent, time \\ 0) do
    Agent.update(agent, fn n -> n + 1 end)
    wait(time)
  end

  def wait(time) do
    Process.sleep(time)
    time
  end

  def crasher() do
    raise "\nI will crash you!\n  /Garrosh 2014/"
  end
end

defmodule LambdaFinalTest do
  use ExUnit.Case, async: true

  @moduletag :final_tests
  setup do
    {:ok, _} = Application.ensure_all_started(:lambda)

    on_exit(fn ->
      Application.stop(:lambda)
    end)

    :ok
  end

  test "can register a function" do
    Lambda.register(Helpers, :wait)
  end

  test "can run function that is registered" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 1} == Lambda.run(Helpers, :wait, [1])
  end

  test "run returns :not_registered when called for non registered function" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 1} == Lambda.run(Helpers, :wait, [1])
    assert {:error, :not_registered} == Lambda.run(Helpers, :crasher, [])
  end

  test "run returns :execution_error when function raises" do
    Lambda.register(Helpers, :wait)
    Lambda.register(Helpers, :crasher)
    assert {:ok, 1} == Lambda.run(Helpers, :wait, [1])
    assert {:error, :execution_error} == Lambda.run(Helpers, :crasher, [])
  end

  @tag timeout: 20_000
  test "function that runes for more then 5 sec times out by default" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 4995} == Lambda.run(Helpers, :wait, [4995])
    assert :timeout == Lambda.run(Helpers, :wait, [5900])
  end

  test "can change the timeout of run" do
    Lambda.register(Helpers, :wait)
    assert :timeout == Lambda.run(Helpers, :wait, [4000], 1)
  end

  test "after we calculate function the timeout doesn't come into effect" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21], 20)
  end

  test "fetch_cached returns the cached result when it was previusly calculate" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 21} == Lambda.fetch_cached(Helpers, :wait, [21])
  end

  test "fetch_cached returns not_registed when the function is not registered" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 21} == Lambda.fetch_cached(Helpers, :wait, [21])
    assert {:error, :not_registered} == Lambda.fetch_cached(Helpers, :crasher, [])
  end

  test "fetch_cached returns not_cached when the function is not ran with the given arguments" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 21} == Lambda.fetch_cached(Helpers, :wait, [21])
    assert {:error, :not_cached} == Lambda.fetch_cached(Helpers, :wait, [3])
  end

  test "clear_cache with 2 args removes all the results for the cached functions" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 22} == Lambda.run(Helpers, :wait, [22])
    Lambda.clear_cache(Helpers, :wait)
    assert {:error, :not_cached} == Lambda.fetch_cached(Helpers, :wait, [21])
    assert {:error, :not_cached} == Lambda.fetch_cached(Helpers, :wait, [22])
  end

  test "clear_cache with 3 args removes the result for the cached functions only for the args" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 22} == Lambda.run(Helpers, :wait, [22])
    Lambda.clear_cache(Helpers, :wait, [21])
    assert {:error, :not_cached} == Lambda.fetch_cached(Helpers, :wait, [21])
    assert {:ok, 22} == Lambda.fetch_cached(Helpers, :wait, [22])
  end

  test "unregister works properly" do
    Lambda.register(Helpers, :wait)
    assert {:ok, 21} == Lambda.run(Helpers, :wait, [21])
    assert {:ok, 22} == Lambda.run(Helpers, :wait, [22])
    Lambda.unregister(Helpers, :wait)
    assert {:error, :not_registered} == Lambda.fetch_cached(Helpers, :wait, [21])
  end

  test "when we run a function with the same args 2 times it is executed only once" do
    {:ok, agent} = Agent.start(fn -> 0 end)
    Lambda.register(Helpers, :add_to_agent)
    assert {:ok, 100} == Lambda.run(Helpers, :add_to_agent, [agent, 100])
    assert {:ok, 100} == Lambda.run(Helpers, :add_to_agent, [agent, 100])
    assert 1 == Agent.get(agent, fn x -> x end)
  end
end
