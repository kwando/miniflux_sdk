import birdie
import gleam/http/response
import gleam/list
import gleeunit
import miniflux_sdk
import pprint
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn get_feeds_response_decoder_test() {
  let assert Ok(feeds) =
    json_response_from_file("test/fixtures/get_feeds.json")
    |> miniflux_sdk.get_feeds_response_decoder()

  pprint.format(feeds)
  |> birdie.snap(title: "get_feeds")
}

pub fn get_entry_response_decoder_test() {
  let assert Ok(result) =
    json_response_from_file("test/fixtures/get_entries.json")
    |> miniflux_sdk.get_entries_response_decoder()

  assert list.length(result) == 3
}

pub fn get_categories_response_decoder_test() {
  let assert Ok(result) =
    json_response_from_file("test/fixtures/get_categories.json")
    |> miniflux_sdk.get_categories_response_decoder()

  pprint.format(result)
  |> birdie.snap(title: "get_categories")
}

// --------------------------- [ Helper functions ] --------------------------
fn json_response_from_file(path: String) {
  let assert Ok(content) = simplifile.read(path)
  response.Response(200, [#("content-type", "application/json")], content)
}
