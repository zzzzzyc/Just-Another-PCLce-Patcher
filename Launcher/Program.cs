using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        try
        {
            string directory = AppDomain.CurrentDomain.BaseDirectory;
            string target = args.FirstOrDefault(a => !a.StartsWith("-"));
            if (target == null)
            {
                var candidates = Directory.GetFiles(directory, "*.exe")
                    .Concat(Directory.Exists(Path.Combine(directory, "Original"))
                        ? Directory.GetFiles(Path.Combine(directory, "Original"), "*.exe") : new string[0])
                    .Where(p => FileVersionInfo.GetVersionInfo(p).ProductName == "Plain Craft Launcher Community Edition")
                    .ToArray();
                if (candidates.Length != 1)
                    throw new Exception("请在同目录或 Original 子目录放置一个 PCL CE EXE。");
                target = candidates[0];
            }
            target = Path.GetFullPath(target);
            string hook = Path.Combine(directory, "Hook.dll");
            if (!File.Exists(hook)) throw new Exception("找不到 Hook.dll，请解压完整运行包。");
            var start = new ProcessStartInfo(target) {
                WorkingDirectory = Path.GetDirectoryName(target),
                UseShellExecute = false,
                CreateNoWindow = true
            };
            start.EnvironmentVariables["DOTNET_STARTUP_HOOKS"] = hook;
            start.EnvironmentVariables.Remove("PCL_HOOK_DISABLE_LOBBY_TELEMETRY");
            if (args.Any(a => a.Equals("-DisableLobbyTelemetry", StringComparison.OrdinalIgnoreCase)))
                start.EnvironmentVariables["PCL_HOOK_DISABLE_LOBBY_TELEMETRY"] = "1";
            Process.Start(start);
        }
        catch (Exception error)
        {
            Environment.ExitCode = 1;
            MessageBox.Show(error.Message, "PCL Hook", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
