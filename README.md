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
 
    To learn more about the configuration file [see the dedicated documentation](/Documentation/GeneralSpec.md).   
    
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

## Config

General stores config to simplify its usage. 

1. Set alias for templates repo

    ```bash
    general config repo <templates repo> --as <alias>
    ```

    After that alias can be used instead repo in `general setup`.

2. Set default plugin to command.
    If there are more then one plugin that can handle command line input `general` will ask you to choose one. But it is possible setup plgun name that
    was be used by default for this command. For example, general has preinstalled `GeneralIOs` plugin that has `gen` and `setup` commands. To always
    use ios plugin for command `gen` needs to perform
    
    ```bash
    general config use --executable GeneralIOs --for gen
    ```
    
3. If plugin could not read command line input you can try override its standart input using

    ```bash
    general config override-plugin-input true
    ```
    
## Bootsrap

To use bootstrap you need a repo with templates. Refer to [this](https://github.com/rosberry/swift-project-template) for example.

There are two ways to bootstrap project from templates files using `general`.

### 1. Cookiecutter
First, you need templates files located on the disk. Then just run 
```bash
general bootstrap --name <project name> --template <path to templates>
```

### 2. Stensil+PlantUML
You're still need template files located on the disk. You can find an example on the `umaler` branch of the [reference](https://github.com/rosberry/swift-project-template).
Also, you need [plant uml](https://plantuml.com/sequence-diagram) diagram that describes your project architecture components. 
We recomend use [this framework](https://github.com/rosberry/plantrsb) to compose it.
Now just run
```bash
general bootstrap --name <project name> --template <path to templates> --uml <path to main uml file>
```

With this approach, not only general template files are set up, but also specific files that form the architecture of a particular project.

### Bootstrap config
Both approaches allows specify following template variables:
-  -c, --company Copyright company
-  -f, --firebase Enable or disable firebase
-  -s, --swiftgen Enable or disable swiftgen
-  -l, --licenseplist Enable or disable licenseplist

It can be a bit annoying to point them out all the time. You can specify default value for all projects by running
```bash
general bootstrap config update <-c/-f/-s/-l> <true/false>
```

Also it is possible to use the same templates location by default:
```bash
general bootstrap config update --template <path to templates>
```

And one more bootstrap feature - you can run additional shell commands after bootstrap. To specyfy them run
```bash
general bootstrap config update shell --add <executable>
```

It will ask you arguments and dependence files at runtime.

## Shared setup

Using general with fully configured defaults is pretty easy but its the configuration still remains annoying.
For example, you need set up the config:

- `general config repo "rosberry/general-templates ios" --as "ios"`
- `general config override-plugin-input true`
- `general config use --executable GeneralIOs --for setup`
- `general config use --executable GeneralIOs --for gen`

Then set up bootstrap
- `git (clone "https://github.com/rosberry/swift-project-template" && cd "swift-project-template" && git checkout umaler)`
- `general bootstrap config update -t "swift-project-template/{{ project.name }}"`
- `general bootstrap config update --company "Rosberry"`
- `general bootstrap config update --firebase true`
- `general bootstrap config update --swiftgen true`
- `general bootstrap config update --licenseplist true`
- `general bootstrap config update shell --add swiftgen`
- `general bootstrap config update shell --add general`
- `general bootstrap config update shell --add fastfood`
- `general bootstrap config update shell --add fastlane`
- `general bootstrap config update shell --add depo`

It is more better place this setup instructions to some `Makefile` and share it between devices. If you place such `Makefile` on the [github repo](https://github.com/rosberry/RSBGeneral) then you can use it on another device just by running

```bash
general shared setup --repo <github repo> 
```

## Installing
- [Homebrew](https://brew.sh): `brew install rosberry/tap/general`
- [Mint](https://github.com/yonaskolb/Mint): `mint install rosberry/general`
- From source: `make install`


## Authors

* Artem Novichkov, artem.novichkov@rosberry.com
* Nikolay Tyunin, nikolay.tyunin@rosberry.com
* Vlad Zhavoronkov, vlad.zhavoronkov@rosberry.com
* Stanislav Klyukhin, stanislav.klyukhin@rosberry.com
* Evgeny Schwarzkopf, evgeny.schwarzkopf@rosberry.com

## About

<img src="https://github.com/rosberry/Foundation/blob/master/Assets/full_logo.png?raw=true" height="100" />

This project is owned and maintained by [Rosberry](http://rosberry.com). We build mobile apps for users worldwide 🌏.

Check out our [open source projects](https://github.com/rosberry), read [our blog](https://medium.com/@Rosberry) or give us a high-five on 🐦 [@rosberryapps](http://twitter.com/RosberryApps).

## License

The project is available under the MIT license. See the LICENSE file for more info.
