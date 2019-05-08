defmodule Integration.GenServerTest do
  use Sparrow.IntegrationCase, async: false

  alias Sparrow.Support.GenServer, as: GS

  describe "crashed with" do
    setup do
      {:ok, pid} = GS.start_link()
      {:ok, pid: pid}
    end

    test "exit", %{pid: pid} do
      send(pid, :exit)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}",
           value: "(exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (sparrow) test/support/errors/gen_server.ex:21: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{vars: %{}, filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib"},
          %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: 711, module: ":gen_server", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
        ]

      assert report.exception ==
        [%{type: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}",
           value: "(exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (sparrow) test/support/errors/gen_server.ex:21: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Last message: :exit
        """)

      assert report.stacktrace.frames ==
        [
          %{vars: %{}, filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib"},
          %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: 711, module: ":gen_server", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
        ]
    end

    test "throw", %{pid: pid} do
      send(pid, :throw)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "{:bad_return_value, :throwed}",
           value: "(exit) bad return value: :throwed"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) bad return value: :throwed
            (stdlib) gen_server.erl:755: :gen_server.handle_common_reply/8
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_common_reply/8", lineno: 755}
        ]

      assert report.exception ==
        [%{type: "{:bad_return_value, :throwed}",
           value: "(exit) bad return value: :throwed"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :throwed
        Last message: :throw
        """)

      assert report.stacktrace.frames == []
    end

    test "raise", %{pid: pid} do
      send(pid, :raise)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (ArgumentError) argument error
            (sparrow) test/support/errors/gen_server.ex:29: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: 711},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
        ]

      assert report.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (ArgumentError) argument error
            (sparrow) test/support/errors/gen_server.ex:29: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Last message: :raise
        """)

      assert report.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: 711, module: ":gen_server", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
        ]
    end

    test "badmatch", %{pid: pid} do
      send(pid, :badmatch)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (MatchError) no match of right hand side value: 2
            (sparrow) test/support/errors/gen_server.ex:33: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: 711},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
        ]

      assert report.exception == [%{type: "{:badmatch, 2}", value: "(exit) {:badmatch, 2}"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (MatchError) no match of right hand side value: 2
            (sparrow) test/support/errors/gen_server.ex:33: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Last message: :badmatch
        """)

      assert report.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: 711, module: ":gen_server", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
        ]
    end

    test "bad_return", %{pid: pid} do
      send(pid, :bad_return)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "{:bad_return_value, :bad_return}",
           value: "(exit) bad return value: :bad_return"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) bad return value: :bad_return
            (stdlib) gen_server.erl:755: :gen_server.handle_common_reply/8
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_common_reply/8", lineno: 755}
        ]

      assert report.exception ==
        [%{type: "{:bad_return_value, :bad_return}",
           value: "(exit) bad return value: :bad_return"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :bad_return
        Last message: :bad_return
        """)

      assert report.stacktrace.frames == []
    end
  end

  describe "GenServer with registered name" do
    setup do
      name = NamedGS

      {:ok, pid} = GS.start_link(name: name)
      {:ok, pid: pid, name: name}
    end

    test "raise", %{pid: pid, name: name} do
      send(pid, :raise)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert crash.message ==
        String.trim("""
        Process #{inspect(name)} (#{inspect(pid)}) terminating
        ** (ArgumentError) argument error
            (sparrow) test/support/errors/gen_server.ex:29: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert crash.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: 711},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
        ]

      assert report.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(name)} terminating
        ** (ArgumentError) argument error
            (sparrow) test/support/errors/gen_server.ex:29: Sparrow.Support.GenServer.handle_info/2
            (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
            (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
            (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
        Last message: :raise
        """)

      assert report.stacktrace.frames ==
        [
          %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: 711, module: ":gen_server", vars: %{}},
          %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: 637, module: ":gen_server", vars: %{}},
          %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
        ]
    end
  end

  describe "GenServer reports" do
    setup do
      {:ok, pid} = GS.start_link()
      send(pid, :bad_return)

      {:ok, pid: pid}
    end

    test "with state, last message and pid", %{pid: pid} do
      assert_receive %Sparrow.Event{
        extra: %{
          last_message: :bad_return, name: ^pid,
          state: %Sparrow.Support.GenServer.State{a: 1, b: 2, c: %{d: []}}
        }
      }
    end

    test "with simple exception" do
      assert_receive %Sparrow.Event{
        exception: [
          %{type: "{:bad_return_value, :bad_return}", value: "(exit) bad return value: :bad_return"}
        ]
      }
    end

    test "with message", %{pid: pid} do
      assert_receive %Sparrow.Event{message: message}

      assert message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :bad_return
        Last message: :bad_return
        """)
    end

    test "without stacktrace" do
      assert_receive %Sparrow.Event{
        stacktrace: %{frames: []}
      }
    end
  end
end