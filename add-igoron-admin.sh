#!/usr/bin/env bash
set -Eeuo pipefail

USER_NAME="igoron"
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXnb1Z51+JlBOLJKsIGFrGJm/XUrL0ZfvLY4JJRH7TxIvu1gICjCbEf1gBY9GMFkb25igqxYi/+Bx1XD6RlNQXz3snoh408/pjal+KzrJ2+al9sW1zGxwQ4Tf2Ba1BmZ/TYq7j6j7S265tS/lJr2Ge6aK947osokkuMiB1qXcQpOVMJBXibc3rSFMAGLHfeRTQvU4vZW4DcEzdw0P/4TKIxbYY9A2G/CbyzAMtQjMT/dAbKq2uWyiO2nUhjf7xpShtykiQpp/BDajZvQ3USS90nD9bjiv1kvyk8l9gZoa6yVJ3AbOjCmC0iOuvbGUPas9j3s5bn8l/3B8EXxyZYQb7 igoron@MacBook-Pro-Igor.local'

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: run this script as root."
    exit 1
fi

echo "=== Configuring ${USER_NAME} ==="

# Create user if it doesn't exist
if ! id "$USER_NAME" >/dev/null 2>&1; then
    echo "Creating user: $USER_NAME"
    useradd \
        --create-home \
        --shell /bin/bash \
        "$USER_NAME"
else
    echo "User $USER_NAME already exists."
fi

HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"

if [[ -z "$HOME_DIR" ]]; then
    echo "ERROR: cannot determine home directory for $USER_NAME"
    exit 1
fi

echo "Home directory: $HOME_DIR"

# SSH directory
install -d \
    -m 700 \
    -o "$USER_NAME" \
    -g "$USER_NAME" \
    "$HOME_DIR/.ssh"

AUTHORIZED_KEYS="$HOME_DIR/.ssh/authorized_keys"

touch "$AUTHORIZED_KEYS"
chown "$USER_NAME:$USER_NAME" "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

# Add public key only if it isn't already present
if grep -qxF "$PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
    echo "SSH key already installed."
else
    echo "$PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
    echo "SSH key installed."
fi

chown "$USER_NAME:$USER_NAME" "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

# Add user to sudo group
usermod -aG sudo "$USER_NAME"

# Passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/igoron"

echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
chown root:root "$SUDOERS_FILE"

# Validate sudoers before finishing
if ! visudo -cf "$SUDOERS_FILE"; then
    echo "ERROR: sudoers validation failed."
    rm -f "$SUDOERS_FILE"
    exit 1
fi

echo
echo "=== Verification ==="
id "$USER_NAME"

echo
echo "--- authorized_keys ---"
grep -F "$PUBLIC_KEY" "$AUTHORIZED_KEYS" >/dev/null \
    && echo "OK: SSH key installed"

echo
echo "--- sudo ---"
cat "$SUDOERS_FILE"

echo
echo "=========================================="
echo " User $USER_NAME configured successfully."
echo " SSH public-key authentication: READY"
echo " Passwordless sudo: READY"
echo "=========================================="
