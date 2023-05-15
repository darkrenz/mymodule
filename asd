#!/bin/bash

# Function to extract usernames from the JSON file
get_usernames() {
  config=$(grep -oP '(?<=^\s*"config": \[).*(?=\])' /etc/zivpn/config.json)
  usernames=$(grep -oP '\w+' <<< "$config")
  echo "$usernames"
}

# Function to validate the username format
validate_username() {
  username=$1
  if [[ ! "$username" =~ ^[[:alnum:]]{1,10}$ ]]; then
    echo "Invalid username format. Username must contain only alphanumeric characters and be up to 10 characters long."
    return 1
  fi
}

# Function to add a new username
add_username() {
  echo -n "Enter the username to add: "
  read -r new_username

  # Validate the username format
  if ! validate_username "$new_username"; then
    return 1
  fi

  # Extract existing usernames
  usernames=$(get_usernames)

  # Check if the username already exists
  if [[ "$usernames" == *"$new_username"* ]]; then
    echo "Username '$new_username' already exists."
    return 1
  fi

  # Add the new username to the list
  updated_usernames=$(printf '%s\n%s' "$usernames" "$new_username")

  # Update the JSON file with the new list of usernames
  sed -i "s/\(\"config\": \[\)\(.*\)\(\]\)/\1$updated_usernames\3/" /etc/zivpn/config.json

  echo "Username '$new_username' added successfully."
}

# Function to change an existing username
change_username() {
  echo -n "Enter the username to change: "
  read -r old_username

  echo -n "Enter the new username: "
  read -r new_username

  # Validate the new username format
  if ! validate_username "$new_username"; then
    return 1
  fi

  # Extract existing usernames
  usernames=$(get_usernames)

  # Check if the old username exists
  if [[ ! "$usernames" == *"$old_username"* ]]; then
    echo "Username '$old_username' does not exist."
    return 1
  fi

  # Replace the old username with the new one
  updated_usernames=$(sed "s/$old_username/$new_username/" <<< "$usernames")

  # Update the JSON file with the updated list of usernames
  sed -i "s/\(\"config\": \[\)\(.*\)\(\]\)/\1$updated_usernames\3/" /etc/zivpn/config.json

  echo "Username '$old_username' changed to '$new_username' successfully."
}

# Function to remove an existing username
remove_username() {
  echo -n "Enter the username to remove: "
  read -r username

  # Extract existing usernames
  usernames=$(get_usernames)

  # Check if the username exists
  if [[ ! "$usernames" == *"$username"* ]]; then
    echo "Username '$username' does not exist."
    return 1
  fi

  # Remove the specified username from the list
  updated_usernames=$(sed "s/\b$username\b//g" <<< "$usernames")
  updated_usernames=$(sed 's/,\s*,/,/g' <<< "$updated_usernames")
  updated_usernames=$(sed 's/^\s*,//; s/,\s*$//;' <<< "$updated_usernames")

  # Update the JSON file with the updated list of usernames
  sed -i "s/\(\"config\": \[\)\(.*\)\(\]\)/\1$updated_usernames\3/" /etc/zivpn/config.json

  echo "Username '$username' removed successfully."
}

# Main menu
while true; do
  clear
  echo "1. Add Username"
  echo "2. Change Username"
  echo "3. Remove Username"
  echo "4. Display Current Users"
  echo "5. Exit"
  echo -n "Enter your choice: "
  read -r choice

  case $choice in
    1) add_username ;;
    2) change_username ;;
    3) remove_username ;;
    4) echo "Current Users:"
       get_usernames ;;
    5) echo "Exiting..."
       break ;;
    *) echo "Invalid choice. Please try again." ;;
  esac

  echo
  echo "Press Enter to continue..."
  read -r
done
