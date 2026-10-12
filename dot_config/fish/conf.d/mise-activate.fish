# Deliberately empty. fish runs only the first conf.d file of a given name,
# and this one shadows Homebrew's vendor_conf.d/mise-activate.fish, which runs
# a full `mise activate` in every shell, scripted ones included (~150ms). That
# made the interactive/shims split in config.fish dead code and meant
# interactive shells activated mise twice. config.fish now owns activation.
