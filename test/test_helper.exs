ExUnit.start()

import Mox

defmock(Mechanize.HTMLParser.Custom, for: Mechanize.HTMLParser)
defmock(Mechanize.HTTPAdapter.Custom, for: Mechanize.HTTPAdapter)
