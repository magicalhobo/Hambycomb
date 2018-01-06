# Hambycomb

[Hambycomb](http://www.hambycomb.com/) is an ActionScript 3 project that allows runtime modifictaion of the game Draw My Thing on [OMGPOP](http://www.omgpop.com/).

It is the inspiration for both [SWFWire](http://www.swfwire.com/) and [SketchPort](http://www.sketchport.com/).

The idea is simple.  We load the OMGPOP SWF and a custom SWF into the same `ApplicationDomain`, and the custom SWF can modify the OMGPOP SWF at runtime.

This gives us two parts:

## The container
*A.K.A. Hambycomb.as / Hambycomb.swf*

The container loads OMGPOP and the injection. Depending on the `TESTING` flag, it will either:

- Embed the injection for quick loading.
- Load it dynamically for easy testing.  A *green dot* appears in the top left, which you can click to reload the hack.

## The injection
*A.K.A. HambycombInjection.as / HambycombInjection.swf*

The injection contains the code that interacts with the OMGPOP SWF.  You can modify it during game play to quickly figure out your hack.  In this case, it adds keyboard shortcuts that can modify the brush while drawing.

Unfortunately, like most SWFs, the main class of the OMGPOP SWF depends on the `stage` being immediately accessible.  That means when you try to load it using a `Loader`, you get a null object reference error.  This is where being able to read the SWF file format becomes necessary.  We want to find the `ShowFrame` tag that would usually cause Flash Player to start executing code, and remove it.  This way we can access all of the classes in the SWF, and initialize it in our own way.

So how can we remove the correct `ShowFrame` tag?  The SWF file format is pretty organized, and we can read tags without knowing anything about them.

The things we need to handle are:

- Removing file compression
- Getting past variable length fields in the SWF header
- Removing the unwanted tags
- Updating the file size field in the SWF header
- Updating the frame count field in the SWF header

All of this is taken care of in the `read` method.  Now that we can load the SWF without error, we can directly instantiate the necessary objects (`iilwy.versions.website.Website` in this case) and add them to the stage.

All that's left now is a little code to disable and cleanup the current injection (`deactivate`) when you want to load a new one, and everything should be working.
