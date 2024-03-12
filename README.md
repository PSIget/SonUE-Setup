# Installation Wizard for the [STALKER on UE](https://git.s2ue.org/RedProjects/SonUE) project

An Inno Setup-based Installation Wizard that is easy to use while meeting all project requirements.

## Installer Features

The Installation Wizard supports three languages: Russian, English, and Ukrainian.

Before starting the installation, the program automatically detects all installed versions of the "S.T.A.L.K.E.R.: Shadow of Chernobyl" game. If the game is already installed, the installer will proceed with the process. If the game is not present, installation will not be possible - this is necessary to comply with copyright laws.

## How to Build the Installer

### Editing the build version

The build version can be edited in the `./src/Setup.iss` file.

### Building the installation file (Setup)

1. Download and install the latest version of [Inno Setup](https://jrsoftware.org/isdl.php).
2. Open the `./src/Setup.iss` file in Inno Setup.
3. Press `Ctrl+F9` or select `Build > Compile`.

### Creating an archive (packing game files)

1. Move the game files to the `./pack/Input` folder.
2. Run `./pack/Pack.cmd` and wait. Packing may take some time.
3. After packing is complete, move the `./pack/Output/Data.bin` file to `./src/Output`.

Now the installer is ready for testing and distribution!

## Important

Please ensure that you are using the latest versions of all tools and follow the build instructions. If you encounter any problems or have questions, feel free to ask for help.
