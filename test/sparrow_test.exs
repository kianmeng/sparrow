defmodule SparrowTest do
  use Sparrow.Case, async: false

  doctest Sparrow

  describe "#capture" do
    test "sends event to Sentry" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(url, _headers, body, _opts) ->
        assert url == "https://sentry.host/api/store/"
        assert %{"message" => ^message, "project" => "42"} = decode(body)

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://p:s@sentry.host/42")
    end

    test "contains stacktrace started from current location" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert %{"stacktrace" => %{"frames" => stacktrace}} = decode(body)

        assert [
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "anonymous fn/4 in ExUnit.Runner.spawn_test_monitor/4", "lineno" => 306, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "timer.erl", "function" => ":timer.tc/1", "lineno" => 166, "module" => ":timer", "vars" => %{}},
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "ExUnit.Runner.exec_test/1", "lineno" => 355, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "test/sparrow_test.exs", "function" => "SparrowTest.\"test #capture contains stacktrace started from current location\"/1", "lineno" => 34, "module" => "SparrowTest", "vars" => %{}}
        ] == stacktrace

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test")
    end

    test "with custom stacktrace" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert json = decode(body)
        refute Map.get(json, "stacktrace")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test", stacktrace: [])
    end

    test "sends event to Sentry with public and secret keys" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(_url, headers, _body, _opts) ->
        assert {"X-Sentry-Auth", sentry_auth} = List.keyfind(headers, "X-Sentry-Auth", 0)
        assert [_version, _client, _time, " sentry_key=public", " sentry_secret=secret"] = String.split(sentry_auth, ",")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://public:secret@sentry.local/42")
    end

    test "sends event to Sentry with public key only" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(_url, headers, _body, _opts) ->
        assert {"X-Sentry-Auth", sentry_auth} = List.keyfind(headers, "X-Sentry-Auth", 0)
        assert [_version, _client, _time, " sentry_key=public"] = String.split(sentry_auth, ",")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://public@sentry.local/42")
    end

    test "sends event to Sentry through proxy" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(url, _headers, body, _opts) ->
        assert url == "http://proxy/service/suffix/api/store/"
        assert %{"project" => "31"} = decode(body)

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "http://public:secret@proxy/service/suffix/31")
    end
  end

  defp decode(binary) do
    binary |> Base.decode64!() |> :zlib.uncompress() |> Jason.decode!()
  end
end
