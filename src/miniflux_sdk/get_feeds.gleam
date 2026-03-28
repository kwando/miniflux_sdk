import gleam/dynamic/decode
import gleam/http/response
import gleam/option.{type Option}
import miniflux_sdk

pub type EntryStatus {
  Read
  Unread
  Removed
}

pub type EntryFilter {
  EntryFilter(
    status: List(EntryStatus),
    limit: Option(Int),
    offset: Option(Int),
    starred: Option(Bool),
    search: Option(String),
    category: Option(Int),
  )
}

pub fn request(client: miniflux_sdk.Client) {
  miniflux_sdk.http_get(client, "/v1/feeds", [])
}

pub fn decoder(response: response.Response(String)) {
  use <- miniflux_sdk.expect_http_status(response, 200)
  miniflux_sdk.decode_json(response, decode.list(miniflux_sdk.feed_decoder()))
}
