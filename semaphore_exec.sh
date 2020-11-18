#!/usr/bin/env bash

source ./semaphore.sh

evaluateBranch $projectid $attempts "localhost.gitlab.int"
