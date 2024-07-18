# Pixel Edit

<img src="https://github.com/cowboy8625/pixel-edit/assets/43012445/46d1269f-25b9-4e95-be15-dd472f30a95f"/>

### Building

- dependencies: [raylib](https://github.com/raysan5/raylib)
- built with version `0.13.0`

```shell
git clone https://github.com/cowboy8625/pixel-edit
cd pixel-edit
git checkout remastered
git submodule update --init --recursive
zig build run
```

### TODO
- [ ] Fix Colon not being in the KeyboardKey enum
- [ ] Try to use RayGui for the command bar
- [ ] add cursor to command bar
- [ ] add move cursor in command bar <kbd>left</kbd> and <kbd>right</kbd>
- [ ] add <kbd>up</kbd> and <kbd>down</kbd> in command bar to move through command history
- [ ] <kbd>f</kbd> to use the fill command
- [ ] use of mouse for drawing
- [ ] command: num:num to jump cursor to location
