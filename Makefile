# This Makefile is designed to be run with PowerShell on Windows.
# It explicitly sets PowerShell as the shell.
SHELL := pwsh.exe
.SHELLFLAGS := -Command

all: cover gen

cover:
	# Generate simple book cover
	.\create_cover.ps1

gen:
	# Generate EPUB and PDF
	.\gen.ps1

commit-ai:
	# Stage all changes (optional, remove if you want to stage manually)
	git add .
	# Generate commit message with gemini and commit
	git diff HEAD | gemini --model gemini-2.5-flash -p "Based on the following git diff, write a concise and descriptive commit message following the conventional commit format, result in plain text" > commit-message.log
	# Remove fist line (optional)
	(Get-Content commit-message.log | Select-Object -Skip 1) | Set-Content commit-message.log
	# Commit log from file
	git commit -F commit-message.log
	# Git push
	git push