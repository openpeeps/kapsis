
type
    Preloader* = object


proc init*[P: typedesc[Preloader]](preloader: P): Preloader =
    ## Initialize a new Preloader
