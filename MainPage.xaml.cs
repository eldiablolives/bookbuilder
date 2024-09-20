// MainPage.xaml.cs
using System;
using FolderPickerApp.Services;
using Microsoft.Maui.Controls;

namespace FolderPickerApp
{
    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();
        }

        private async void OnPickFolderButtonClicked(object sender, EventArgs e)
        {
            var folderPicker = DependencyService.Get<IFolderPicker>();
            string folderPath = await folderPicker.PickFolder();

            if (!string.IsNullOrEmpty(folderPath))
            {
                SelectedFolderLabel.Text = $"Selected Folder: {folderPath}";
            }
            else
            {
                SelectedFolderLabel.Text = "No folder selected.";
            }
        }
    }
}