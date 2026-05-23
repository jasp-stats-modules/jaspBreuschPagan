//
// Copyright (C) 2013-2024 University of Amsterdam
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//

import QtQuick
import QtQuick.Layouts
import JASP.Controls
import JASP.Widgets
import JASP

Form
{
	info: qsTr("Performs the Breusch-Pagan test for heteroskedasticity. " +
			   "Select the dependent variable and the predictor(s) of a linear " +
			   "regression; the analysis fits the model, takes the squared " +
			   "residuals, runs the auxiliary regression and reports the " +
			   "LM = n \u00d7 R\u00b2 statistic with its \u03c7\u00b2 p-value.")

	// Visible reminder shown directly on the form
	Text
	{
		Layout.columnSpan	: 2
		Layout.fillWidth	: true
		wrapMode		: Text.WordWrap
		textFormat		: Text.RichText
		text			: "<b>" + qsTr("Note:") + "</b> " +
			qsTr("The dependent variable should be the <b>residuals from an " +
				 "already-fitted regression</b>. Run your linear regression first, " +
				 "save its residuals as a new column, and select that column here " +
				 "together with the same predictors. The test then performs the " +
				 "Breusch-Pagan auxiliary regression on those residuals.")
	}

	VariablesForm
	{
		AvailableVariablesList { name: "allVariables" }

		AssignedVariablesList
		{
			name:           "dependent"
			title:          qsTr("Dependent variable (residuals)")
			info:           qsTr("The residuals saved from an already-fitted regression model. " +
								  "Run your linear regression first and save its residuals as a column, " +
								  "then select that column here.")
			singleVariable: true
			allowedColumns: ["scale"]
		}

		AssignedVariablesList
		{
			name:           "covariates"
			title:          qsTr("Predictors")
			info:           qsTr("One or more predictors of the regression model (x). " +
								  "The Breusch-Pagan test uses these same predictors in the " +
								  "auxiliary regression of the squared residuals.")
			allowedColumns: ["scale", "ordinal", "nominal"]
		}
	}

	RadioButtonGroup
	{
		name:  "testType"
		title: qsTr("Test variant")

		RadioButton
		{
			value:   "koenker"
			label:   qsTr("Studentized (Koenker)")
			checked: true
			info:    qsTr("The robust default. Regresses the raw squared residuals " +
						   "on the predictors and uses LM = n \u00d7 R\u00b2 ~ \u03c7\u00b2(k). " +
						   "This matches lmtest::bptest() and is not sensitive to " +
						   "non-normal errors.")
		}

		RadioButton
		{
			value: "original"
			label: qsTr("Original Breusch-Pagan (1979)")
			info:  qsTr("The classic version that assumes normally distributed errors. " +
						"Regresses the scaled squared residuals and uses half the " +
						"explained sum of squares as the statistic.")
		}
	}

	Group
	{
		title: qsTr("Output")

		CheckBox
		{
			name:    "auxiliaryRegression"
			label:   qsTr("Auxiliary regression table")
			checked: true
			info:    qsTr("Show the coefficients of the auxiliary regression " +
						   "(squared residuals on the predictors), including its R\u00b2.")
		}

		CheckBox
		{
			name:  "residualPlot"
			label: qsTr("Residuals vs. fitted plot")
			info:  qsTr("A scatter plot of the regression residuals against the " +
						"fitted values. A fan or funnel shape suggests heteroskedasticity.")
		}
	}
}
