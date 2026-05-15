package com.tapresearch.tapresearch_flutter_plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import org.mockito.Mockito.verify
import kotlin.test.Test

/*
 * Unit tests for TapresearchFlutterPlugin.onMethodCall argument validation.
 *
 * Run from the command line with `./gradlew testDebugUnitTest` in `example/android/`,
 * or directly from Android Studio / IntelliJ.
 */

internal class TapresearchFlutterPluginTest {

    private fun plugin() = TapresearchFlutterPlugin()
    private fun mockResult(): MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    @Test
    fun onMethodCall_unknownMethod_callsNotImplemented() {
        val result = mockResult()
        plugin().onMethodCall(MethodCall("unknownMethod", null), result)
        verify(result).notImplemented()
    }

    // initialize

    @Test
    fun onMethodCall_initialize_missingApiToken_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("initialize", hashMapOf("userIdentifier" to "user-1")),
            result,
        )
        verify(result).error("INVALID_ARG", "apiToken required", null)
    }

    @Test
    fun onMethodCall_initialize_missingUserIdentifier_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("initialize", hashMapOf("apiToken" to "test-token")),
            result,
        )
        verify(result).error("INVALID_ARG", "userIdentifier required", null)
    }

    // setUserIdentifier

    @Test
    fun onMethodCall_setUserIdentifier_missingArg_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(MethodCall("setUserIdentifier", null), result)
        verify(result).error("INVALID_ARG", "userIdentifier required", null)
    }

    // canShowContentForPlacement

    @Test
    fun onMethodCall_canShowContentForPlacement_missingTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("canShowContentForPlacement", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "tag required", null)
    }

    // sendUserAttributes

    @Test
    fun onMethodCall_sendUserAttributes_missingArg_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("sendUserAttributes", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "userAttributes required", null)
    }

    // showContentForPlacement

    @Test
    fun onMethodCall_showContentForPlacement_missingTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("showContentForPlacement", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "tag required", null)
    }

    // hasSurveysForPlacement

    @Test
    fun onMethodCall_hasSurveysForPlacement_missingPlacementTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("hasSurveysForPlacement", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "placementTag required", null)
    }

    // getSurveysForPlacement

    @Test
    fun onMethodCall_getSurveysForPlacement_missingPlacementTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("getSurveysForPlacement", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "placementTag required", null)
    }

    // showSurveyForPlacement

    @Test
    fun onMethodCall_showSurveyForPlacement_missingPlacementTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("showSurveyForPlacement", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "placementTag required", null)
    }

    @Test
    fun onMethodCall_showSurveyForPlacement_missingSurveyId_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("showSurveyForPlacement", hashMapOf("placementTag" to "earn-center")),
            result,
        )
        verify(result).error("INVALID_ARG", "surveyId required", null)
    }

    // grantBoost

    @Test
    fun onMethodCall_grantBoost_missingBoostTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("grantBoost", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "boostTag required", null)
    }

    // getPlacementDetails

    @Test
    fun onMethodCall_getPlacementDetails_missingPlacementTag_returnsError() {
        val result = mockResult()
        plugin().onMethodCall(
            MethodCall("getPlacementDetails", hashMapOf<String, Any>()),
            result,
        )
        verify(result).error("INVALID_ARG", "placementTag required", null)
    }
}
