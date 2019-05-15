ExUnit.start()

import Mox

defmock(Mechanizex.HTMLParser.Custom, for: Mechanizex.HTMLParser)
defmock(Mechanizex.HTTPAdapter.Custom, for: Mechanizex.HTTPAdapter)
