defprotocol Mechanize.HTMLParser.Parseable do
  @moduledoc false

  def parser(parseable)
  def parser_data(parseable)
  def page(parseable)
end
