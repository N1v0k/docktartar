#!/usr/bin/env bash
echo "Sending test email"
echo "From: ${EMAIL_FROM} <${EMAIL_FROM_ADRESS}>" > testmail.mail
echo "Subject: ${EMAIL_SUBJECT}" >> testmail.mail
echo "Your e-mail settings seem to work fine!" >> testmail.mail
ssmtp ${EMAIL_TO} < testmail.mail

if [[ $? != 0 ]]; then
    echo "Could not send email, ssmtp returned a non-zero code!"
    exit 1
else
    echo "Success"
    exit 0
fi

