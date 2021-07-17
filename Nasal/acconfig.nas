# Aircraft Config Center V2.0.0
# Copyright (c) 2021 Josh Davidson (Octal450)

var CONFIG = {
	minFgfsInt: num(string.replace(getprop("/sim/minimum-fg-version"), ".", "")),
	minFgfsString: getprop("/sim/minimum-fg-version"),
	minOptionsRevision: 1, # Minimum revision of supported options
	noUpdateCheck: 0, # Disable ACCONFIG Update Checks
};

var SYSTEM = {
	autoConfigRunning: props.globals.getNode("/systems/acconfig/autoconfig-running"),
	Error: {
		code: props.globals.initNode("/systems/acconfig/error-code", "0x000", "STRING"),
		outOfDate: 0,
		reason: props.globals.initNode("/systems/acconfig/error-reason", "", "STRING"),
	},
	fgfs: num(string.replace(getprop("/sim/version/flightgear"), ".", "")),
	newRevision: props.globals.initNode("/systems/acconfig/new-revision", 0, "INT"),
	revision: props.globals.initNode("/systems/acconfig/revision", 0, "INT"),
	revisionTemp: 0,
	spinner: "\\",
	simInit: func() {
		PANEL.stop = 1;
		me.autoConfigRunning.setBoolValue(0);
		spinningT.start();
		fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-init"}));
		if (!CONFIG.noUpdateCheck) {
			http.load("https://raw.githubusercontent.com/Octal450/MD-80/master/revision.txt").done(func(r) me.newRevision.setValue(r.response));
		}
		me.revision.setValue(io.readfile(getprop("/sim/aircraft-dir") ~ "/revision.txt"));
		print("System: MD-80 Revision " ~ me.revision.getValue());
	},
	fdmInit: func() {
		me.revisionTemp = me.revision.getValue();
		
		if (!CONFIG.noUpdateCheck) {
			if (me.newRevision.getValue() > me.revisionTemp) {
				me.Error.outOfDate = 1;
				print("System: Aircraft update available!");
			} else {
				me.Error.outOfDate = 0;
				print("System: No aircraft update available!");
			}
		} else {
			print("System: Update checks have been turned off!");
		}
		
		fgcommand("dialog-close", props.Node.new({"dialog-name": "acconfig-init"}));
		spinningT.stop();
		
		me.errorCheck();
		OPTIONS.read();
		
		if (!CONFIG.noUpdateCheck) { # Update Checks Enabled
			if (me.Error.outOfDate) {
				fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-update"}));
			} else if (me.Error.code.getValue() == "0x000") {
				if (OPTIONS.savedRevision.getValue() < me.revisionTemp) {
					fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-updated"}));
				} else if (!OPTIONS.welcomeSkip.getBoolValue()) {
					fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-welcome"}));
				}
				
				# Only do on successful init
				RENDERING.check();
				OPTIONS.savedRevision.setValue(me.revisionTemp);
				OPTIONS.write();
			}
		} else { # No Update Checks
			if (me.Error.code.getValue() == "0x000") {
				if (!OPTIONS.welcomeSkip.getBoolValue()) {
					fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-welcome"}));
				}
				
				# Only do on successful init
				RENDERING.check();
				OPTIONS.savedRevision.setValue(me.revisionTemp);
				OPTIONS.write();
			}
		}
	},
	errorCheck: func() {
		if (SYSTEM.fgfs < CONFIG.minFgfsInt) {
			me.Error.code.setValue("0x121");
			me.Error.reason.setValue("FGFS version is too old! Please update FlightGear to at least " ~ CONFIG.minFgfsString ~ ".");
			me.showError();
			print("System: Error 0x121");
		} else if (getprop("/gear/gear[0]/wow") == 0 or getprop("/position/altitude-ft") >= 15000) {
			me.Error.code.setValue("0x223");
			me.Error.reason.setValue("Preposterous configuration detected for initialization. Check your position or scenery.");
			me.showError();
			print("System: Error 0x223");
		} else if (getprop("/systems/acconfig/libraries-loaded") != 1 or getprop("/systems/acconfig/property-tree-setup-loaded") != 1) {
			me.Error.code.setValue("0x247");
			me.Error.reason.setValue("System files are missing or damaged. Please download a new copy of the aircraft.");
			me.showError();
			print("System: Error 0x247");
		}
	},
	showError: func() {
		libraries.systemsLoop.stop();
		systems.DUController.showError();
		fgcommand("dialog-close", props.Node.new({"dialog-name": "acconfig-updated"}));
		fgcommand("dialog-close", props.Node.new({"dialog-name": "acconfig-welcome"}));
		fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-error"}));
		# Kill menu items
		setprop("/sim/menubar/default/menu[101]/enabled", 0);
		setprop("/sim/menubar/default/menu[102]/enabled", 0);
		setprop("/sim/menubar/default/menu[103]/enabled", 0);
		setprop("/sim/menubar/default/menu[104]/enabled", 0);
	},
	resetFailures: func() {
		systems.ELEC.resetFailures();
		systems.FCTL.resetFailures();
		systems.FUEL.resetFailures();
		systems.GEAR.resetFailures();
		systems.HYD.resetFailures();
	},
	spinning: func() {
		if (me.spinner == "\\") {
			me.spinner = "|";
		} else if (me.spinner == "|") {
			me.spinner = "/";
		} else if (me.spinner == "/") {
			me.spinner = "-";
		} else if (me.spinner == "-") {
			me.spinner = "\\";
		}
		props.globals.getNode("/systems/acconfig/spinner-prop").setValue(me.spinner);
	},
};

var RENDERING = {
	als: props.globals.getNode("/sim/rendering/shaders/skydome"),
	alsMode: props.globals.getNode("/sim/gui/dialogs/advanced/mode/als-mode", 1),
	customSettings: props.globals.getNode("/sim/rendering/shaders/custom-settings"),
	landmass: props.globals.getNode("/sim/rendering/shaders/landmass"),
	landmassSet: 0,
	lowSpecMode: props.globals.getNode("/sim/gui/dialogs/advanced/mode/low-spec-mode", 1),
	model: props.globals.getNode("/sim/rendering/shaders/model"),
	modelEffects: props.globals.getNode("/sim/gui/dialogs/advanced/model-effects", 1),
	modelSet: 0,
	rembrandt: props.globals.getNode("/sim/rendering/rembrandt/enabled"),
	check: func() {
		if (OPTIONS.noRenderingWarn.getBoolValue()) {
			return;
		}
		
		me.landmassSet = me.landmass.getValue() >= 4;
		me.modelSet = me.model.getValue() >= 3;
		
		if (SYSTEM.fgfs >= 202040) {
			if (!me.rembrandt.getBoolValue() and (!me.als.getBoolValue() or !me.landmassSet or !me.modelSet)) {
				fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-rendering"}));
			}
		} else {
			if (!me.rembrandt.getBoolValue() and (!me.als.getBoolValue() or !me.customSettings.getBoolValue() or !me.landmassSet or !me.modelSet)) {
				fgcommand("dialog-show", props.Node.new({"dialog-name": "acconfig-rendering"}));
			}
		}
	},
	fixAll: func() {
		# Don't override higher settings
		if (me.landmass.getValue() < 4) {
			me.landmass.setValue(4);
			if (SYSTEM.fgfs >= 202040) {
				me.modelEffects.setValue("Medium");
			}
		}
		if (me.model.getValue() < 3) {
			me.model.setValue(3);
			if (SYSTEM.fgfs >= 202040) {
				me.modelEffects.setValue("Enabled");
			}
		}
		
		me.fixCore();
	},
	fixCore: func() {
		me.als.setBoolValue(1); # ALS on
		if (SYSTEM.fgfs >= 202040) {
			me.alsMode.setBoolValue(1);
			me.lowSpecMode.setBoolValue(0);
		} else {
			me.customSettings.setBoolValue(1);
		}
		
		print("System: Rendering Settings updated!");
		gui.popupTip("System: Rendering settings updated!");
	},
};

var OPTIONS = {
	noRenderingWarn: props.globals.initNode("/systems/acconfig/options/no-rendering-warn", 0, "BOOL"),
	savedRevision: props.globals.initNode("/systems/acconfig/options/saved-revision", 0, "INT"),
	tempRevision: props.globals.initNode("/systems/acconfig/temp/saved-revision", 0, "INT"),
	welcomeSkip: props.globals.initNode("/systems/acconfig/options/welcome-skip", 0, "BOOL"),
	read: func() {
		io.read_properties(getprop("/sim/fg-home") ~ "/Export/MD-80-options.xml", "/systems/acconfig/temp");
		
		# Only load if options is new enough
		if (me.tempRevision.getValue() < CONFIG.minOptionsRevision) {
			print("System: Options reset!");
			gui.popupTip("System: Aircraft Options have been reset due to aircraft installation/update!", 10);
		} else {
			io.read_properties(getprop("/sim/fg-home") ~ "/Export/MD-80-options.xml", "/systems/acconfig/options");
			
			# These aren't stored in acconfig themselves, so we move them there
			setprop("/sim/model/autopush/route/show", getprop("/systems/acconfig/options/autopush/show-route"));
			setprop("/sim/model/autopush/route/show-wingtip", getprop("/systems/acconfig/options/autopush/show-wingtip"));
			print("System: Options loaded successfully!");
		}
	},
	write: func() {
		# These aren't stored in acconfig themselves, so we move them there
		setprop("/systems/acconfig/options/autopush/show-route", getprop("/sim/model/autopush/route/show"));
		setprop("/systems/acconfig/options/autopush/show-wingtip", getprop("/sim/model/autopush/route/show-wingtip"));
		
		io.write_properties(getprop("/sim/fg-home") ~ "/Export/MD-80-options.xml", "/systems/acconfig/options");
	},
};

# Panel States specifically designed to work with IntegratedSystems design
var PANEL = {
	stop: 1,
	cancel: func() {
		me.stop = 1; # Kill timers
	},
	panelBase: func(t) {
		
	},
	coldDark: func() {
		
	},
	beforeStart: func() {
		
	},
	afterStart: func(t) {
		
	},
};

var spinningT = maketimer(0.05, SYSTEM, SYSTEM.spinning);
SYSTEM.simInit();

setlistener("/sim/signals/fdm-initialized", func() {
	SYSTEM.fdmInit();
});

setlistener("/sim/signals/reinit", func(s) {
	if (!s.getBoolValue() and libraries.initDone) {
		#PANEL.coldDark(1);
		
		libraries.systemsInit();
		pts.Services.Chocks.enable.setBoolValue(1);
		setprop("/controls/lighting/main-digital-norm", 0);
		settimer(func() {
			setprop("/controls/engines/engine[0]/cutoff", 1);
			setprop("/controls/engines/engine[1]/cutoff", 1);
			setprop("/controls/engines/engine[0]/starter", 0);
			setprop("/controls/engines/engine[1]/starter", 0);
			setprop("/engines/engine[0]/state", 0);
			setprop("/engines/engine[1]/state", 0);
		}, 1);
	}
});
