# Changelog

## 2.1.0 (2023-04-30)

- add support of `:redact` field option by @nukosuke

## 2.0.0 (2022-11-20)

### Breaking changes

- `Schema.from/1` returns a map instead of a struct.
- `Schema.from/1` rejects the fields whose value is `nil`, which makes pattern-matching more user-friendly. Checkout [here](https://github.com/cozy-elixir/cozy_params/blob/ed15672501970157782243e7dedf12c9d20c97d7/test/cozy_params_test.exs#L21) and [here](https://github.com/cozy-elixir/cozy_params/blob/ed15672501970157782243e7dedf12c9d20c97d7/test/cozy_params_test.exs#L37).

## 1.1.0 (2022-08-15)

### Enhancements

- add `CozyParams.get_error_messages/2` by @nukosuke
