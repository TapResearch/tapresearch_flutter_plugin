@file:OptIn(kotlinx.serialization.InternalSerializationApi::class)

package com.tapresearch.tapresearch_flutter_plugin

import java.lang.ref.WeakReference
import android.content.Context
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.tapresearch.tapsdk.TapInitOptions
import com.tapresearch.tapsdk.TapResearch
import com.tapresearch.tapsdk.callback.TRContentCallback
import com.tapresearch.tapsdk.callback.TRErrorCallback
import com.tapresearch.tapsdk.callback.TRGrantBoostResponseListener
import com.tapresearch.tapsdk.callback.TRQQDataCallback
import com.tapresearch.tapsdk.callback.TRRewardCallback
import com.tapresearch.tapsdk.callback.TRSdkReadyCallback
import com.tapresearch.tapsdk.callback.TRSurveysRefreshedListener
import com.tapresearch.tapsdk.models.PayoutTypes
import com.tapresearch.tapsdk.models.QQPayload
import com.tapresearch.tapsdk.models.TRError
import com.tapresearch.tapsdk.models.TRGrantBoostResponse
import com.tapresearch.tapsdk.models.TRPlacementDetails
import com.tapresearch.tapsdk.models.TRReward
import com.tapresearch.tapsdk.models.TRSurvey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TapresearchFlutterPlugin : FlutterPlugin, MethodCallHandler {

    companion object {

        // edit to be same as tapresearch_flutter_plugin version in pubspec.yaml!
        const val VERSION = "3.7.0--rc1"
    }

    private var applicationContext: WeakReference<Context>? = null

    private lateinit var channel: MethodChannel
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.applicationContext = WeakReference(binding.getApplicationContext())
        channel = MethodChannel(binding.binaryMessenger, "tapresearch_flutter_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "setUserIdentifier" -> {
                val id = call.argument<String>("userIdentifier")
                    ?: return result.error("INVALID_ARG", "userIdentifier required", null)
                TapResearch.setUserIdentifier(id)
                result.success(null)
            }
            "canShowContentForPlacement" -> handleCanShowContentForPlacement(call, result)
            "sendUserAttributes" -> handleSendUserAttributes(call, result)
            "showContentForPlacement" -> handleShowContentForPlacement(call, result)
            "isReady" -> result.success(TapResearch.isReady())
            "setSurveysRefreshedListener" -> {
                val enable = call.argument<Boolean>("enable") ?: true
                TapResearch.setSurveysRefreshedListener(if (enable) object : TRSurveysRefreshedListener {
                    override fun onSurveysRefreshedForPlacement(placementTag: String) {
                        invokeOnMain("onSurveysRefreshed", mapOf("placementTag" to placementTag))
                    }
                } else null)
                result.success(null)
            }
            "hasSurveysForPlacement" -> handleHasSurveysForPlacement(call, result)
            "getSurveysForPlacement" -> handleGetSurveysForPlacement(call, result)
            "showSurveyForPlacement" -> handleShowSurveyForPlacement(call, result)
            "grantBoost" -> handleGrantBoost(call, result)
            "getPlacementDetails" -> handleGetPlacementDetails(call, result)
            else -> result.notImplemented()
        }
    }

    private fun invokeOnMain(method: String, args: Any?) {
        mainHandler.post { channel.invokeMethod(method, args) }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val flutterVersion = call.argument<String>("flutterVersion")
            ?: return result.error("INVALID_ARG", "flutterVersion required", null)
        val apiToken = call.argument<String>("apiToken")
            ?: return result.error("INVALID_ARG", "apiToken required", null)
        val userIdentifier = call.argument<String>("userIdentifier")
            ?: return result.error("INVALID_ARG", "userIdentifier required", null)
        val hasRewardCallback = call.argument<Boolean>("hasRewardCallback") ?: false
        val hasQqCallback = call.argument<Boolean>("hasQqCallback") ?: false
        val userAttributes = call.argument<HashMap<String, Any>>("userAttributes")
        val clearPreviousAttributes = call.argument<Boolean>("clearPreviousAttributes")

        val initOptions = if (userAttributes != null || clearPreviousAttributes != null)
            TapInitOptions(userAttributes = userAttributes, clearPreviousAttributes = clearPreviousAttributes)
        else null

        storeAttributes(applicationContext?.get(), flutterVersion)
        TapResearch.initialize(
            apiToken = apiToken,
            userIdentifier = userIdentifier,
            sdkReadyCallback = object : TRSdkReadyCallback {
                override fun onTapResearchSdkReady() {
                    invokeOnMain("onSdkReady", null)
                }
            },
            errorCallback = object : TRErrorCallback {
                override fun onTapResearchDidError(error: TRError) {
                    invokeOnMain("onError", mapOf("source" to "initialize") + errorToMap(error))
                }
            },
            rewardCallback = if (hasRewardCallback) object : TRRewardCallback {
                override fun onTapResearchDidReceiveRewards(rewards: MutableList<TRReward>) {
                    invokeOnMain("onReward", rewards.map { rewardToMap(it) })
                }
            } else null,
            qqDataCallback = if (hasQqCallback) object : TRQQDataCallback {
                override fun onQuickQuestionDataReceived(data: QQPayload) {
                    invokeOnMain("onQuickQuestionData", qqDataToMap(data))
                }
            } else null,
            initOptions = initOptions,
        )
        result.success(null)
    }

    private fun handleCanShowContentForPlacement(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val tag = call.argument<String>("tag")
            ?: return result.error("INVALID_ARG", "tag required", null)
        val canShow = TapResearch.canShowContentForPlacement(tag, object : TRErrorCallback {
            override fun onTapResearchDidError(error: TRError) {
                invokeOnMain("onError", mapOf("callId" to callId, "source" to "canShowContentForPlacement") + errorToMap(error))
            }
        })
        result.success(canShow)
    }

    private fun handleSendUserAttributes(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val userAttributes = call.argument<HashMap<String, Any>>("userAttributes")
            ?: return result.error("INVALID_ARG", "userAttributes required", null)
        val clearPreviousAttributes = call.argument<Boolean>("clearPreviousAttributes")
        TapResearch.sendUserAttributes(
            userAttributes = userAttributes,
            clearPreviousAttributes = clearPreviousAttributes,
            errorCallback = object : TRErrorCallback {
                override fun onTapResearchDidError(error: TRError) {
                    invokeOnMain("onError", mapOf("callId" to callId, "source" to "sendUserAttributes") + errorToMap(error))
                }
            },
        )
        result.success(null)
    }

    private fun handleShowContentForPlacement(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val tag = call.argument<String>("tag")
            ?: return result.error("INVALID_ARG", "tag required", null)
        val customParameters = call.argument<HashMap<String, Any>>("customParameters")
        val hasContentCallback = call.argument<Boolean>("hasContentCallback") ?: false

        TapResearch.showContentForPlacement(
            tag = tag,
            contentCallback = if (hasContentCallback) object : TRContentCallback {
                override fun onTapResearchContentShown(placementTag: String) {
                    invokeOnMain("onContentShown", mapOf("callId" to callId, "placementTag" to placementTag))
                }
                override fun onTapResearchContentDismissed(placementTag: String) {
                    invokeOnMain("onContentDismissed", mapOf("callId" to callId, "placementTag" to placementTag))
                }
            } else null,
            customParameters = customParameters,
            errorCallback = object : TRErrorCallback {
                override fun onTapResearchDidError(error: TRError) {
                    invokeOnMain("onError", mapOf("callId" to callId, "source" to "showContentForPlacement") + errorToMap(error))
                }
            },
        )
        result.success(null)
    }

    private fun handleHasSurveysForPlacement(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val tag = call.argument<String>("placementTag")
            ?: return result.error("INVALID_ARG", "placementTag required", null)
        val has = TapResearch.hasSurveysForPlacement(tag, object : TRErrorCallback {
            override fun onTapResearchDidError(error: TRError) {
                invokeOnMain("onError", mapOf("callId" to callId, "source" to "hasSurveysForPlacement") + errorToMap(error))
            }
        })
        result.success(has)
    }

    private fun handleGetSurveysForPlacement(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val tag = call.argument<String>("placementTag")
            ?: return result.error("INVALID_ARG", "placementTag required", null)
        val surveys = TapResearch.getSurveysForPlacement(tag, object : TRErrorCallback {
            override fun onTapResearchDidError(error: TRError) {
                invokeOnMain("onError", mapOf("callId" to callId, "source" to "getSurveysForPlacement") + errorToMap(error))
            }
        })
        result.success(surveys?.map { surveyToMap(it) })
    }

    private fun handleShowSurveyForPlacement(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val placementTag = call.argument<String>("placementTag")
            ?: return result.error("INVALID_ARG", "placementTag required", null)
        val surveyId = call.argument<String>("surveyId")
            ?: return result.error("INVALID_ARG", "surveyId required", null)
        val customParameters = call.argument<HashMap<String, Any>>("customParameters")
        val hasContentCallback = call.argument<Boolean>("hasContentCallback") ?: false

        TapResearch.showSurveyForPlacement(
            placementTag = placementTag,
            surveyId = surveyId,
            customParameters = customParameters,
            contentListener = if (hasContentCallback) object : TRContentCallback {
                override fun onTapResearchContentShown(pt: String) {
                    invokeOnMain("onContentShown", mapOf("callId" to callId, "placementTag" to pt))
                }
                override fun onTapResearchContentDismissed(pt: String) {
                    invokeOnMain("onContentDismissed", mapOf("callId" to callId, "placementTag" to pt))
                }
            } else null,
            errorListener = object : TRErrorCallback {
                override fun onTapResearchDidError(error: TRError) {
                    invokeOnMain("onError", mapOf("callId" to callId, "source" to "showSurveyForPlacement") + errorToMap(error))
                }
            },
        )
        result.success(null)
    }

    private fun handleGrantBoost(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val boostTag = call.argument<String>("boostTag")
            ?: return result.error("INVALID_ARG", "boostTag required", null)
        val hasListener = call.argument<Boolean>("hasListener") ?: false

        TapResearch.grantBoost(
            boostTag = boostTag,
            grantBoostResponseListener = if (hasListener) object : TRGrantBoostResponseListener {
                override fun onGrantBoostResponse(response: TRGrantBoostResponse) {
                    invokeOnMain("onGrantBoostResponse", mapOf("callId" to callId) + grantBoostResponseToMap(response))
                }
            } else null,
        )
        result.success(null)
    }

    private fun handleGetPlacementDetails(call: MethodCall, result: Result) {
        val callId = call.argument<Int>("callId") ?: 0
        val placementTag = call.argument<String>("placementTag")
            ?: return result.error("INVALID_ARG", "placementTag required", null)
        val details = TapResearch.getPlacementDetails(
            placementTag = placementTag,
            errorListener = object : TRErrorCallback {
                override fun onTapResearchDidError(error: TRError) {
                    invokeOnMain("onError", mapOf("callId" to callId, "source" to "getPlacementDetails") + errorToMap(error))
                }
            },
        )
        result.success(details?.let { placementDetailsToMap(it) })
    }

    // MARK: - Serialization helpers

    private fun errorToMap(error: TRError): Map<String, Any?> = mapOf(
        "error_code" to error.code,
        "message" to error.description,
    )

    private fun rewardToMap(reward: TRReward): Map<String, Any?> = mapOf(
        "transactionIdentifier" to reward.transactionIdentifier,
        "placementIdentifier" to reward.placementIdentifier,
        "currencyName" to reward.currencyName,
        "rewardAmount" to reward.rewardAmount,
        "payoutEventType" to reward.payoutEventType?.let { name ->
            try { PayoutTypes.valueOf(name).value } catch (_: Exception) { null }
        },
        "placementTag" to reward.placementTag,
    )

    private fun surveyToMap(survey: TRSurvey): Map<String, Any?> = mapOf(
        "survey_identifier" to survey.surveyId,
        "length_in_minutes" to survey.lengthInMinutes,
        "reward_amount" to survey.rewardAmount,
        "currency_name" to survey.currencyName,
        "is_sale" to survey.isSale,
        "sale_end_date" to survey.saleEndDate,
        "sale_multiplier" to survey.saleMultiplier,
        "pre_sale_reward_amount" to survey.preSaleRewardAmount,
        "is_hot_tile" to survey.isHotTile,
        "category" to survey.category,
    )

    private fun placementDetailsToMap(details: TRPlacementDetails): Map<String, Any?> = mapOf(
        "name" to details.name,
        "content_type" to details.contentType,
        "currency_name" to details.currencyName,
        "is_sale" to details.isSale,
        "sale_type" to details.saleType,
        "sale_end_date" to details.saleEndDate,
        "sale_multiplier" to details.saleMultiplier,
        "sale_display_name" to details.saleDisplayName,
        "sale_tag" to details.saleTag,
        "bonus_bar_progress" to details.bonusBarProgress?.let { bonusBarProgressToMap(it) },
    )

    private fun bonusBarProgressToMap(progress: com.tapresearch.tapsdk.models.TRBonusBarProgress): Map<String, Any?> = mapOf(
        "is_active" to progress.isActive,
        "current_completes" to progress.currentCompletes,
        "bonus_window_end_at" to progress.bonusWindowEndAt,
        "bonus_tiers" to progress.bonusTiers?.map { bonusTierToMap(it) },
        "error" to progress.error?.let { errorToMap(it) },
    )

    private fun bonusTierToMap(tier: com.tapresearch.tapsdk.models.TRBonusTier): Map<String, Any?> = mapOf(
        "tier_number" to tier.tierNumber,
        "completes_needed" to tier.completesNeeded,
        "reward_amount" to tier.rewardAmount,
        "status" to tier.status,
    )

    private fun grantBoostResponseToMap(response: TRGrantBoostResponse): Map<String, Any?> = mapOf(
        "boost_tag" to response.boostTag,
        "success" to response.success,
        "error" to response.error?.let { errorToMap(it) },
    )

    private fun qqDataToMap(data: QQPayload): Map<String, Any?> = mapOf(
        "survey_identifier" to data.surveyIdentifier,
        "app_name" to data.appName,
        "api_token" to data.apiToken,
        "sdk_version" to data.sdkVersion,
        "platform" to data.platform,
        "placement_tag" to data.placementTag,
        "user_identifier" to data.userIdentifier,
        "user_locale" to data.userLocale,
        "seen_at" to data.seenAt,
        "complete" to data.complete?.let {
            mapOf("complete_identifier" to it.completeIdentifier, "completed_at" to it.completedAt)
        },
        "questions" to data.questions.map { q ->
            mapOf(
                "question_identifier" to q.questionIdentifier,
                "question_text" to q.questionText,
                "question_type" to q.questionType,
                "user_answer" to q.userAnswer?.let {
                    mapOf("value" to it.value, "identifiers" to it.identifiers)
                },
            )
        },
        "target_audience" to data.targetAudience?.toList(),
    )

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun storeAttributes(context: Context?, flutterVersion: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                context?.let {
                    it.getSharedPreferences("tr_orca_params", 0).edit()
                        .putString("dev_platform", "flutter")
                        .putString("dev_version", VERSION)
                        .putString("dev_engine_version", flutterVersion)
                        .commit()
                }
            }catch (_: Throwable){}
        }
    }
}
