ExUnit.start(capture_log: true)

"#{__DIR__}/**/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.require_file/1)
