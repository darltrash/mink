# Mink, ANOTHER game experiment.
This is another little game experiment I have coded in Lua targetting Löve; It currently only works in desktop and ***has only been tested toroughly in Linux*** with both **Wayland** and **X11**

## > Controls:
<kbd>↓</kbd> <kbd>←</kbd> <kbd>→</kbd>: Movement <br>
<kbd>Spacebar</kbd>: Jump <br>
<kbd>Z Key</kbd>: Run <br>
<kbd>C Key</kbd>: **SCREAM!!!!!** <br>
<kbd>X Key</kbd>: Wall-grab <br>
<kbd>A Key</kbd>: Pet <br>
<kbd>D Key</kbd>: Use <br>

## > Roadmap:
- [X] Entity handler
- [X] Tile handler
- [X] Asset handler
- [X] Language handler
- [X] Event script handler
- [X] Basic physics system (lol)
- [X] Logging system
- [ ] Dynamic music system
- [ ] Actually making something with it!

## > Debugging:
Set the following environment variables for debug features:

| Variable                | Description                                       |
|-------------------------|---------------------------------------------------|
| `MINK_DEBUG=1`          | Enable debugging features                         |
| `MINK_NODEBUGOVERLAY=1` | Disable debug overlay features when in debug mode |
| `MINK_EDIT=1`           | Enable editing features *(WIP)*                   |
| `MINK_NOVOLUME=1`       | Disable all sound and music                       |

## > File structure:
- `main.lua`: Main loop and setting up stuff

- `conf.lua`: Config file for Löve stuff 

- `ass/`: 
  - `manifest.toml`: Contains all the asset definitions and properties

- `ent/`
  - `init.lua`: Contains the loader and importer of all the entity files, manual so far, considering to move to `.toml`
  - `<entity>.lua`: Contains entity definition code, a single table with a process method which gets processed every frame alongside entity properties

- `lan/`
  - `<language>.lua`: translations for &lt;language&gt;
  - `init.lua`: Contains the loader for all language files, automatic
  - `en.lua`: English translations, used as an example language

- `lib/`
  - `<library>.lua`: Random libraries I used for the project lol
  
- `scr/`
  - `<event>.lua`: An event scripting file, returns a table with the method `onPlayerInteraction`
  
- `src/`
  - `scn_<scene>.lua`: An scene file, must contain the methods `init`, `loop` and `draw`, other methods are also available and added as needed
  - `scn_main.lua`: The main scene file, used as an example scene.
  - `utils.lua`: Random utility functions!
  - `world.lua`: Main world code, *VERY* complicated right now lmao.

## > Contribute:
Feel free to contribute on everything you want! Though I might take some time to reply to PRs :(

## > License:
Check out the [LICENSE file](LICENSE) at this repo which covers all the `.lua`, `.glsl` and `.toml` files which do not contain their own licenses. <br>
Check out the [CC-BY-SA 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/) which covers all non-code assets (`.png`, `.mp3`, `.wav`) not explicitly set with a different license