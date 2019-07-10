ExUnit.start()

{:ok, files} = File.ls("./test/support")

files
|> Enum.filter(&String.ends_with?(&1, [".ex", ".exs"]))
|> Enum.each(&Code.require_file("support/#{&1}", __DIR__))

import Mox

defmock(Mechanizex.HTMLParser.Custom, for: Mechanizex.HTMLParser)
defmock(Mechanizex.HTTPAdapter.Mock, for: Mechanizex.HTTPAdapter)
