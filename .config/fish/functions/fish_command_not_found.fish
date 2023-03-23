function fish_command_not_found \
	--description 'Called by Fish when a command is not found'
	echo "fish: $argv[1]: command not found..."
	if type -q podman
		podman run --rm -it --pull never "localhost/$argv[1]" $argv[1..-1]
	end
end
