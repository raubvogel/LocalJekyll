#!/bin/sh
set -e

groupadd -g $EXTGID extgroup
adduser $DEVUSER extgroup

su - $DEVUSER

# And we are done here
exec "$@"
