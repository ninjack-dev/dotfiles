## TODO
- [ ] Consolidate `panel_input.py` with the [up-to-date panel kitten](https://github.com/kovidgoyal/kitty/blob/master/kittens/panel/main.py)
    - The downstream kitten added a `focus-policy` parameter much like the `input-mode` parameter I added. I tried updating it, but some enum types were missing for whatever reason. I'll need to copy the upstream one over when it's working and re-add my `listen-on` parameter.
