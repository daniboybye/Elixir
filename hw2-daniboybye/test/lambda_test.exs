defmodule Test do
  def wait(time) do
    Process.sleep(time)
    time
  end

  def crasher() do
    raise "\nI will crash you!\n  /Garrosh 2014/"
  end
end

defmodule LambdaTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, _} = Application.ensure_all_started(:lambda)

    on_exit(fn ->
      Application.stop(:lambda)
    end)

    :ok
  end

  test "can not run non-registered function" do
    assert Lambda.run(Test, :wait, [1]) == {:error, :not_registered}
  end

  test "can run registered function" do
    Lambda.register(Test, :wait)
    assert Lambda.run(Test, :wait, [1]) == {:ok, 1}
  end

  test "second execution of a slow function is faster" do
    Lambda.register(Test, :wait)
    f = fn -> :timer.tc(fn -> Lambda.run(Test, :wait, [1000]) end) end
    assert {non_cached, {:ok, 1000}} = f.()
    assert {cached,     {:ok, 1000}} = f.()
    assert cached * 10 < non_cached
  end

  test "running function that crashes returns error" do
    Lambda.register(Test, :crasher)
    assert Lambda.run(Test, :crasher, []) == {:error, :execution_error}
  end

  test "can check get something cached" do
    Lambda.register(Test, :wait)
    assert Lambda.run(Test, :wait, [1]) == {:ok, 1}
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:ok, 1}
  end

  test "trying to get something that is not cashed returns error" do
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:error, :not_registered}
    Lambda.register(Test, :wait)
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:error, :not_cached}
  end

  test "running function that crashes doesn't delete the cache" do
    Lambda.register(Test, :wait)
    Lambda.register(Test, :crasher)
    assert Lambda.run(Test, :wait, [1]) == {:ok, 1}
    assert Lambda.run(Test, :crasher, []) == {:error, :execution_error}
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:ok, 1}
  end

  test "can clear the whole cache for a function" do
    Lambda.register(Test, :wait)
    assert Lambda.run(Test, :wait, [1]) == {:ok, 1}
    assert Lambda.run(Test, :wait, [2]) == {:ok, 2}
    Lambda.clear_cache(Test, :wait)
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:error, :not_cached}
    assert Lambda.fetch_cached(Test, :wait, [2]) == {:error, :not_cached}
  end

  test "can clear a single cache entry" do
    Lambda.register(Test, :wait)
    assert Lambda.run(Test, :wait, [1]) == {:ok, 1}
    assert Lambda.run(Test, :wait, [2]) == {:ok, 2}
    Lambda.clear_cache(Test, :wait, [1])
    assert Lambda.fetch_cached(Test, :wait, [1]) == {:error, :not_cached}
    assert Lambda.fetch_cached(Test, :wait, [2]) == {:ok, 2}
  end

  test "can unregister a function" do
    Lambda.register(Test, :wait)
    Lambda.unregister(Test, :wait)
    assert Lambda.run(Test, :wait, [1]) == {:error, :not_registered}
  end

  test "after unregister" do
    Lambda.register(Test, :wait)

    spawn(fn ->
      Process.sleep(1_000)
      Lambda.unregister(Test, :wait)
    end)

    assert Lambda.run(Test, :wait, [3_000]) == {:ok, 3_000}
    assert Lambda.fetch_cached(Test, :wait, [3_000]) == {:error, :not_registered}
  end
end
