defmodule TestSuiteTest do
  use ExUnit.Case

  test "0" do
    test =
      TestSuite.new([fn -> 1 + 10 end, fn -> Process.sleep(6_000) end], :ff)
      |> TestSuite.add(fn -> false end, [:ff, :gg])

    assert test |> TestSuite.run() |> inspect =~ ~r/\A#TestSuite<3 tests:.TF>/

    assert TestSuite.size(test, only: :ff) == 3

    assert TestSuite.size(test, exclude: :ff) == 0

    assert TestSuite.size(test, exclude: :gg) == 2

    assert test |> TestSuite.run(only: :gg) |> inspect =~ ~r/\A#TestSuite<3 tests:SSF>/

    assert TestSuite.run(test) |> TestSuite.passed() |> TestSuite.size() == 1

    assert test |> TestSuite.run(only: :gg) |> TestSuite.add(fn -> true end) |> inspect =~
             ~r/\A#TestSuite<4 tests:SSFP>/

    assert test |> TestSuite.run(only: :gg) |> TestSuite.size()

    assert test |> TestSuite.ran?() == false

    assert test |> TestSuite.run(timeout: 7_500) |> TestSuite.ran?() == true

    assert test |> TestSuite.run(timeout: 7_500) |> TestSuite.reset() |> TestSuite.ran?() == false
  end

  test "that you can create test cases" do
    f = fn -> 3 == 3 end
    g = fn -> 3 == 4 end

    TestSuite.new([f, g])
  end

  test "that you can get number of tests" do
    assert TestSuite.new() |> TestSuite.size() == 0
  end

  test "that you can add tests to cases" do
    test_case = TestSuite.new()

    test_case = TestSuite.add(test_case, fn -> 3 = 3 end)

    assert TestSuite.size(test_case) == 1
  end

  test "that you can run tests" do
    TestSuite.new()
    |> TestSuite.add(fn -> 3 = 3 end)
    |> TestSuite.run()
  end

  test "that you can get passed tests" do
    TestSuite.new()
    |> TestSuite.passed()
  end

  test "that it implements inspect" do
    t = TestSuite.new()

    assert inspect(t) =~ ~r/\A#TestSuite<0 tests>/
  end
end
