namespace TicTacToe_Avalonia

open Avalonia
open Avalonia.Controls.ApplicationLifetimes
open Avalonia.Markup.Xaml
open TicTacToe_Avalonia.ViewModels
open TicTacToe_Avalonia.Views

type App() =
    inherit Application()

    override this.Initialize() =
        AvaloniaXamlLoader.Load(this)

    override this.OnFrameworkInitializationCompleted() =
        match this.ApplicationLifetime with
        | :? IClassicDesktopStyleApplicationLifetime as desktop ->
            let mainWindow = MainWindow()
            mainWindow.DataContext <- MainViewModel()
            desktop.MainWindow <- mainWindow
        | :? ISingleViewApplicationLifetime as singleViewPlatform ->
            let mainView = MainView()
            mainView.DataContext <- MainViewModel()
            singleViewPlatform.MainView <- mainView
        | _ -> ()

        base.OnFrameworkInitializationCompleted()