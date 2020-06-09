# General Spec

Simply create a YAML file named `general.yml` at the root of your repository or use `general spec` command. It is not required by General, but adds useful context for Stencil templates, configs for Xcode projects and default outputs for templates. 

## Configuration File Format

The configuration file is a YAML file structured like this (example):

```yaml
project: Project.xcodeproj
target: App
company: Rosberry
outputs:
  - templateName: rsb_mvp_vm_module
    path: Classes/Presentation/Modules
  - templateName: rsb_mvp_vm_list_module
    path: Classes/Presentation/Modules
```

Here's a quick description of all the possible _root_ keys. All of them are optional.

| Key       | Description                                                  | Intended usage                                               |
| --------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `project` | If present, General will try to add generated files to Xcode project with this name. | This is useful if you want to add generated files to Xcode project. |
| `target`  | If present, generated files will be added to `project` target with this name. | If missing, General will try to add generated files to first app target in `project` if it presents. |
| `company` | Describe the name of the company. Commonly used fo header templates. | If you use `general spec` command, it will try to use `ORGANIZATIONNAME` from `project` if it presents. |
| `outputs` | Describe default paths for templates.                        | See below for a detail of all the subkeys.                   |

Here's a description of subkeys for `outputs`.

| Subkey         | Type   | Description                                                  |
| -------------- | ------ | ------------------------------------------------------------ |
| `templateName` | String | The name of the template.                                    |
| `path`         | String | The relative path for generated files. Used if `path` option for `gen` command is missing. |
