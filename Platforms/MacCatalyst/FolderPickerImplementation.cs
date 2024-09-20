// Platforms/MacCatalyst/FolderPickerImplementation.cs
using AppKit;
using Foundation;
using System.Threading.Tasks;
using FolderPickerApp.Services;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.PlatformConfiguration;

[assembly: Dependency(typeof(FolderPickerApp.Platforms.MacCatalyst.FolderPickerImplementation))]
namespace FolderPickerApp.Platforms.MacCatalyst
{
    public class FolderPickerImplementation : IFolderPicker
    {
        public async Task<string> PickFolder()
        {
            var tcs = new TaskCompletionSource<string>();

            await MainThread.InvokeOnMainThreadAsync(() =>
            {
                var openPanel = new NSOpenPanel
                {
                    CanChooseFiles = false,
                    CanChooseDirectories = true,
                    AllowsMultipleSelection = false,
                    CanCreateDirectories = false
                };

                if (openPanel.RunModal() == 1)
                {
                    var url = openPanel.Url;
                    if (url != null)
                    {
                        tcs.SetResult(url.Path);
                        return;
                    }
                }

                tcs.SetResult(null);
            });

            return await tcs.Task;
        }
    }
}