#r "nuget: Newtonsoft.Json"

using Newtonsoft.Json.Linq;
using System.IO;

string NormalizePathInput(string value)
{
    return value.Trim().Trim('"', '\'');
}

string GetFolderFromUser()
{
    Console.WriteLine("Enter your Epic Games folder path");
    Console.WriteLine("(Tip: you can drag the folder into this window):");

    Console.Write("> ");

    var input = Console.ReadLine() ?? "";

    // Drag-and-drop paths come in quotes, so trim them
    input = NormalizePathInput(input);

    while (!Directory.Exists(input))
    {
        Console.WriteLine("That path doesn't exist. Try again:");
        Console.Write("> ");
        input = NormalizePathInput(Console.ReadLine() ?? "");
    }

    return input;
}

string gameRoot;

// Argument provided?
if (Args.Count > 0)
{
    // Join all args to support unquoted paths with spaces in shells.
    gameRoot = NormalizePathInput(string.Join(" ", Args));
    if (!Directory.Exists(gameRoot))
    {
        Console.WriteLine($"Argument path '{gameRoot}' is invalid.");
        gameRoot = GetFolderFromUser();
    }
}
else
{
    gameRoot = GetFolderFromUser();
}

Console.WriteLine($"Using Epic game folder: {gameRoot}");
Console.WriteLine();

var manifestOut = @"C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests";
var launcherInstalledPath = @"C:\ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat";

JObject launcherInstalled;
JArray installationList;
var useLegacyItems = Directory.Exists(manifestOut);

if (!useLegacyItems)
{
    var launcherDir = Path.GetDirectoryName(launcherInstalledPath)!;
    Directory.CreateDirectory(launcherDir);

    if (File.Exists(launcherInstalledPath))
    {
        launcherInstalled = JObject.Parse(File.ReadAllText(launcherInstalledPath));
    }
    else
    {
        launcherInstalled = new JObject();
    }

    installationList = launcherInstalled["InstallationList"] as JArray ?? new JArray();
    launcherInstalled["InstallationList"] = installationList;
}
else
{
    launcherInstalled = new JObject();
    installationList = new JArray();
}

var createdCount = 0;

foreach (var dir in Directory.GetDirectories(gameRoot))
{
    var manifestPath = Path.Combine(dir, ".egstore", "Manifest.sjson");
    if (!File.Exists(manifestPath))
    {
        Console.WriteLine($"Skipping {Path.GetFileName(dir)} — no Manifest.sjson");
        continue;
    }

    var json = JObject.Parse(File.ReadAllText(manifestPath));

    var item = new JObject
    {
        ["FormatVersion"] = 0,
        ["AppName"] = json["AppName"],
        ["CatalogItemId"] = json["CatalogItemId"],
        ["CatalogNamespace"] = json["CatalogNamespace"],
        ["DisplayName"] = json["DisplayName"],
        ["InstallLocation"] = dir,
        ["InstallSize"] = json["InstallSize"],
        ["MainGameAppName"] = json["AppName"],
        ["MandatoryPatchSequence"] = 0
    };

    if (useLegacyItems)
    {
        var fileName = $"{Guid.NewGuid():N}.item";
        var outPath = Path.Combine(manifestOut, fileName);
        File.WriteAllText(outPath, item.ToString());
        Console.WriteLine($"Created legacy manifest for {json["DisplayName"]}");
        createdCount++;
        continue;
    }

    var appName = json["AppName"]?.ToString() ?? Path.GetFileName(dir);
    var existing = installationList
        .OfType<JObject>()
        .FirstOrDefault(x =>
            string.Equals(x["InstallLocation"]?.ToString(), dir, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(x["AppName"]?.ToString(), appName, StringComparison.OrdinalIgnoreCase));

    if (existing != null)
    {
        installationList.Remove(existing);
    }

    var installEntry = new JObject
    {
        ["InstallLocation"] = dir,
        ["NamespaceId"] = json["CatalogNamespace"]?.ToString() ?? "",
        ["ItemId"] = json["CatalogItemId"]?.ToString() ?? "",
        ["ArtifactId"] = appName,
        ["AppVersion"] = json["BuildVersion"]?.ToString() ?? "",
        ["AppName"] = appName
    };

    installationList.Add(installEntry);
    Console.WriteLine($"Registered launcher install for {json["DisplayName"]}");
    createdCount++;
}

if (!useLegacyItems)
{
    File.WriteAllText(launcherInstalledPath, launcherInstalled.ToString());
    Console.WriteLine();
    Console.WriteLine($"Updated {launcherInstalledPath} with {createdCount} entries.");
}

Console.WriteLine();
Console.WriteLine("Done! Restart Epic Games Launcher to rediscover your library.");
