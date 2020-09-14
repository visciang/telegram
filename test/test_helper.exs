"#{__DIR__}/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)

ExUnit.start(capture_log: true)
Test.Utils.Mock.tesla_mock_global_async()
