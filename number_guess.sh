#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo Enter your username:
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

if [[ -z $USER_ID ]]
  then
  # username has not been used before
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
else
  # username has been used before
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(ARRAY_LENGTH(history_guessed_number, 1)) FROM games WHERE user_id = $USER_ID")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(($RANDOM % 1000 + 1))

echo "Guess the secret number between 1 and 1000:"

GAME() {
  if [[ $1 ]]
    then
      echo -e "\n$1"
  fi

  read GUESSED_NUMBER

  if [[ ! $GUESSED_NUMBER =~ ^[0-9]+$ ]]
    then
      GAME "That is not an integer, guess again:"
  else
    # guess the secret number
    HISTORY_GUESSED_NUMBER+=($GUESSED_NUMBER)

    if [[ $GUESSED_NUMBER -lt $SECRET_NUMBER ]]
      then
        GAME "It's higher than that, guess again:"
    elif [[ $GUESSED_NUMBER -gt $SECRET_NUMBER ]]
      then
        GAME "It's lower than that, guess again:"
    else
      HISTORY_STR=$(IFS=, ; echo "${HISTORY_GUESSED_NUMBER[*]}")
      INSERT_GAME=$($PSQL "INSERT INTO games(secret_number, history_guessed_number, user_id) VALUES($SECRET_NUMBER, '{$HISTORY_STR}'::int[], $USER_ID)")
      echo "You guessed it in ${#HISTORY_GUESSED_NUMBER[@]} tries. The secret number was $SECRET_NUMBER. Nice job!"
      fi
  fi
}

GAME
