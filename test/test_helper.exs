ExUnit.start()

Code.require_file "utils.ex", __DIR__
Application.ensure_all_started(:bypass)

# disable pipelining in test
:ok = :httpc.set_options(max_keep_alive_length: 0, max_pipeline_length: 0, max_sessions: 0)
