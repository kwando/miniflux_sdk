import envoy
import gleam/http/response
import gleam/httpc
import gleam/result
import gleam/string
import miniflux_sdk
import miniflux_sdk/get_categories
import simplifile
import snag

pub fn get_entries_test() {
  let client = create_client()

  let assert Ok(_resp) =
    get_categories.request(client)
    |> echo
    |> httpc.send
    |> echo
    |> result.map(dump_to_file(_, "get_categories.json"))
    |> snag.map_error(string.inspect)
    |> result.try(snagify(get_categories.decoder))
    |> echo
}

fn create_client() {
  let assert Ok(base_url) = envoy.get("MINIFLUX_BASE_URL")
    as "missing MINIFLUX_BASE_URL"
  let assert Ok(api_key) = envoy.get("MINIFLUX_API_KEY")
    as "missing MINIFLUX_API_KEY"

  let assert Ok(client) = miniflux_sdk.client_from_url(base_url, api_key)
  client
}

fn dump_to_file(response: response.Response(String), filename) {
  let _ = simplifile.write(filename, response.body)
  response
}

fn snagify(fun: fn(x) -> Result(a, b)) {
  fn(value) {
    fun(value)
    |> snag.map_error(string.inspect)
  }
}
