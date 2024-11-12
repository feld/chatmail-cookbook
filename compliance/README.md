# compliance

This directory contains Cinc Auditor profile, waiver and input objects which are used with the Cinc Infra Compliance Phase.

Detailed information on the Cinc Infra Compliance Phase can be found in the [Chef Documentation](https://docs.chef.io/chef_compliance_phase/).

```plain
./compliance
├── inputs
├── profiles
└── waivers
```

Use the `cinc generate` command from Cinc Workstation to create content for these directories:

```sh
# Generate a Cinc Auditor profile
cinc generate profile PROFILE_NAME

# Generate a Cinc Auditor waiver file
cinc generate waiver WAIVER_NAME

# Generate a Cinc Auditor input file
cinc generate input INPUT_NAME
```
