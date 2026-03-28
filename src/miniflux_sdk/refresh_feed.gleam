import gleam/http/response
import miniflux_sdk

pub fn request(client) {
  miniflux_sdk.http_put(client, "/v1/feeds/refresh", "")
}

pub fn decoder(response: response.Response(String)) {
  use <- miniflux_sdk.expect_http_status(response, 204)
  Ok(Nil)
}
