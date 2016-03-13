# Origami 0.6


## Requirements

- BaseX 8.3 or higher

The provided Gradle build script will download BaseX 8.4.1.

## Getting started

- Some tutorials can be found on my [blog][blog].
- The [demo code](https://github.com/xokomola/origami-app)
- For documentation see the [wiki][wiki].

Import the module

```
import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami/origami.xqm'; 
```

Alternatively you can install Origami in the BaseX repo using

    gradlew install

which let's you import the module without using it's location.

```
import module namespace o = 'http://xokomola.com/xquery/origami' 
```

### GUI

If you want to launch the BaseX GUI

    gradlew gui

## Running the tests

The [test][tests] subdirectory contains the unit tests. To run them use:

    gradlew test

[examples]: https://github.com/xokomola/origami/tree/master/examples
[tests]: https://github.com/xokomola/origami/tree/master/test
[blog]: http://xokomola.com/
[wiki]: https://github.com/xokomola/origami/wiki

