namespace TicTacToe_Avalonia.Android

open Android.App
open Android.Content.PM
open Avalonia
open Avalonia.Android
open TicTacToe_Avalonia

[<Activity(
    Label = "TicTacToe_Avalonia.Android",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@drawable/icon",
    MainLauncher = true,
    ConfigurationChanges = (ConfigChanges.Orientation ||| ConfigChanges.ScreenSize ||| ConfigChanges.UiMode))>]
type MainActivity() =
    inherit AvaloniaMainActivity()
