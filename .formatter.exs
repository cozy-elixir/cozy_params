# Used by "mix format"
[
  import_deps: [:ecto],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    defparams: :*,
    params: :*
  ],
  export: [
    locals_without_parens: [
      defparams: :*,
      params: :*
    ]
  ]
]
