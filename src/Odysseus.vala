/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016-2017).
*
* Odysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Odysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Odysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
public class Odysseus.Application : Granite.Application {
    construct {
        this.flags |= ApplicationFlags.HANDLES_OPEN;
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain ("odysseus");

        app_launcher = "com.github.alcinnz.odysseus.desktop";
        program_name = "Odysseus";
        build_version = "1";
        exec_name = application_id = "com.github.alcinnz.odysseus";
    }

    private static Odysseus.Application _instance = null;
    public static Odysseus.Application instance {
        get {
            if (_instance == null)
                _instance = new Odysseus.Application();
            return _instance;
        }
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        activate();

        var window = get_active_window() as BrowserWindow;
        var args = command_line.get_arguments();
        for (var i = 1; i < args.length; i++) {
            var arg = args[i];
            if (arg == "--tab") arg = "odysseus:home";
            else if (arg == "--search") {
                i++;
                arg = "https://ddg.gg/?q=" + Soup.URI.encode(args[i], null);
            } else if (arg == "--window") {
                var win = new BrowserWindow.from_new_entry();
                win.new_tab();
                win.show_all();
                continue;
            }

            window.new_tab(arg);
        }

        return 0;
    }

    public void initialize() {
        Gtk.IconTheme.get_default().add_resource_path("/io/github/alcinnz/Odysseus/odysseus:/");

        // Ensure configuration folder exists
        try {
            var config = File.new_for_path(Environment.get_user_config_dir());
            config = config.get_child("com.github.alcinnz.odysseus");
            if (!config.query_exists()) config.make_directory_with_parents();
        } catch (Error err) {
            error("Failed to setup configuration directory!\n" +
                "Is ~/.config readonly?");
        }

        // Make sure odysseus:special/restore is parsed only once
        // by priming the cache.
        try {
            Templating.ErrorData? error_data = null;
            var path = "/io/github/alcinnz/Odysseus/odysseus:/special/restore";
            Templating.get_for_resource(path, ref error_data);
        } catch {/* This error will be reported again later. */}

        // Setup application-unique resources.
        var is_first_start = Odysseus.Database.setup_database();
        Odysseus.Traits.setup_autosuggest();

        // Create main application window, upon restore failure.
        if (is_first_start) {
            var window = new BrowserWindow.from_new_entry();
            window.new_tab();
            window.show_all();
        } else Persist.restore_application();
    }

    private bool initialized = false;
    public override void activate() {
        if (!initialized) {
            initialize();
            initialized = true;
        }
    }
}

public static int main(string[] args) {
    return Odysseus.Application.instance.run(args);
}
