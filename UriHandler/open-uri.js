// Opens every http(s) URL in a .uri text file with the default browser.
// Run by wscript.exe so no console window appears.
var fso = new ActiveXObject("Scripting.FileSystemObject");
var shell = new ActiveXObject("Shell.Application");

if (WScript.Arguments.length < 1) { WScript.Quit(1); }

var file = fso.OpenTextFile(WScript.Arguments(0), 1);
while (!file.AtEndOfStream) {
    var line = file.ReadLine().replace(/^\s+|\s+$/g, "");
    if (/^https?:\/\//i.test(line)) {
        shell.ShellExecute(line);
    }
}
file.Close();
