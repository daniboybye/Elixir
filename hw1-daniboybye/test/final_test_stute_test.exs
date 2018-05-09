defmodule FinalTestSuiteTest do
  use ExUnit.Case

  @moduletag :final_tests

  describe "TestSuite.new/0" do
    test "can create empty test sute" do
      assert_is_test_sute(TestSuite.new())
    end

    test "creates the same struct as %TestSuite{}" do
      assert TestSuite.new() == %TestSuite{}
    end
  end

  describe "TestSuite.new/1" do
    test "can create test suite when called with function of arity 0" do
      assert_is_test_sute(TestSuite.new(fn -> nil end))
    end

    test "can not create test suite when called with function of arity different then 0" do
      assert_is_test_sute(TestSuite.new(fn -> nil end))
      catch_error(TestSuite.new(fn x -> x end))
    end

    test "can create test suite when given a list of function of arity 0" do
      test_case = fn -> nil end
      assert_is_test_sute(TestSuite.new([]))
      assert_is_test_sute(TestSuite.new([test_case]))
      assert_is_test_sute(TestSuite.new([test_case, test_case]))
    end

    test "can not create test suite when the list given contains something different then 0 arity functions" do
      assert_is_test_sute(TestSuite.new([]))
      catch_error(TestSuite.new([nil]))
      catch_error(TestSuite.new([& &1]))
    end

    test "can not create test suite when given something different then list or function" do
      assert_is_test_sute(TestSuite.new(fn -> nil end))
      assert_is_test_sute(TestSuite.new([]))
      catch_error(TestSuite.new(nil))
    end
  end

  describe "TestSuite.add/2" do
    test "can add single 0 arity function to a test suite" do
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(fn -> nil end))
    end

    test "works only with test suite as first argument" do
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(fn -> nil end))
      catch_error(nil |> TestSuite.add([nil]))
    end

    test "can add list of 0 arity functions to a test suite" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add([test_case, test_case]))
    end

    test "can not add anything but list or a 0 arity function" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(fn -> nil end))
      assert_is_test_sute(%TestSuite{} |> TestSuite.add([test_case, test_case]))
      catch_error(%TestSuite{} |> TestSuite.add(nil))
      catch_error(%TestSuite{} |> TestSuite.add(fn x -> x end))
    end

    test "can not add list conatining anything but 0 arity functions" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add([test_case, test_case]))
      catch_error(%TestSuite{} |> TestSuite.add([nil]))
      catch_error(%TestSuite{} |> TestSuite.add([2, 3, 4]))
    end

    test "adding test changes the test suite" do
      test_case = fn -> nil end

      {test_suite, _} = test_suite_with_size()
      assert test_suite != test_suite |> TestSuite.add(test_case)
    end
  end

  describe "TestSuite.add/3" do
    test "can add test with a single tag" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(test_case, :tag))
      {test_suite, _} = test_suite_with_size()
      assert_is_test_sute(test_suite |> TestSuite.add(test_case, :tag))
    end

    test "can add test with mutiple tags to a test suite" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(test_case, [:two, :tags]))
      {test_suite, _} = test_suite_with_size()
      assert_is_test_sute(test_suite |> TestSuite.add(test_case, [:two, :tags]))
    end

    test "can not use anything but atoms as tags" do
      test_case = fn -> nil end
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(test_case, :two))
      assert_is_test_sute(%TestSuite{} |> TestSuite.add(test_case, [:two, :tags]))
      catch_error(%TestSuite{} |> TestSuite.add(test_case, "two"))
      catch_error(%TestSuite{} |> TestSuite.add(test_case, ['yes', 0]))
    end

    test "adding a test with a tag is different then adding it without tag" do
      test_case = fn -> nil end

      assert %TestSuite{} |> TestSuite.add(test_case) !=
               %TestSuite{} |> TestSuite.add(test_case, :tag)
    end

    test "adding a test with a tag is different then adding it with another tag" do
      test_case = fn -> nil end

      assert %TestSuite{} |> TestSuite.add(test_case, :tag) !=
               %TestSuite{} |> TestSuite.add(test_case, :another)
    end
  end

  describe "TestSuite.size/1" do
    test "works only with test suite" do
      assert 0 == %TestSuite{} |> TestSuite.size()
      catch_error(TestSuite.size(nil))
    end

    test "resturns 0 for newly created empty set" do
      assert 0 == TestSuite.new() |> TestSuite.size()
      assert 0 == %TestSuite{} |> TestSuite.size()
      assert 0 == TestSuite.new([]) |> TestSuite.size()
    end

    test "returns 1 for a test suite create with a function" do
      test_case = fn -> nil end
      assert 1 == TestSuite.new(test_case) |> TestSuite.size()
    end

    test "returns same number as the length of the list used to create the test suite" do
      {test_suite, size} = test_suite_with_size()

      assert size == TestSuite.size(test_suite)
    end

    test "adding a test to a test sute changes its size by 1" do
      test_case = fn -> nil end
      assert 1 == %TestSuite{} |> TestSuite.add(test_case) |> TestSuite.size()
      {test_suite, size} = test_suite_with_size()
      assert size + 1 == test_suite |> TestSuite.add(test_case) |> TestSuite.size()
    end

    test "adding tests to empty test suite is the same as creating a test suite with the same list" do
      test_case = fn -> nil end
      {list, _} = list_of_funcs_with_size()

      assert TestSuite.new(test_case) == TestSuite.new() |> TestSuite.add(test_case)

      assert TestSuite.new(list) == TestSuite.new() |> TestSuite.add(list)
    end

    test "adding a list of tests to a test suite changes its size with the length of the list" do
      test_case = fn -> nil end

      test_suite_with_size_one = TestSuite.new(test_case)
      assert 2 == test_suite_with_size_one |> TestSuite.add([test_case]) |> TestSuite.size()

      {list, list_length} = list_of_funcs_with_size()

      assert list_length + 1 ==
               test_suite_with_size_one |> TestSuite.add(list) |> TestSuite.size()

      {test_suite, size} = test_suite_with_size()
      assert size + 1 == test_suite |> TestSuite.add([test_case]) |> TestSuite.size()

      assert size + list_length == test_suite |> TestSuite.add(list) |> TestSuite.size()
    end
  end

  describe "TestSuite.size/2" do
    test "returns same as TestSuite.size/1 if give keyword list that does not contain :only or :exclude" do
      {test_suite, _} = test_suite_with_size()
      assert TestSuite.size(test_suite) == TestSuite.size(test_suite, [])
      assert TestSuite.size(test_suite) == TestSuite.size(test_suite, pesho: :ne)
    end

    test "returns 0 when all test are tagged with nothing and we pass :only option" do
      {test_suite, _} = test_suite_with_size()
      assert 0 == TestSuite.size(test_suite, only: :tag)
    end

    test "returns the size of the test suite when all test are tagged with nothing and we pass :exclude option" do
      {test_suite, size} = test_suite_with_size()
      assert size == TestSuite.size(test_suite, exclude: :tag)
    end

    test "returns the number of the tests tagged with the tag passed to :only" do
      {list, list_size} = list_of_funcs_with_size()
      {test_suite, _} = test_suite_with_size()

      assert list_size * 2 ==
               test_suite
               |> TestSuite.add(list, [:tag, :some_other_tag])
               |> TestSuite.add(list, [:some_other_tag])
               |> TestSuite.add(list, [:tag])
               |> TestSuite.size(only: :tag)
    end

    test "returns the number of the tests not tagged with the tag passed to :exclude" do
      {list, list_size} = list_of_funcs_with_size()
      {test_suite, size} = test_suite_with_size()

      assert list_size + size ==
               test_suite
               |> TestSuite.add(list, [:tag, :some_other_tag])
               |> TestSuite.add(list, [:some_other_tag])
               |> TestSuite.add(list, [:tag])
               |> TestSuite.size(exclude: :tag)
    end

    test "returns the number of the tests not tagged with the tag passed to :exclude but tagged with the tag passed to :only" do
      {list, list_size} = list_of_funcs_with_size()
      {test_suite, _} = test_suite_with_size()

      assert list_size ==
               test_suite
               |> TestSuite.add(list, [:tag, :some_other_tag])
               |> TestSuite.add(list, [:some_other_tag])
               |> TestSuite.add(list, [:tag])
               |> TestSuite.size(only: :tag, exclude: :some_other_tag)
    end

    test "returns the same result when :exclude and :only are interchanged" do
      {list, _} = list_of_funcs_with_size()

      test_suite =
        TestSuite.new()
        |> TestSuite.add(list, [:tag, :some_other_tag])
        |> TestSuite.add(list |> tl(), [:some_other_tag])
        |> TestSuite.add(list |> tl() |> tl(), [:tag])

      assert TestSuite.size(test_suite, only: :tag, exclude: :some_other_tag) ==
               TestSuite.size(test_suite, exclude: :some_other_tag, only: :tag)
    end

    test "works properly when :exclude and :only are interleaved with other keywords" do
      {list, _} = list_of_funcs_with_size()

      test_suite =
        TestSuite.new()
        |> TestSuite.add(list, [:tag, :some_other_tag])
        |> TestSuite.add(list |> tl(), [:some_other_tag])
        |> TestSuite.add(list |> tl() |> tl(), [:tag])

      assert TestSuite.size(test_suite, only: :tag, echo: :echo, exclude: :some_other_tag) ==
               TestSuite.size(test_suite, exclude: :some_other_tag, echo: :echo, only: :tag)
    end
  end

  describe "TestSuite.run/2" do
    test "can run a test suite" do
      assert_is_test_sute(%TestSuite{} |> TestSuite.run())
      assert_is_test_sute(TestSuite.new(fn -> nil end) |> TestSuite.run())
    end

    test "treats test that returns `nil` or `false` as failed" do
      TestSuite.new([fn -> nil end, fn -> false end])
      |> TestSuite.run()
      |> assert_tests_states_after_run(failed: 2)
    end

    test "treats test that rises and error as failed" do
      TestSuite.new([fn -> raise "error" end])
      |> TestSuite.run()
      |> assert_tests_states_after_run(failed: 1)
    end

    test "treats test that returns `true` as passed" do
      TestSuite.new([fn -> true end])
      |> TestSuite.run()
      |> assert_tests_states_after_run(passed: 1)
    end

    test "treats test that returns term different then `nil`, `false` or `true` as passed" do
      TestSuite.new([fn -> 1 end, fn -> :ala end, fn -> "bala" end])
      |> TestSuite.run()
      |> assert_tests_states_after_run(passed: 3)
    end

    test "by default treats test that run for more then 5 seconds as timed_out" do
      TestSuite.new(fn -> Process.sleep(5100) end)
      |> TestSuite.run()
      |> assert_tests_states_after_run(timed_out: 1)
    end

    test "can change the timeout for a test" do
      TestSuite.new(fn -> Process.sleep(5000) end)
      |> TestSuite.run(timeout: 100)
      |> assert_tests_states_after_run(timed_out: 1)
    end

    test "can change the timeout to infinity" do
      TestSuite.new(fn -> Process.sleep(500) end)
      |> TestSuite.run(timeout: :infinity)
      |> assert_tests_states_after_run(passed: 1)
    end

    test "can skip test that are not tagged with the tag given to :only" do
      %TestSuite{}
      |> TestSuite.add(fn -> true end, [:first, :second])
      |> TestSuite.add(fn -> true end, [:first])
      |> TestSuite.add(fn -> true end, [:second])
      |> TestSuite.run(only: :first)
      |> assert_tests_states_after_run(passed: 2, skipped: 1)
    end

    test "can skip test that are tagged with the tag given to :exclude" do
      %TestSuite{}
      |> TestSuite.add(fn -> true end, [:first, :second])
      |> TestSuite.add(fn -> true end, [:first])
      |> TestSuite.add(fn -> true end, [:second])
      |> TestSuite.run(exclude: :first)
      |> assert_tests_states_after_run(passed: 1, skipped: 2)
    end

    test "can comply both to exclude and only" do
      %TestSuite{}
      |> TestSuite.add(fn -> true end, [:first, :second])
      |> TestSuite.add(fn -> true end, [:first, :third])
      |> TestSuite.add(fn -> true end, [:second])
      |> TestSuite.run(only: :first, exclude: :third)
      |> assert_tests_states_after_run(passed: 1, skipped: 2)
    end

    test "when used on test suite with passed tests runs only the tests that are not passed" do
      {:ok, pid} = Agent.start(fn -> 0 end)

      %TestSuite{}
      |> TestSuite.add(fn ->
        Agent.update(pid, fn n -> n + 1 end)
        true
      end)
      |> TestSuite.add(fn ->
        Agent.update(pid, fn n -> n + 1 end)
        false
      end)
      |> TestSuite.run()
      |> assert_tests_states_after_run(passed: 1, failed: 1)
      |> TestSuite.run()
      |> assert_tests_states_after_run(passed: 1, failed: 1)

      times_aclled = Agent.get(pid, fn n -> n end)
      assert times_aclled == 3
    end
  end

  describe "TestSuite.ran?/1" do
    test "returns false for newly create TestSuite" do
      refute TestSuite.new() |> TestSuite.ran?()
      {test_suite, _} = test_suite_with_size()
      refute TestSuite.ran?(test_suite)
    end

    test "returns true on a test_suite that was returned by run" do
      assert TestSuite.new() |> TestSuite.run() |> TestSuite.ran?()
      {test_suite, _} = test_suite_with_size()
      assert test_suite |> TestSuite.run() |> TestSuite.ran?()
    end

    test "returns false if test suite is returned by a filter" do
      {test_suite, _} = test_suite_with_size()
      ran_test_suite = test_suite |> TestSuite.run()
      refute ran_test_suite |> TestSuite.passed() |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.pending() |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.failed() |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.timed_out() |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.skipped() |> TestSuite.ran?()
    end

    test "returns false if the test suite is returned by add" do
      {test_suite, _} = test_suite_with_size()
      ran_test_suite = test_suite |> TestSuite.run()

      func = fn -> nil end

      refute ran_test_suite |> TestSuite.add([]) |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.add(func) |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.add([func], [:tag, :more_tags]) |> TestSuite.ran?()
      refute ran_test_suite |> TestSuite.add(func, :tag) |> TestSuite.ran?()
    end
  end

  describe "Inspect.TestSuite.inspect/2" do
    test "properly displays empty test suite" do
      assert "#TestSuite<0 tests>" == %TestSuite{} |> inspect()
    end

    test "properly displays singular form of test in a test suite with only one test" do
      assert TestSuite.new(fn -> nil end) |> inspect() =~ ~r/#TestSuite<1 test:[PTFS.]>/
    end

    test "properly displays pending test in a test suite" do
      func = fn -> nil end
      assert "#TestSuite<2 tests:PP>" == TestSuite.new([func, func]) |> inspect()
    end

    test "properly displays failed tests in a test suite" do
      func = fn -> nil end

      assert "#TestSuite<2 tests:FF>" ==
               TestSuite.new([func, func]) |> TestSuite.run() |> inspect()
    end

    test "properly displays passed tests in a test suite" do
      func = fn -> true end

      assert "#TestSuite<2 tests:..>" ==
               TestSuite.new([func, func]) |> TestSuite.run() |> inspect()
    end

    test "properly displays skipped tests in a test suite" do
      assert "#TestSuite<2 tests:SS>" ==
               %TestSuite{}
               |> TestSuite.add(fn -> true end, [])
               |> TestSuite.add(fn -> true end, [:to_include, :to_exclude])
               |> TestSuite.run(exclude: :to_exclude, only: :to_include)
               |> inspect()
    end

    test "properly displays timed out tests in a test suite" do
      func = fn -> Process.sleep(2000) end

      assert "#TestSuite<2 tests:TT>" ==
               TestSuite.new([func, func])
               |> TestSuite.run(timeout: 10)
               |> inspect()
    end
  end

  defp list_of_funcs_with_size() do
    size = :rand.uniform(100) + 5

    list =
      fn -> fn -> nil end end
      |> Stream.repeatedly()
      |> Enum.take(size)

    {list, size}
  end

  defp test_suite_with_size() do
    {list, size} = list_of_funcs_with_size()

    {TestSuite.new(list), size}
  end

  defp assert_is_test_sute(test_suite) do
    assert %TestSuite{} = test_suite
  end

  @assertion_map %{skipped: 0, timed_out: 0, passed: 0, failed: 0, pending: 0}
  defp assert_tests_states_after_run(test_suite, list) do
    test_suite
    |> do_assert_tests_states_after_run(list |> Enum.into(@assertion_map))
  end

  defp do_assert_tests_states_after_run(test_suite, states) do
    assert states.passed == test_suite |> TestSuite.passed() |> TestSuite.size()
    assert states.failed == test_suite |> TestSuite.failed() |> TestSuite.size()
    assert states.timed_out == test_suite |> TestSuite.timed_out() |> TestSuite.size()
    assert states.skipped == test_suite |> TestSuite.skipped() |> TestSuite.size()
    assert states.pending == test_suite |> TestSuite.pending() |> TestSuite.size()
    test_suite
  end
end
