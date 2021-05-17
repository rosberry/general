# General
New vision of source code generation. Allows to generate files and automatically add them to project hierarchy by the most easiest way. All you need is to get templates where already declared their place in progect hierarchy and specify spec file where provided default project target. Also you can specify other target if required right in command line.

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.2-orange.svg" />
    <a href="https://github.com/yonaskolb/Mint">
          <img src="https://img.shields.io/badge/mint-compatible-brightgreen.svg?style=flat" alt="Mint" />
    </a>
</p>

## Using

1. Setup templates and spec: 

	```bash
	general setup [-r <templates repo> [-g]
	```
3. Create a module with one of installed templates:

   ```bash
   general -n main -t rsb_mvp_vm_module
   ```

Run `general help` to see available commands and options:

```
OVERVIEW: Generates code from templates.

USAGE: general <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  gen (default)           Generates modules from templates.
  create                  Creates a new template.
  list                    List of available templates.
  setup                   Provides your environment with templates
  config                  Provides an access to config file
  upgrade                 Upgrades general to specified version
```

## Plugins

Now you can create your own executable file and place it under `~/.general/plugins`. The only requirement - this file should provide `--help` option for it and each its public subcommands like swift `ArgumentParser` (see example above). General will find appropriate plugin by command line arguments semantic. 

To learn more about the configuration file [see the dedicated documentation](/Documentation/GeneralSpec.md).

## Installing
- [Homebrew](https://brew.sh): `brew install rosberry/tap/general`
- [Mint](https://github.com/yonaskolb/Mint): `mint install rosberry/general`
- From source: `make install`


## Authors

* Artem Novichkov, artem.novichkov@rosberry.com
* Nikolay Tyunin, nikolay.tyunin@rosberry.com
* Vlad Zhavoronkov, vlad.zhavoronkov@rosberry.com
* Stanislav Klyukhin, stanislav.klyukhin@rosberry.com

## About

<img src="https://github.com/rosberry/Foundation/blob/master/Assets/full_logo.png?raw=true" height="100" />

This project is owned and maintained by [Rosberry](http://rosberry.com). We build mobile apps for users worldwide 🌏.

Check out our [open source projects](https://github.com/rosberry), read [our blog](https://medium.com/@Rosberry) or give us a high-five on 🐦 [@rosberryapps](http://twitter.com/RosberryApps).

## License

The project is available under the MIT license. See the LICENSE file for more info.
