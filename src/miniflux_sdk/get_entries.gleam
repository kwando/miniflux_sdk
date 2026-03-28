import gleam/bool
import gleam/dynamic/decode
import gleam/function
import gleam/http/response
import gleam/int
import gleam/list
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

pub fn request(client: miniflux_sdk.Client, filter: EntryFilter) {
  miniflux_sdk.http_get(client, "/v1/entries", entry_filter_to_list(filter))
}

pub fn decoder(response: response.Response(String)) {
  use <- miniflux_sdk.expect_http_status(response, 200)
  miniflux_sdk.decode_json(
    response,
    decode.at(["entries"], decode.list(miniflux_sdk.entry_decoder())),
  )
}

fn entry_filter_to_list(filter: EntryFilter) {
  list.map(filter.status, fn(status) {
    #("status", case status {
      Read -> "read"
      Unread -> "unread"
      Removed -> "removed"
    })
  })
  |> append_if("limit", filter.limit, int.to_string)
  |> append_if("offset", filter.offset, int.to_string)
  |> append_if("starred", filter.starred, bool.to_string)
  |> append_if("search", filter.search, function.identity)
  |> append_if("category_id", filter.category, int.to_string)
  |> list.reverse
}

fn append_if(list, key, option: Option(opt), mapper: fn(opt) -> String) {
  case option {
    option.Some(value) -> [#(key, mapper(value)), ..list]
    option.None -> list
  }
}
