# ssh-agent (systemd user socket): unlock a key once per login with ssh-add.
# Left alone when already set (an agent forwarded over ssh -A).
set -q SSH_AUTH_SOCK; or set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
