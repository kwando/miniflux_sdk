import gleam/bool
import gleam/dynamic/decode
import gleam/function
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri

pub type Category {
  Category(id: Int, user_id: Int, title: String)
}

pub type Entry {
  Entry(
    id: Int,
    user_id: Int,
    feed_id: Int,
    title: String,
    url: String,
    content: String,
    status: String,
    starred: Bool,
    reading_time: Int,
  )
}

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
    Some(value) -> [#(key, mapper(value)), ..list]
    None -> list
  }
}

pub fn entry_decoder() -> decode.Decoder(Entry) {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use feed_id <- decode.field("feed_id", decode.int)
  use title <- decode.field("title", decode.string)
  use url <- decode.field("url", decode.string)
  use content <- decode.field("content", decode.string)
  use status <- decode.field("status", decode.string)
  use starred <- decode.field("starred", decode.bool)
  use reading_time <- decode.field("reading_time", decode.int)
  decode.success(Entry(
    id:,
    user_id:,
    feed_id:,
    title:,
    url:,
    content:,
    status:,
    starred:,
    reading_time:,
  ))
}

pub fn get_entries_response_decoder(response: Response(String)) {
  use <- expect_http_status(response, 200)

  json.parse(
    response.body,
    decode.at(["entries"], decode.list(entry_decoder())),
  )
  |> result.map_error(CannotDecodeJson)
}

pub opaque type Client {
  Client(
    base_path: String,
    host: String,
    scheme: http.Scheme,
    port: Option(Int),
    api_key: String,
  )
}

pub type Error {
  CannotParseUrl
  CannotDecodeJson(json.DecodeError)
  InvalidScheme
  Unauthorized(response: Response(String))
  UnexpectedHttpStatus(response: Response(String))
}

pub fn from_url(base_url, api_key: String) {
  use url <- result.try(
    uri.parse(base_url)
    |> result.replace_error(CannotParseUrl),
  )
  use scheme <- result.try(case url.scheme {
    Some("https") -> Ok(http.Https)
    Some("http") -> Ok(http.Http)
    None -> Ok(http.Http)
    Some(_) -> Error(InvalidScheme)
  })

  Client(
    base_path: url.path,
    host: url.host |> option.unwrap("localhost"),
    scheme:,
    port: url.port,
    api_key:,
  )
  |> Ok
}

fn category_decoder() -> decode.Decoder(Category) {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use title <- decode.field("title", decode.string)
  decode.success(Category(id:, user_id:, title:))
}

pub type Feed {
  Feed(
    id: Int,
    user_id: Int,
    title: String,
    site_url: String,
    feed_url: String,
    disabled: Bool,
    category: Category,
  )
}

fn feed_decoder() -> decode.Decoder(Feed) {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use title <- decode.field("title", decode.string)
  use site_url <- decode.field("site_url", decode.string)
  use feed_url <- decode.field("feed_url", decode.string)
  use disabled <- decode.field("disabled", decode.bool)
  use category <- decode.field("category", category_decoder())
  decode.success(Feed(
    id:,
    user_id:,
    title:,
    site_url:,
    feed_url:,
    disabled:,
    category:,
  ))
}

pub fn get_feeds_response_decoder(
  response: Response(String),
) -> Result(List(Feed), Error) {
  use <- expect_http_status(response, 200)
  response.body
  |> json.parse(decode.list(feed_decoder()))
  |> result.map_error(CannotDecodeJson)
}

fn expect_http_status(response: Response(String), status, continue) {
  case response.status {
    actual_status if actual_status == status -> continue()
    401 -> Error(Unauthorized(response))
    _ -> Error(UnexpectedHttpStatus(response))
  }
}

pub fn get_feeds_request(client: Client) {
  http_get(client, "/v1/feeds", [])
}

pub fn get_entries_request(client: Client, filter: EntryFilter) {
  http_get(client, "/v1/entries", entry_filter_to_list(filter))
}

fn http_get(client: Client, path: String, query: List(#(String, String))) {
  request.Request(
    method: http.Get,
    headers: [
      #("accept", "application/json"),
      #("x-auth-token", client.api_key),
    ],
    body: "",
    scheme: client.scheme,
    host: client.host,
    port: client.port,
    path: client.base_path <> path,
    query: case query {
      [] -> None
      list -> Some(uri.query_to_string(list))
    },
  )
}

pub fn get_categories(client: Client) -> request.Request(String) {
  http_get(client, "/v1/categories", [])
}

pub fn get_categories_response_decoder(
  response: Response(String),
) -> Result(List(Category), Error) {
  use <- expect_http_status(response, 200)
  json.parse(response.body, decode.list(category_decoder()))
  |> result.map_error(CannotDecodeJson)
}
