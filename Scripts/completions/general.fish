function __fish_general_using_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq (count $argv) ]
        for i in (seq (count $argv))
            if [ $cmd[$i] != $argv[$i] ]
                return 1
            end
        end
        return 0
    end
    return 1
end
complete -c general -n '__fish_general_using_command general' -f -l version -d 'Show the version.'
complete -c general -n '__fish_general_using_command general' -f -s h -l help -d 'Show help information.'
complete -c general -n '__fish_general_using_command general' -f -a 'gen' -d 'Generates modules from templates.'
complete -c general -n '__fish_general_using_command general' -f -a 'create' -d 'Creates a new template.'
complete -c general -n '__fish_general_using_command general' -f -a 'list' -d 'List of available templates.'
complete -c general -n '__fish_general_using_command general' -f -a 'setup' -d 'Provides your environment with templates'
complete -c general -n '__fish_general_using_command general' -f -a 'config' -d 'Provides an access to general config'
complete -c general -n '__fish_general_using_command general' -f -a 'upgrade' -d 'Upgrades general to specified version'
complete -c general -n '__fish_general_using_command general' -f -a 'help' -d 'Show subcommand help information.'

complete -c general -n '__fish_general_using_command general gen' -f -r -l path -s p -d 'The path for the project.'
complete -c general -n '__fish_general_using_command general gen --path' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general gen -p' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general gen' -f -r -l name -s n -d 'The name of the module.'
complete -c general -n '__fish_general_using_command general gen' -f -r -l template -s t -d 'The name of the template.'
complete -c general -n '__fish_general_using_command general gen --template' -f -a '(command general ---completion gen -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general gen -t' -f -a '(command general ---completion gen -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general gen' -f -r -l output -s o -d 'The output for the template.'
complete -c general -n '__fish_general_using_command general gen --output' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general gen -o' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general gen' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general create' -f -r -l template -s t -d 'The name of the template.'
complete -c general -n '__fish_general_using_command general create' -f -r -l path -s p -d 'The path for the template.'
complete -c general -n '__fish_general_using_command general create --path' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general create -p' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general create' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general list' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general setup' -f -r -l repo -s r -d 'Fetch templates from specified github repo. Format: "<github>\ [branch]".'
complete -c general -n '__fish_general_using_command general setup --repo' -f -a '(command general ---completion setup -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general setup -r' -f -a '(command general ---completion setup -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general setup' -f -r -l global -s g -d 'If specified loads templates into user home directory'
complete -c general -n '__fish_general_using_command general setup' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general config' -f -s h -l help -d 'Show help information.'
complete -c general -n '__fish_general_using_command general config' -f -a 'print' -d 'Displays general config'
complete -c general -n '__fish_general_using_command general config' -f -a 'reset' -d 'Resets general config'
complete -c general -n '__fish_general_using_command general config' -f -a 'repo' -d 'Allows to add templates repo for easy setup'
complete -c general -n '__fish_general_using_command general config' -f -a 'use' -d 'Set default executable instance for specific command'
complete -c general -n '__fish_general_using_command general config' -f -a 'help' -d 'Show subcommand help information.'

complete -c general -n '__fish_general_using_command general config print' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general config reset' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general config repo' -f -r -l as -d 'Specifies short repo alias'
complete -c general -n '__fish_general_using_command general config repo' -f -s h -l help -d 'Show help information.'

complete -c general -n '__fish_general_using_command general config use' -f -r -l executable -s e -d 'The executable instance for the command'
complete -c general -n '__fish_general_using_command general config use --executable' -f -a '(command general ---completion config use -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general config use -e' -f -a '(command general ---completion config use -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general config use' -f -r -l for -d 'The name on the command'
complete -c general -n '__fish_general_using_command general config use' -f -s h -l help -d 'Show help information.'

