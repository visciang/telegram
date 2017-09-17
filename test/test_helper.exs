ExUnit.start(capture_log: true)

Code.require_file "utils.ex", __DIR__
Application.ensure_all_started(:bypass)
