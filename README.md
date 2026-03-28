# miniflux_sdk

A Gleam SDK for interacting with the [Miniflux](https://miniflux.app/) RSS reader API.

[![Package Version](https://img.shields.io/hexpm/v/miniflux_sdk)](https://hex.pm/packages/miniflux_sdk)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/miniflux_sdk/)

As of know only a tiny subset of the API is implemented and not all fields are
decoded. If you need something more just make a PR.

## Installation

```sh
gleam add miniflux_sdk
```

## Usage

```gleam
import miniflux_sdk
import miniflux_sdk/get_entries

pub fn main() {
  let client = miniflux_sdk.client_from_url("https://miniflux.example.com", "your-api-key")

  let request = get_entries.request(client, get_entries.EntryFilter(status: [get_entries.Unread], limit: None, offset: None, starred: None, search: None, category: None))

  // Send request the request with your HTTP-client of choice
  let assert Ok(response) = httpc.send(request)

  // Handle the response
  let assert Ok(entries) = get_entries.decoder(response)
}
```

## API

### Client

- `client_from_url(base_url, api_key)` - Create a client from a Miniflux URL and API key

### Types

- `Client` - Opaque type for making API requests
- `Category` - Represents a category
- `Feed` - Represents a feed
- `Entry` - Represents an entry/article
- `Error` - Error types (`CannotParseUrl`, `CannotDecodeJson`, `InvalidScheme`, `Unauthorized`, `UnexpectedHttpStatus`)

### Modules

- `get_entries` - Fetch entries with filtering options
- `get_feeds` - Fetch all feeds
- `get_categories` - Fetch all categories
- `refresh_feed` - Refresh a single feed
- `refresh_all_feeds` - Refresh all feeds

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam docs  # Build documentation
```
