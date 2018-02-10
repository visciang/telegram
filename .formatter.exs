# Used by "mix format" and to export configuration.
export_locals_without_parens = [
  command: :*,
  message: 1,
  edited_message: 1,
  channel_post: 1,
  edited_channel_post: 1,
  callback_query: 1,
  shipping_query: 1,
  pre_checkout_query: 1,
  inline_query: 2,
  chosen_inline_result: 2,
  any: 1
]

[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
  ],
  locals_without_parens: export_locals_without_parens,
  import_deps: [:tesla],
  export: [locals_without_parens: export_locals_without_parens]
]