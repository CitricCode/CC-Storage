# CC:Storage

CC:Storage is a program for the CC:Restitched mod that creates and manages a storage system written in lua.

This project is currently very unfinished.

## Installation

Download the repository and extract `src` into the computer's directory

Ensure there is a `databases` folder within the `storage` folders

Add empty files with the names "chests.db", "items.db", and "mods.db"

## Usage

```bash
storage -h
# Gets help for the different functions the program does

storage -r [item name] [amount]
# Requests amount number of items from storage. Note its format is "mod:name" e.g. "minecraft:stone"

storage -s
# Stores whatever is in the input chest into storage

storage -u
# Updates database if player manually collected items from storage

storage -d
# Initiates a questionnaire that outputs what items are in storage given the filters supplied
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

## License

[GNU General Public License, version 3 (GPL-3.0) ](https://choosealicense.com/licenses/gpl-3.0/)
