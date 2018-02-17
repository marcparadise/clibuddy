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
git clone https://github.com/marcparadise/clibuddy.git
# Move into the project directory
cd clibuddy
# Build the current version docker image
docker build -t clibuddy .
# Setup a shortcut, so that whenever you type 'clibuddy' you run the code
# inside of the Docker image. This will work for this one terminal.
function clibuddy {
  docker run -it --rm -v $(pwd):/share clibuddy:latest $@
}
# Now move to a directory where you have defined a clibuddy 'sample.txt' file
cd ~/Downloads
# Run your CLI command with clibuddy - I have a cli command called 'dentist'
clibuddy dentist
```

When it is time to upgrade your CLIBuddy you will need to return to the
directory that contains the repository and update the code. Then rebuild
your docker image.

```shell
cd ~/clibuddy
git pull origin master
docker build -t clibuddy .
# If the 'clibuddy' function is not defined you will redefine it.
function clibuddy {
  docker run -it --rm -v $(pwd):/share clibuddy:latest $@
}
```

You might be saying: Hey wait! I want to take screenshots or recordings of the
command that I built and I don't want `clibuddy` to be the first word of every
command. I want it to be the name of the command I defined in my BuddyScript file.

That's a great idea and all it requires is that you define a function that
is the same name as the command you want to run and then insert that same
command between `clibuddy:latest` and `$@`. So if I defined a command in my
BuddyScript named `dentist` and I wanted my commands in my shell to appear as
 `dentist vikki brush`, then I would need to create a function that looked like:

```shell
function dentist {
  docker run -it --rm -v $(pwd):/share clibuddy:latest dentist $@
}
```

You might love your CLIBuddy so much that you want to have access to it all the
time. I respect that! We all want to keep our buddies close. Then I would
encourage you to append the function to the script that runs whenever you
start a new terminal session. This is likely your `.bash_profile`. This command
will append this function to the end of that file:

```shell
$ echo 'function dentist {
  docker run -it --rm -v $(pwd):/share clibuddy:latest dentist $@
}' >> ~/.bash_profile
```

Now every time you open a new terminal you will be able to use your command.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
