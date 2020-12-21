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
complete -c general -n '__fish_general_using_command general' -f -a 'gen' -d 'Generates modules from templates.'
complete -c general -n '__fish_general_using_command general' -f -a 'create' -d 'Creates a new template.'
complete -c general -n '__fish_general_using_command general' -f -a 'spec' -d 'Creates a new spec.'
complete -c general -n '__fish_general_using_command general' -f -a 'list' -d 'List of available templates.'
complete -c general -n '__fish_general_using_command general' -f -a 'setup' -d 'Provides your environment with templates'
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
complete -c general -n '__fish_general_using_command general gen' -f -r -l target -d 'The target to which add files.'
complete -c general -n '__fish_general_using_command general gen --target' -f -a '(command general ---completion gen -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general gen' -f -r -l test-target -d 'The test target to which add test files.'
complete -c general -n '__fish_general_using_command general gen --test-target' -f -a '(command general ---completion gen -- --custom (commandline -opc)[1..-1])'
complete -c general -n '__fish_general_using_command general create' -f -r -l template -s t -d 'The name of the template.'
complete -c general -n '__fish_general_using_command general create' -f -r -l path -s p -d 'The path for the template.'
complete -c general -n '__fish_general_using_command general create --path' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general create -p' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general spec' -f -r -l path -s p -d 'The path for the template.'
complete -c general -n '__fish_general_using_command general spec --path' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general spec -p' -f -a '(__fish_complete_directories)'
complete -c general -n '__fish_general_using_command general setup' -f -r -l repo -s r -d 'Fetch templates from specified github repo. Format: "<github>\ [branch]".'
complete -c general -n '__fish_general_using_command general setup' -f -r -l global -s g -d 'If specified loads templates into user home directory'
