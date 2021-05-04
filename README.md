Compose a UI using page morphs

**How?**
- UI components ("templates") are inserted/removed using two reflex actions, and are identified by `uuid`s
- The `session` is used to persist/manage them

**Caveat**

Note that in a real-world app, you'd probably want to use model partials and empty model instances to construct your UI (the `Template`) class acts as a stand-in for both model and partial)

**Variations**

Use [kredis](https://github.com/rails/kredis) as ephemeral persistence store