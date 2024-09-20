// Services/IFolderPicker.cs
using System.Threading.Tasks;

namespace FolderPickerApp.Services
{
    public interface IFolderPicker
    {
        Task<string> PickFolder();
    }
}