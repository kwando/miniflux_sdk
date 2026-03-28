//// This library contains functions for talking to the miniflux API. So far only a tiny subset of the API
//// is available.
////
//// You will need an API-key for your instance in order to use this library.
////
//// See [https://miniflux.app](https://miniflux.app)

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import redact/secret.{type Secret}

/// Represents a category in Miniflux.
///
/// Categories are used to organize feeds into groups.
pub type Category {
  Category(id: Int, user_id: Int, title: String)
}

/// Represents an entry (article) in Miniflux.
///
/// An entry is a single article or item from a feed.
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

/// Creates a new Miniflux client from a base URL and API key.
///
/// The base URL should be the full URL of your Miniflux instance,
/// including the scheme (http or https) and any path prefix.
///
/// ## Examples
///
/// ```gleam
/// let client = miniflux_sdk.client_from_url("https://miniflux.example.com", "your-api-key")
/// ```
///
/// ## Errors
///
/// Returns `CannotParseUrl` if the URL cannot be parsed.
/// Returns `InvalidScheme` if the URL scheme is not http or https.
pub fn client_from_url(base_url, api_key: String) {
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
    api_key: secret.new(api_key),
  )
  |> Ok
}

/// Returns a decoder for parsing JSON entries from the Miniflux API.
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

/// Error types that can occur when using the Miniflux SDK.
///
/// - `CannotParseUrl`: The provided URL could not be parsed.
/// - `CannotDecodeJson`: The JSON response could not be decoded.
/// - `InvalidScheme`: The URL scheme is not http or https.
/// - `Unauthorized`: The API key is invalid (HTTP 401).
/// - `UnexpectedHttpStatus`: An unexpected HTTP status was received.
pub type Error {
  CannotParseUrl
  CannotDecodeJson(json.DecodeError)
  InvalidScheme
  Unauthorized(response: Response(String))
  UnexpectedHttpStatus(response: Response(String))
}

/// Returns a decoder for parsing JSON categories from the Miniflux API.
pub fn category_decoder() -> decode.Decoder(Category) {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use title <- decode.field("title", decode.string)
  decode.success(Category(id:, user_id:, title:))
}

/// Represents a feed in Miniflux.
///
/// A feed is a source of entries, such as an RSS or Atom feed.
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

/// Returns a decoder for parsing JSON feeds from the Miniflux API.
pub fn feed_decoder() -> decode.Decoder(Feed) {
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

@internal
pub fn expect_http_status(response: Response(String), status, continue) {
  case response.status {
    actual_status if actual_status == status -> continue()
    401 -> Error(Unauthorized(response))
    _ -> Error(UnexpectedHttpStatus(response))
  }
}

@internal
pub fn decode_json(
  response: Response(String),
  decoder: decode.Decoder(a),
) -> Result(a, Error) {
  json.parse(response.body, decoder)
  |> result.map_error(CannotDecodeJson)
}

/// The Miniflux client used to make API requests.
///
/// This is an opaque type - you create it using `client_from_url`
/// and pass it to the various API functions.
pub opaque type Client {
  Client(
    base_path: String,
    host: String,
    scheme: http.Scheme,
    port: option.Option(Int),
    api_key: Secret(String),
  )
}

@internal
pub fn http_get(client: Client, path: String, query: List(#(String, String))) {
  http_request(client, http.Get, path, query, "")
}

@internal
pub fn http_put(client: Client, path: String, body: String) {
  http_request(client, http.Put, path, [], body)
}

fn http_request(
  client: Client,
  method: http.Method,
  path: String,
  query: List(#(String, String)),
  body: a,
) -> request.Request(a) {
  request.Request(
    method:,
    headers: [
      #("accept", "application/json"),
      #("x-auth-token", secret.expose(client.api_key)),
    ],
    body:,
    scheme: client.scheme,
    host: client.host,
    port: client.port,
    path: client.base_path <> path,
    query: case query {
      [] -> option.None
      list -> option.Some(uri.query_to_string(list))
    },
  )
}
