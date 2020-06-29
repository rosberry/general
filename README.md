# General

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.2-orange.svg" />
    <a href="https://github.com/yonaskolb/Mint">
          <img src="https://img.shields.io/badge/mint-compatible-brightgreen.svg?style=flat" alt="Mint" />
    </a>
</p>

## Using

1. Copy `.templates` folder to the root directory.
2. Run `general spec` in a project directory. This command will create a spec.
3. Create a module with one of installed templates:

   ```bash
   general -n main -t rsb_mvp_vm_module
   ```

Run `general help` to see available commands and options:

```
OVERVIEW: Generates code from templates.

USAGE: general <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  gen                     Generates modules from templates.
  create                  Creates a new template.
  spec                    Creates a new spec.
  list                    List of available templates.

  See 'general help <subcommand>' for detailed help.
```

To learn more about the configuration file [see the dedicated documentation](/Documentation/GeneralSpec.md).

## Installing
- [Homebrew](https://brew.sh): `brew install rosberry/tap/general`
- [Mint](https://github.com/yonaskolb/Mint): `mint install rosberry/general`
- From source: `make install`

## License

The project is available under the MIT license. See the LICENSE file for more info.
