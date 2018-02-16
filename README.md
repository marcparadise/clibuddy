# Clibuddy

Welcome to CLIBuddy.

CLIBuddy is a simple engine that parses a CLI interface descriptor file and can play back
mocks of that CLI based on the descriptor.

Current state: very rough WIP POC. Everything may change, including the language used for implementation.

## Running it locally

```shell
$ cd ~
# Clone the repository
$ git clone https://github.com/marcparadise/clibuddy.git
# Move into the project directory
$ cd ~/clibuddy
# Install the dependencies
$ bundle install
# Now copy a BuddyScript file, `sample.txt`, into the directory file
$ cp ~/Downloads/sample.txt .
# Run your CLI command with clibuddy - I have a cli command called 'dentist'
$ bundle exec bin/clibuddy run dentist
```

## Running it through Docker

Running CLIBuddy through Docker is great if you are someone that loves CLIBuddy
but don't want the hassle of all baggage that comes with it.

Let's walk through getting the source code, building your CLIBuddy in a Docker
Image and then making that buddy really easy to use with a shortcut (alias).

```shell
# Clone the repository
$ git clone https://github.com/marcparadise/clibuddy.git
# Move into the project directory
$ cd clibuddy
# Build the current version docker image
$ docker build -t clibuddy .
# Setup a shortcut, so that whenever you type 'clibuddy' you run the code
# inside of the Docker image. This will last in only this terminal session
# unit you close it.
alias clibuddy="docker run -it --rm -v $(pwd):/share clibuddy:latest"
# Now move to a directory where you have defined a clibuddy 'sample.txt' file
$ cd ~/Downloads
# Run your CLI command with clibuddy - I have a cli command called 'dentist'
$ clibuddy dentist
```

When it is time to upgrade your CLIBuddy you will need to return to the
directory that contains the repository and update the code. Then rebuild
your docker image. The existing alias will still work for you.

```shell
$ cd ~/clibuddy
$ git pull origin master
$ docker build -t clibuddy .
```

You might be saying: Hey wait! I want to take screenshots or recordings of the
command that I built and I don't want 'clibuddy' to be the first word of every
command. I want it to be the name of the command I defined in my BuddyScript file.

That's a great idea and all it requires is that you change the alias to your command
and add that command to the end of command you are assigning to that alias. So
if I wanted to be able to say `dentist vikki brush`, I would need to create an
alias like this:

```shell
$ alias dentist="docker run -it --rm -v $(pwd):/share clibuddy:latest dentist"
```

You might love your CLIBuddy so much that you want to have access to it all the
time. I respect that! We all want to keep our buddies close. Then I would
encourage you to append the alias to the script that runs whenever you start a
new terminal.

```shell
$ echo 'alias dentist="docker run -it --rm -v $(pwd):/share clibuddy:latest dentist"' >> .bashrc
```

Now every time you open a new terminal you will be able to run the command.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
