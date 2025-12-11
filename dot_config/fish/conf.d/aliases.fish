# Fish shell aliases

# Tools
alias lg 'lazygit'
alias be "bundle exec"
alias bi "bundle install"

# Directories
alias cdw "cd ~/a/nevaya"
alias cdnev "cd ~/a/nevaya/nev"

alias awsexec 'AWS_REGION=eu-west-1 AWS_PROFILE=staging aws ecs execute-command \
        --cluster nv-dev-euw1-ecs-admin \
        --container genieacs \
        --interactive \
        --command "/bin/bash" \
        --task '
