namespace TicTacToe_Avalonia.Android

open Android.App
open Android.Content.PM
open Avalonia
open Avalonia.Android
open TicTacToe_Avalonia

    [<Application>]
type Application(javaReference: nativeint, transfer: Android.Runtime.JniHandleOwnership) = 
    inherit AvaloniaAndroidApplication<App>(javaReference, transfer)

     override _.CustomizeAppBuilder(builder) =
        base.CustomizeAppBuilder(builder)
            .WithInterFont()
