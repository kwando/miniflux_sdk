import gleam/http/response
import gleam/int
import miniflux_sdk

pub fn request(client, feed_id) {
  miniflux_sdk.http_put(
    client,
    "/v1/feeds/" <> int.to_string(feed_id) <> "/refresh",
    "",
  )
}

pub fn decoder(response: response.Response(String)) {
  use <- miniflux_sdk.expect_http_status(response, 204)
  Ok(Nil)
}
