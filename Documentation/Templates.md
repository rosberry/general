# Templates

To create a new template, use `general template` command. It creates a folder with passed name, a `Code` folder with `template.stencil` file and `spec.yml`. The example:

```bash
general gen -t module
```

Generated template:

```bash
module
├── Code
│   └── template.stencil
└── spec.yml
```

By default generated templates are saved in `.templates` folder in your root directory. General use [Stencil](https://stencil.fuller.li/en/latest) language for template files. 

If you want to reuse `.stencil` files between different templates, just create `common` folder in `.templates` folder and put commonly used templates. Here is an example of `header.stencil`:

```stencil
//
//  Copyright © {{ year }} {{ company }}. All rights reserved.
//
```

Here's a list of supported variables:

|           | Description             | Intended usage                                               |
| --------- | ----------------------- | ------------------------------------------------------------ |
| `name`    | The name of the module  | This is useful if you want to add generated files to Xcode project. |
| `year`    |                         | Useful for file headers. By default General uses current year. |
| `company` | The name of the company | Useful for file headers.                                     |

If you want to use custom variables or override the variables above, pass it to `gen` command in `key:value` format. For instance:

```bash
general gen -t module year:2007
```

## Template Spec File Format

The configuration file is a YAML file structured like this (example):

```yaml
files:
  - template: Code/ViewController.swift.stencil
  - template: Code/ViewModel.swift.stencil
testFiles:
  - template: Test/ViewModelTests.swift.stencil
```

Here's a quick description of all the possible _root_ keys.

| Key         | Description                             | Intended usage                           |
| ----------- | --------------------------------------- | ---------------------------------------- |
| `files`     | The list of templates for module.       | Paths must be repative to module folder. |
| `testFiles` | The list of templates for module tests. | Paths must be repative to module folder. |