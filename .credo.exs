%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, []}
        ]
      }
    }
  ]
}
