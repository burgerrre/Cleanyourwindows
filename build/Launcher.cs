using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;

[assembly: AssemblyTitle("Cleanyourwindows")]
[assembly: AssemblyVersion("1.1.0.0")]
[assembly: AssemblyFileVersion("1.1.0.0")]

internal static class Launcher
{
    public static int Main(string[] args)
    {
        try
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            byte[] payload;
            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
            using (var buffer = new MemoryStream())
            {
                if (input == null) throw new InvalidDataException("Embedded payload is missing.");
                input.CopyTo(buffer);
                payload = buffer.ToArray();
            }
            string hash;
            using (var sha = SHA256.Create()) hash = BitConverter.ToString(sha.ComputeHash(payload)).Replace("-", "");
            if (args.Length == 1 && args[0] == "--verify")
            {
                Console.WriteLine("Payload SHA256: " + hash);
                return 0;
            }
            string root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Cleanyourwindows", "Sessions", DateTime.UtcNow.ToString("yyyyMMdd-HHmmss") + "-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            using (var memory = new MemoryStream(payload))
            using (var archive = new ZipArchive(memory, ZipArchiveMode.Read))
            {
                string prefix = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
                foreach (ZipArchiveEntry entry in archive.Entries)
                {
                    string target = Path.GetFullPath(Path.Combine(root, entry.FullName));
                    if (!target.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                        throw new InvalidDataException("Invalid archive entry.");
                    if (entry.Name.Length == 0) { Directory.CreateDirectory(target); continue; }
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    entry.ExtractToFile(target, false);
                }
            }
            if (args.Length == 1 && args[0] == "--extract-only")
            {
                Console.WriteLine("Extracted / Распаковано: " + root);
                return 0;
            }
            Console.WriteLine("Files / Файлы: " + root);
            string powerShell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
            string start = Path.Combine(root, "Start-Debloat.ps1");
            var options = new ProcessStartInfo(powerShell,
                "-NoProfile -ExecutionPolicy Bypass -File \"" + start + "\"");
            options.UseShellExecute = false;
            options.WorkingDirectory = root;
            using (Process process = Process.Start(options))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("Launch failed / Ошибка запуска: " + error.Message);
            Console.WriteLine("Press Enter / Нажмите Enter");
            Console.ReadLine();
            return 1;
        }
    }
}
