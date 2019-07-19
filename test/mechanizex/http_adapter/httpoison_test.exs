defmodule Mechanizex.HTTPAdapter.HTTPoisonTest do
  use Mechanizex.HTTPAdapterTest,
    adapter: Mechanizex.HTTPAdapter.Httpoison,
    methods: [:get, :delete, :options, :patch, :post, :put, :head]
end
