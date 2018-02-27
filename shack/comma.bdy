commands
  foo,bar
    flow
      for -h
        .show-usage
    definition
      ARG
        some argument
      --*help
        shows usage details for this command
    usage
      short
        foo ARG
      full
        Foo a bar
