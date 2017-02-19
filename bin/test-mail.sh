#!/usr/bin/env bash
echo "Sending test email"
echo "Your e-mail settings seems to work fine!" > testmail.mail
ssmtp ${EMAIL_TO} < testmail.mail

if [[ $? != 0 ]]; then
    echo "Could not send email, ssmtp returned a non-zero code!"
    exit 1
else
    echo "Success"
    exit 0
fi

