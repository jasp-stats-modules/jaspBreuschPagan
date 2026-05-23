import QtQuick
import JASP.Module

Description
{
	name		: "jaspBreuschPagan"
	title		: qsTr("Breusch-Pagan Test")
	description	: qsTr("Test for heteroskedasticity in linear regression via the Breusch-Pagan test.")
	version		: "0.1.0"
	author		: "Your Name"
	maintainer	: "Your Name <you@example.com>"
	website		: "https://jasp-stats.org"
	license		: "GPL (>= 2)"
	icon		: "exampleIcon.svg" // Located in /inst/icons/
	preloadData	: true
	requiresData: true

	Analysis
	{
		title:	qsTr("Breusch-Pagan Test")  // Title for window
		menu:	qsTr("Breusch-Pagan Test")   // Title for ribbon
		func:	"breuschPagan"               // R function to call
		qml:	"BreuschPagan.qml"           // Input form
	}
}
