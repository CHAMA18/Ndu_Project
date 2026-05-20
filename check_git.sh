#!/bin/bash
cd /home/z/my-project/Ndu_Project
echo "=== Current git config ==="
git config user.name
git config user.email
echo "=== Global git config ==="
git config --global user.name
git config --global user.email
echo "=== Recent commits ==="
git log --oneline -5 --format="%H %an <%ae> %s"
