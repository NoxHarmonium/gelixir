# Gelixir

A toy project to learn about Elixir and actor concurrency.
The theme of the project is tracking the GPS coords
of a large amount of clients
and sharing them with other clients
without having a bottleneck of a proxy single actor.
The name comes from a portmanteau of the words 'geo' and 'Elixir'.

### Goals:

- Create a simple server that can accept any number of tcp clients. ✓
- Store and update the state (location, name, user agent) of a client.
- Register clients with a local hub that keeps them up to date with the addresses of nearby clients.
- Get clients to update other nearby clients with their state without an intermediate actor.
- Run a test with a massive amount of connections.
- Bonus: Write the same thing in something I'm more familiar with (e.g. Node) and compare performance.



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gelixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gelixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gelixir](https://hexdocs.pm/gelixir).

