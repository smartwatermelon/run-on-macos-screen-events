# run-on-macos-screen-events

A tiny Swift program to run a command whenever the screen locks or unlocks \
(I use it for locking other local machines' screens when locking the primary, and remounting network shares when waking from sleep)

```sh
# run-on-macos-screen-events <command-to-run-on-unlock> [command-args]
run-on-macos-screen-events ./examples/mount-network-shares.sh
```

```sh
# add to launchctl (start on login)
serviceman add --user \
    --path "$PATH" \
    ./run-on-macos-screen-events ./examples/mount-network-shares.sh
```

# Table of Contents

-	[Acknowledgement](#ack)
-   [Install](#install)
-   [Run on Login](#run-on-login)
    -   [With serviceman](#with-serviceman)
    -   [With a plist template](#with-a-plist-template)
-   [Build from Source](#build-from-source)
-   [Publish Release](#publish-release)
-   [Similar Products](#similar-products)

# Acknowledgement
Forked from [coolaj86/run-on-macos-screen-unlock](https://github.com/coolaj86/run-on-macos-screen-unlock).

# Install

1. Download
    ```sh
    curl --fail-with-body -L -O https://github.com/smartwatermelon/run-on-macos-screen-events/releases/download/v1.1.0/run-on-macos-screen-events-v1.1.0.tar.gz
    ```
2. Extract
    ```sh
    tar xvf ./run-on-macos-screen-events-v1.1.0.tar.gz
    ```
3. Allow running even though it's unsigned
    ```sh
    xattr -r -d com.apple.quarantine ./run-on-macos-screen-events
    ```
4. Move into your `PATH`
    ```sh
    mv ./run-on-macos-screen-events ~/bin/
    ```

# Run on Login

You'll see notifications similar to these when adding launchctl services yourself:

<img width="376" alt="Background Items Added" src="https://github.com/user-attachments/assets/362d180b-51e6-4e5a-a9be-8cdc356e5b34">

<img width="827" alt="Login Items from unidentified developer" src="https://github.com/user-attachments/assets/fb8fce4c-035a-40ae-8f37-70c28e67ad87">

## With `serviceman`

1. Install `serviceman`
    ```sh
    curl --fail-with-body -sS https://webi.sh/serviceman | sh
    source ~/.config/envman/PATH.env
    ```
2. Register with Launchd \
   (change `COMMAND_GOES_HERE` to your command)

    ```sh
    serviceman add --user \
        --path "$PATH" \
        ~/bin/run-on-macos-screen-events COMMAND_GOES_HERE
    ```

## With a plist template

1. Download the template plist file
    ```sh
    curl --fail-with-body -L -O https://raw.githubusercontent.com/smartwatermelon/run-on-macos-screen-events/main/examples/run-on-macos-screen-events.COMMAND_LABEL_GOES_HERE.plist
    ```
2. Change the template variables to what you need:

    - `USERNAME_GOES_HERE` (the result of `$(id -u -n)` or `echo $USER`)
    - `COMMAND_LABEL_GOES_HERE` (lowercase, dashes, no spaces)
    - `COMMAND_GOES_HERE` (the example uses `./examples/mount-network-shares.sh`)

3. Rename and move the file to `~/Library/LaunchDaemons/`
    ```sh
    mv ./run-on-macos-screen-events.COMMAND_LABEL_GOES_HERE.plist ./run-on-macos-screen-events.example-label.plist
    mv ./run-on-macos-screen-events.*.plist ~/Library/LaunchDaemons/
    ```
4. Register using `launchctl`
    ```sh
    launchctl load -w ~/Library/LaunchAgents/run-on-macos-screen-events.*.plist
    ```

## View logs

```sh
tail -f ~/.local/share/run-on-macos-screen-events.*/var/log/run-on-macos-screen-events.*.log
```

# Build from Source

1. Install XCode Tools \
   (including `git` and `swift`)
    ```sh
    xcode-select --install
    ```
2. Clone and enter the repo
    ```sh
    git clone https://github.com/smartwatermelon/run-on-macos-screen-events.git
    pushd ./run-on-macos-screen-events/
    ```
3. Build with `swiftc`
    ```sh
    swiftc ./run-on-macos-screen-events.swift
    ```

# Publish Release

1. Git tag and push
    ```sh
    git tag v1.1.x
    git push --tags
    ```
2. Create a release \
   <https://github.com/smartwatermelon/run-on-macos-screen-events/releases/new>
3. Tar and upload
    ```sh
    tar cvf ./run-on-macos-screen-events-v1.1.x.tar ./run-on-macos-screen-events
    gzip ./run-on-macos-screen-events-v1.1.x.tar
    open .
    ```

# Similar Products

-   [How to run a command on lock/unlock](https://apple.stackexchange.com/questions/159216/run-a-program-script-when-the-screen-is-locked-or-unlocked) (the snippets from which this repo grew)
-   [EventScripts](https://apps.apple.com/us/app/eventscripts/id525319418?l=en&mt=12)
-   [HammarSpoon: caffeinate.watcher](https://www.hammerspoon.org/docs/hs.caffeinate.watcher.html)
