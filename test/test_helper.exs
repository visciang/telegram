ExUnit.start(capture_log: true)

Code.require_file("utils.ex", __DIR__)
Code.require_file("good_bot.ex", __DIR__)
Code.require_file("purge_bot.ex", __DIR__)

Application.ensure_all_started(:bypass)
