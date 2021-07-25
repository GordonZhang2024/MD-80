# McDonnell Douglas MD-80 Buttons and Switches
# Copyright (c) 2021 Josh Davidson (Octal450)

# Resets buttons to the default values
var variousReset = func() {
	pts.Controls.Flight.dialAFlap.setValue(15);
	pts.Controls.Switches.minimums.setValue(200);
	pts.Controls.Switches.noSmokingSign.setValue(1); # Smoking is bad!
	pts.Controls.Switches.seatbeltSign.setValue(0);
	pts.Instrumentation.Hsi.slavedToGps[0].setBoolValue(0);
	pts.Instrumentation.Hsi.slavedToGps[1].setBoolValue(0);
}

var apPanel = {
	hdgTemp: 0,
	latTemp: 0,
	ktsTemp: 0,
	ktsFlchTemp: 0,
	machTemp: 0,
	machFlchTemp: 0,
	vertTemp: 0,
	apSwitch: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			if (dfgs.Output.ap1.getBoolValue() or dfgs.Output.ap2.getBoolValue()) {
				dfgs.ITAF.ap1Master(0);
				dfgs.ITAF.ap2Master(0);
			} else {
				if (dfgs.Input.activeAp.getValue() == 2) {
					dfgs.ITAF.ap2Master(1);
					dfgs.ITAF.ap1Master(0);
				} else {
					dfgs.ITAF.ap1Master(1);
					dfgs.ITAF.ap2Master(0);
				}
			}
		}
	},
	apSelector: func() {
		libraries.apPanel.apDisc();
		dfgs.Input.activeAp.setValue(!(dfgs.Input.activeAp.getValue() - 1) + 1); # This sh*t just toggles between 1 and 2
		dfgs.updateFma.capTrkReCheck();
	},
	apDisc: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			if (dfgs.Output.ap1.getBoolValue()) {
				dfgs.ITAF.ap1Master(0);
			}
			if (dfgs.Output.ap2.getBoolValue()) {
				dfgs.ITAF.ap2Master(0);
			}
		}
	},
	atDisc: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			if (dfgs.Output.athr.getBoolValue()) {
				dfgs.ITAF.athrMaster(0);
			}
		}
	},
	spdPush: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.ktsMach.setBoolValue(!dfgs.Input.ktsMach.getBoolValue());
		}
	},
	spdAdjust: func(d) {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			if (dfgs.Input.ktsMach.getBoolValue()) {
				me.machTemp = math.round(dfgs.Input.mach.getValue() + (d * 0.001), (abs(d * 0.001))); # Kill floating point error
				if (me.machTemp < 0.50) {
					dfgs.Input.mach.setValue(0.50);
				} else if (me.machTemp > 0.84) {
					dfgs.Input.mach.setValue(0.84);
				} else {
					dfgs.Input.mach.setValue(me.machTemp);
				}
			} else {
				me.ktsTemp = dfgs.Input.kts.getValue() + d;
				if (me.ktsTemp < 100) {
					dfgs.Input.kts.setValue(100);
				} else if (me.ktsTemp > 340) {
					dfgs.Input.kts.setValue(340);
				} else {
					dfgs.Input.kts.setValue(me.ktsTemp);
				}
			}
		}
	},
	spd: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.vertTemp = dfgs.Output.vert.getValue();
			dfgs.Input.ktsMach.setBoolValue(0);
			dfgs.Athr.setMode(0); # Thrust
			if (me.vertTemp == 4 or me.vertTemp == 7) {
				dfgs.Input.vert.setValue(1);
			}
		}
	},
	mach: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.vertTemp = dfgs.Output.vert.getValue();
			dfgs.Input.ktsMach.setBoolValue(1);
			dfgs.Athr.setMode(0); # Thrust
			if (me.vertTemp == 4 or me.vertTemp == 7) {
				dfgs.Input.vert.setValue(1);
			}
		}
	},
	eprLim: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Athr.setMode(2); # EPR Limit
		}
	},
	hdgPush: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.lat.setValue(3);
		}
	},
	hdgPull: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.lat.setValue(0);
		}
	},
	hdgAdjust: func(d) {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.hdgTemp = dfgs.Input.hdg.getValue() + d;
			if (me.hdgTemp < 0.5) {
				dfgs.Input.hdg.setValue(me.hdgTemp + 360);
			} else if (me.hdgTemp >= 360.5) {
				dfgs.Input.hdg.setValue(me.hdgTemp - 360);
			} else {
				dfgs.Input.hdg.setValue(me.hdgTemp);
			}
		}
	},
	nav: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.lat.setValue(1);
		}
	},
	vorLoc: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.lat.setValue(2);
		}
	},
	ils: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.ITAF.updateAutoLand(0);
			dfgs.Input.vert.setValue(2);
		}
	},
	autoLand: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.latTemp = dfgs.Output.lat.getValue();
			me.vertTemp = dfgs.Output.vert.getValue();
			if ((me.latTemp == 2 or me.latTemp == 4) and (dfgs.Output.apprArm.getBoolValue() or me.vertTemp == 2 or me.vertTemp == 6)) { # Check logic
				dfgs.ITAF.updateAutoLand(1);
			}
		}
	},
	vsAdjust: func(d) { # Called the pitch wheel this so that one binding works on many planes
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.vertTemp = dfgs.Output.vert.getValue();
			if (me.vertTemp == 1) {
				me.vsTemp = dfgs.Input.vs.getValue() + (d * 100);
				if (me.vsTemp < -6000) {
					dfgs.Input.vs.setValue(-6000);
				} else if (me.vsTemp > 6000) {
					dfgs.Input.vs.setValue(6000);
				} else {
					dfgs.Input.vs.setValue(me.vsTemp);
				}
			} else if (me.vertTemp == 4) {
				if (dfgs.Input.ktsMachFlch.getBoolValue()) {
					me.machFlchTemp = math.round(dfgs.Input.machFlch.getValue() + (d * -0.001), (abs(d * 0.001))); # Kill floating point error
					if (me.machFlchTemp < 0.50) {
						dfgs.Input.machFlch.setValue(0.50);
					} else if (me.machFlchTemp > 0.84) {
						dfgs.Input.machFlch.setValue(0.84);
					} else {
						dfgs.Input.machFlch.setValue(me.machFlchTemp);
					}
				} else {
					me.ktsFlchTemp = dfgs.Input.ktsFlch.getValue() + (d * -1);
					if (me.ktsFlchTemp < 100) {
						dfgs.Input.ktsFlch.setValue(100);
					} else if (me.ktsFlchTemp > 340) {
						dfgs.Input.ktsFlch.setValue(340);
					} else {
						dfgs.Input.ktsFlch.setValue(me.ktsFlchTemp);
					}
				}
			} else {
				dfgs.Input.vert.setValue(1);
			}
		}
	},
	altPush: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.altArmed.setBoolValue(0);
		}
	},
	altPull: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.vertTemp = dfgs.Output.vert.getValue();
			if (me.vertTemp != 0 and me.vertTemp != 2 and me.vertTemp != 6) {
				dfgs.Input.altArmed.setBoolValue(1);
			}
		}
	},
	altAdjust: func(d) {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			me.altTemp = dfgs.Input.alt.getValue();
			me.altTemp = math.round(me.altTemp + (d * 100), 100);
			if (me.altTemp < 0) {
				dfgs.Input.alt.setValue(0);
			} else if (me.altTemp > 50000) {
				dfgs.Input.alt.setValue(50000);
			} else {
				dfgs.Input.alt.setValue(me.altTemp);
			}
		}
	},
	vertSpd: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.vert.setValue(1);
		}
	},
	iasMach: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			if (dfgs.Output.vert.getValue() == 4) {
				if (dfgs.Velocities.indicatedMach.getValue() >= 0.4995) {
					dfgs.Input.ktsMachFlch.setBoolValue(!dfgs.Input.ktsMachFlch.getBoolValue());
				} else {
					dfgs.Input.ktsMachFlch.setBoolValue(0);
				}
			} else {
				if (dfgs.Position.indicatedAltitudeFt.getValue() >= 26995 and dfgs.Velocities.indicatedMach.getValue() >= 0.4995) {
					dfgs.Input.ktsMachFlch.setBoolValue(1);
				} else {
					dfgs.Input.ktsMachFlch.setBoolValue(0);
				}
				dfgs.Input.vert.setValue(4);
			}
		}
	},
	altHold: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.vert.setValue(0);
		}
	},
	toga: func() {
		if (systems.ELEC.Generic.fgcpPower.getBoolValue()) {
			dfgs.Input.toga.setValue(1);
		}
	},
};
