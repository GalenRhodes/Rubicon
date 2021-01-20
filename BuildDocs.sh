#!/bin/bash

rm -fr .build
rm -fr docs
swift-doc generate Sources/Rubicon --module-name Rubicon -f html --base-url "/Rubicon/" | exit $?
rsync -avz --delete-after .build/documentation/ grhodes@goober:/var/www/html/Rubicon/
exit $?
