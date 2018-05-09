# TestSuite

Задачата е да напишете модул с име `TestSuite`, в който да дефинирате структура, която ще държи набор от тестов.

Тестовете са анонимни функции с арност 0, или хванати именовани функции с `&/1`(capture operator).
Тест се смята за неуспешен, ако след изпълнението си функцията върне `false`, `nil` или хвърли грешка.
Ако функцията върне нещо различно от `false` или `nil`, то съответният тест е успешен.

Всъщност един тест може да има 5 различни състояния:

  1. Преди да бъде пуснат - ще го бележим с `:pending`
  2. Успешен - `:passed`
  3. Провалил се - `:failed`
  4. Пропуснат - `:skipped`
  5. Не завършил за дадено време - `:timed_out`

## Функции, които TestSuite трябва да съдържа.

#### TestSuite.new()

Създава нов празен `TestSuite`, аналогично на `%TestSuite{}`

```elixir
TestSuite.new() == %TestSuite{}
# => true
```
#### TestSuite.new(initial_tests)
Създава `TestSuite`, който съдържа всички тестове от `initial_tests`.
Ако тестовете са повече от един, то те се добавят в реда, в който ги виждаме. (Това ще е от значение по-нататък и важи също за следващата функция).

```elixir
# Всеки тест е проста анонимна функция.
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

TestSuite.new([f, g])
```

#### TestSuite.add(test_suite, to_add):
`to_add` е една анонимна функция или списък от няколко такива.

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

TestSuite.new() |> TestSuite.add(f)
TestSuite.new() |> TestSuite.add([f, g])
```

#### TestSuite.add(test_suite, to_add, tags)

Вторият параметър е същия, като при `TestSuite.add/2`.
Третият съдържа списък от атоми или един атом, това са таговете на добавените тестове чрез тази функция.
Таговете ще използваме по-късно за да филтрираме тестовете при изпълнението на други функции.

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

TestSuite.new() |> TestSuite.add(f, [:slow, :do_not_run])
TestSuite.new() |> TestSuite.add([f, g], :maybe)
```

#### TestSuite.size(test_suite)

Връща размера на TestSuite-а (броя на тестовете в него).

```
TestSuite.new() |> TestSuite.size()
# => 0
TestSuite.new([fn -> true end]) |> TestSuite.size()
# => 1
```

#### TestSuite.size(test_suite, options)

Връща броя на тестовете филтрирани чрез аргумента `options`.
`options` е асоциативен списък, който може да съдържа следните "филтри":
  - `:only` - ако има такава опция се връща броя на тестовете с даден таг

```elixir
TestSuite.new()
|> TestSuite.add(fn -> true end, :always_true)
|> TestSuite.add([fn -> false end, fn -> nil end], :never_true)
|> TestSuite.size(only: :never_true)
#=> 2
```
  - `:exclude` - ако има такава опция се връща броя на тестовете, които не съдържат даден таг

```elixir
TestSuite.new()
|> TestSuite.add(fn -> true end, :always_true)
|> TestSuite.add([fn -> false end, fn -> nil end], :never_true)
|> TestSuite.size(exclude: :never_true)
#=> 1
```
 - можем да комбинираме двете например:

```elixir
TestSuite.new()
|> TestSuite.add(fn -> true end, :true)
|> TestSuite.add(fn -> false end, :false)
|> TestSuite.add(fn -> rem(:rand.uniform(), 2) == 0 end, [:true, :false])
|> TestSuite.size(only: :true, exclude: :false)
#=> 1
```
#### TestSuite.run(test_suite, options \\\\ [])

Изпълнява тестовете и връща модифицирана `TestSuite` с информация за изпълнените тестове.
Информация ще ни трябва по-нататък.

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

TestSuite.new()
|> TestSuite.add(f) # Ще бъде маркиран, като :passed
|> TestSuite.add(g) # Ще бъде маркиран, като :failed
|> TestSuite.run()
```

Първите две опции са като при `TestSuite.size/2` (`:only`, `:exclude`), като всеки тест, който бъде филтриран не се изпълнява, а се маркира, катo `:skipped`

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

TestSuite.new()
|> TestSuite.add(f, :first) # Ще се изпълни
|> TestSuite.add(g, :second) # Ще бъде маркиран, като пропуснат
|> TestSuite.run(only: :first)
```

Другата опция за изпълнението на тестовете е `:timeout` (тя има дефаултна стойност 5000 ms)

Ако един тест работи повече от това време той бива маркиран като `:timed_out`

```elixir
f = fn ->
  Process.sleep(2000)
  true
end

TestSuite.new()
|> TestSuite.add(f) # Ще бъде маркиран, като :timed_out
|> TestSuite.run(timeout: 500)

TestSuite.new()
|> TestSuite.add(f) # Ще бъде маркиран, като :passed
|> TestSuite.run(timeout: 5000)
```
Можем да run-нем `TestSuite`, който е върнат от `run`, в такъв случай ще изпълним само функциите, които не са маркирани, като `:passed`

Всъщност се очаква да има функции `timed_out`, `failed` и `skipped`, които правят същото като `passed`, но за съответните състояния.

#### TestSuite.passed(test_suite)
Връща нов `TestSuite` съдържащ само тестовете, които са били изпълнени и са били успешни

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end

passed =
TestSuite.new()
|> TestSuite.add(f)
|> TestSuite.add(g)
|> TestSuite.run()
|> TestSuite.passed()
|> TestSuite.size()

TestSuite.size(passed) # passed съдържа само "теста" f, който е отбелязан като :passed
#=> 1
```
#### TestSuite.failed(test_suite)
#### TestSuite.timed_out(test_suite)
#### TestSuite.skipped(test_suite)
#### TestSuite.pending(test_suite)

Последните 4 са аналогични на `TestSuite.passed/1`, но за съответните тест статуси.

#### TestSuite.ran?(test_suite)

Връща `true`, ако TestSuite-а е върнат от `TestSuite.run/2`

```elixir
TestSuite.new() |> TestSuite.ran?() # => false

TestSuite.new() |> TestSuite.run() |> TestSuite.ran?() # => true

TestSuite.new()
|> TestSuite.run()
|> TestSuite.add(fn -> true end)
|> TestSuite.ran?() # => false
```
#### TestSuite.reset(test_suite)

Връща нов `TestSuite` подобен на входния, само че всички тестове са отбелязани, като `:pending`.

```elixir
reset_suite =
TestSuite.new(fn -> true end)
|> TestSuite.run()
|> TestSuite.reset()

reset_suite
|> TestSuite.size()
#=> 1

reset_suite
|> TestSuite.pending()
|> TestSuite.size()
#=> 1
```

### Протоколът `Inspect`

Трябва да имплементирате протокола [`Inspect`](https://hexdocs.pm/elixir/Inspect.html#content) за структурата `TestSuite`

Когато "инспектираме" един празен `TestSuite`, той трябва да получим следния резултат:

```elixir
t = TestSuite.new()

inspect(t) #=> "#TestSuite<0 tests>"
```

Ако имаме тестове нещата са малко по различни

```elixir
f = fn -> 3 == 3 end
g = fn -> 3 == 4 end
h = fn -> Process.sleep(1000) end
j = fn -> true end

test_suite =
TestSuite.new()
|> TestSuite.add(f)
|> TestSuite.add(g)
|> TestSuite.add(h)
|> TestSuite.add(j, :skip)
|> TestSuite.run(exclude: :skip, timeout: 500)
|> TestSuite.add(fn -> nil end)
|> inspect()

inspect(test_suite)
#=> "#TestSuite<5 tests:.FTSP>"
```

Където всеки успешен тест е отбелязан с ".", всеки провали се - с "F", всеки пропуснат - със "S", всеки, който не е минал за допустимо време - "T" и всеки още не е изпълнен - с "P"

Реда в който показваме резултатите е същият в който са били добавени в `TestSuite`-a.

# Бонус точки

Добавете опция на `:parallel` брой на тестове, които да се изпълняват конкурентно.
Имплементирайте схема за паралелизиране на тестовете.
