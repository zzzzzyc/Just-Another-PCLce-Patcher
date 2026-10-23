using System.Reflection;
using System.Runtime.Loader;

internal static class StartupHook
{
    public static void Initialize()
    {
        // Child .NET processes should start without inheriting this hook.
        Environment.SetEnvironmentVariable("DOTNET_STARTUP_HOOKS", null);
        var directory = Path.GetDirectoryName(typeof(StartupHook).Assembly.Location)!;
        AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.Combine(directory, "0Harmony.dll"));
        Patches.Apply();
    }
}

internal static class Patches
{
    private static PropertyInfo _configKey = null!;
    private static MethodInfo _text = null!;
    private static object _strikethrough = null!;
    private static readonly Dictionary<string, string> Options = LoadOptions();
    private static bool Enabled(string key) => !Options.TryGetValue(key, out var value) || value != "0";

    private static Dictionary<string, string> LoadOptions()
    {
        var path = Path.Combine(Path.GetDirectoryName(typeof(Patches).Assembly.Location)!, "Hook.ini");
        return File.Exists(path)
            ? File.ReadLines(path).Where(line => line.Contains('='))
                .Select(line => line.Split('=', 2)).ToDictionary(pair => pair[0].Trim(), pair => pair[1].Trim())
            : new();
    }

    internal static void Apply()
    {
        var core = Assembly.Load("PCL.Core");
        var regionType = core.GetType("PCL.Core.App.Region.RegionAssessment", throwOnError: true)!;
        var profileType = core.GetType("PCL.Core.Minecraft.Profile.ProfileService", throwOnError: true)!;
        var region = regionType.GetProperty("IsRestricted")!.GetMethod!;
        var profile = profileType.GetProperty("HasMicrosoftProfile")!.GetMethod!;
        var harmony = new HarmonyLib.Harmony("JustAnotherPclcePatcher");
        if (Enabled("UnlockRegion")) harmony.Patch(region, prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(Unrestricted)));
        if (Enabled("UnlockProfiles")) harmony.Patch(profile, prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(HasMicrosoftProfile)));
        var configItem = core.GetType("PCL.Core.App.Configuration.ConfigItem`1", true)!.MakeGenericType(typeof(bool));
        _configKey = configItem.GetProperty("Key")!;
        harmony.Patch(configItem.GetMethod("GetValue"), prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(ReadDisabledOptions)));
        if (Enabled("DisableTelemetry")) harmony.Patch(configItem.GetMethod("SetValue"), prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(WriteTelemetry)));

        var app = Assembly.Load("Plain Craft Launcher 2");
        if (Enabled("DisableTelemetry"))
        {
            _text = core.GetType("PCL.Core.App.Localization.Lang", true)!.GetMethod("Text", [typeof(string)])!;
            _strikethrough = Type.GetType("System.Windows.TextDecorations, PresentationCore", true)!
                .GetProperty("Strikethrough")!.GetValue(null)!;
            var main = app.GetType("PCL.ModMain", true)!;
            harmony.Patch(main.GetMethod("MyMsgBox"), prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(TelemetryButtons)));
            var dialog = app.GetType("PCL.MyMsgText", true)!;
            harmony.Patch(dialog.GetConstructor([main.GetNestedType("MyMsgBoxConverter")!]),
                postfix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(StrikeTelemetry)));
        }
        if (Enabled("UnlockProfiles"))
            harmony.Patch(app.GetType("PCL.PageLoginProfile", true)!.GetConstructor(Type.EmptyTypes),
                postfix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(ProfileHint)));

        var disableLobbyTelemetry = Environment.GetEnvironmentVariable("PCL_HOOK_DISABLE_LOBBY_TELEMETRY") == "1" || Enabled("DisableLobbyTelemetry");
        var lobbyTelemetry = core.GetType("PCL.Core.Link.Lobby.LobbyController", true)!
            .GetMethod("_SendTelemetryAsync", BindingFlags.Static | BindingFlags.NonPublic)!;
        if (disableLobbyTelemetry)
            harmony.Patch(lobbyTelemetry, prefix: new HarmonyLib.HarmonyMethod(typeof(Patches), nameof(SkipLobbyTelemetry)));
        Console.WriteLine("[PCL Hook] Loaded Hook.ini settings");

    }

    private static bool Unrestricted(ref bool __result)
    {
        __result = false;
        return false;
    }

    private static bool HasMicrosoftProfile(ref bool __result)
    {
        __result = true;
        return false;
    }

    private static bool ReadDisabledOptions(object __instance, ref bool __result)
    {
        var key = (string)_configKey.GetValue(__instance)!;
        if (!(key == "SystemTelemetry" && Enabled("DisableTelemetry")) &&
            !(key == "UiLauncherCEHint" && Enabled("HideCommunityHint"))) return true;
        __result = false;
        return false;
    }

    private static void WriteTelemetry(object __instance, ref bool value, ref bool forceNewValue)
    {
        if ((string)_configKey.GetValue(__instance)! != "SystemTelemetry") return;
        value = false;
        forceNewValue = true;
    }

    internal static string Text(string key) => (string)_text.Invoke(null, [key])!;

    internal static void TelemetryButtons(string? title, ref string? button1, ref string? button2)
    {
        if (title == Text("Main.Telemetry.Title"))
            button1 = button2 = "不同意";
    }

    private static void StrikeTelemetry(object __instance, object converter)
    {
        if ((string?)converter.GetType().GetField("Title")!.GetValue(converter) != Text("Main.Telemetry.Title")) return;
        var caption = __instance.GetType().GetField("LabCaption", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(__instance)!;
        caption.GetType().GetProperty("TextDecorations")!.SetValue(caption, _strikethrough);
    }

    private static void ProfileHint(object __instance)
    {
        var hint = __instance.GetType().GetField("HintMicrosoft", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(__instance)!;
        hint.GetType().GetProperty("Text")!.SetValue(hint, "不需要先进行一次正版验证才能使用其他验证方式");
    }

    private static bool SkipLobbyTelemetry(ref Task<bool> __result)
    {
        __result = Task.FromResult(true);
        return false;
    }

}
