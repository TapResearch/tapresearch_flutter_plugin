import Flutter
import TapResearch

// MARK: - Per-call delegate wrappers

private final class ContentDelegateWrapper: NSObject, TapResearchContentDelegate {
    let onShown: (String) -> Void
    let onDismissed: (String) -> Void

    init(onShown: @escaping (String) -> Void, onDismissed: @escaping (String) -> Void) {
        self.onShown = onShown
        self.onDismissed = onDismissed
    }

    func onTapResearchContentShown(forPlacement placement: String) { onShown(placement) }
    func onTapResearchContentDismissed(forPlacement placement: String) { onDismissed(placement) }
}

private final class GrantBoostDelegateWrapper: NSObject, TapResearchGrantBoostResponseDelegate {
    let onResponse: (TRGrantBoostResponse) -> Void
    init(onResponse: @escaping (TRGrantBoostResponse) -> Void) { self.onResponse = onResponse }
    func onTapResearchGrantBoostResponse(_ response: TRGrantBoostResponse) { onResponse(response) }
}

private final class NoOpContentDelegate: NSObject, TapResearchContentDelegate {
    static let shared = NoOpContentDelegate()
    func onTapResearchContentShown(forPlacement placement: String) {}
    func onTapResearchContentDismissed(forPlacement placement: String) {}
}

private final class NoOpGrantBoostDelegate: NSObject, TapResearchGrantBoostResponseDelegate {
    static let shared = NoOpGrantBoostDelegate()
    func onTapResearchGrantBoostResponse(_ response: TRGrantBoostResponse) {}
}

// MARK: - Plugin

public class TapresearchFlutterPlugin: NSObject, FlutterPlugin,
    TapResearchSDKDelegate, TapResearchRewardDelegate,
    TapResearchQuickQuestionDelegate, TapResearchSurveysDelegate {

    private var channel: FlutterMethodChannel!
    private var hasRewardCallback = false
    private var hasQqCallback = false
    private var contentDelegates: [Int: ContentDelegateWrapper] = [:]
    private var grantBoostDelegates: [Int: GrantBoostDelegateWrapper] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "tapresearch_flutter_plugin",
            binaryMessenger: registrar.messenger()
        )
        let instance = TapresearchFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private func invokeOnMain(_ method: String, arguments: Any?) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(method, arguments: arguments)
        }
    }

    // MARK: - TapResearchSDKDelegate

    public func onTapResearchSdkReady() {
        invokeOnMain("onSdkReady", arguments: nil)
    }

    public func onTapResearchDidError(_ error: NSError) {
        invokeOnMain("onError", arguments: (["source": "initialize"] as [String: Any]).merging(errorToDict(error)) { $1 })
    }

    // MARK: - TapResearchRewardDelegate

    public func onTapResearchDidReceiveRewards(_ rewards: [TRReward]) {
        guard hasRewardCallback else { return }
        invokeOnMain("onReward", arguments: rewards.map { rewardToDict($0) })
    }

    // MARK: - TapResearchQuickQuestionDelegate

    public func onTapResearchQuickQuestionResponse(_ qqPayload: TRQQDataPayload) {
        guard hasQqCallback else { return }
        invokeOnMain("onQuickQuestionData", arguments: qqDataToDict(qqPayload))
    }

    // MARK: - TapResearchSurveysDelegate

    public func onTapResearchSurveysRefreshed(forPlacement placementTag: String) {
        invokeOnMain("onSurveysRefreshed", arguments: ["placementTag": placementTag])
    }

    // MARK: - FlutterPlugin method handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "initialize":
            handleInitialize(args: args, result: result)
        case "setUserIdentifier":
            guard let id = args["userIdentifier"] as? String else {
                return result(FlutterError(code: "INVALID_ARG", message: "userIdentifier required", details: nil))
            }
            TapResearch.setUserIdentifier(id)
            result(nil)
        case "canShowContentForPlacement":
            handleCanShowContentForPlacement(args: args, result: result)
        case "sendUserAttributes":
            handleSendUserAttributes(args: args, result: result)
        case "showContentForPlacement":
            handleShowContentForPlacement(args: args, result: result)
        case "isReady":
            result(TapResearch.isReady())
        case "setSurveysRefreshedListener":
            let enable = args["enable"] as? Bool ?? true
            TapResearch.setSurveysDelegate(enable ? self : nil)
            result(nil)
        case "hasSurveysForPlacement":
            handleHasSurveysForPlacement(args: args, result: result)
        case "getSurveysForPlacement":
            handleGetSurveysForPlacement(args: args, result: result)
        case "showSurveyForPlacement":
            handleShowSurveyForPlacement(args: args, result: result)
        case "grantBoost":
            handleGrantBoost(args: args, result: result)
        case "getPlacementDetails":
            handleGetPlacementDetails(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Handlers

    private func handleInitialize(args: [String: Any], result: @escaping FlutterResult) {
        guard let apiToken = args["apiToken"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "apiToken required", details: nil))
        }
        guard let userIdentifier = args["userIdentifier"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "userIdentifier required", details: nil))
        }
        hasRewardCallback = args["hasRewardCallback"] as? Bool ?? false
        hasQqCallback = args["hasQqCallback"] as? Bool ?? false
        let userAttributes = args["userAttributes"] as? [String: Any]
        let clearPrevious = args["clearPreviousAttributes"] as? Bool ?? false

        if let ua = userAttributes {
            TapResearch.initialize(
                withAPIToken: apiToken,
                userIdentifier: userIdentifier,
                userAttributes: ua,
                clearPreviousAttributes: clearPrevious,
                sdkDelegate: self
            )
        } else {
            TapResearch.initialize(withAPIToken: apiToken, userIdentifier: userIdentifier, sdkDelegate: self)
        }

        if hasRewardCallback { TapResearch.setRewardDelegate(self) }
        if hasQqCallback { TapResearch.setQuickQuestionDelegate(self) }
        result(nil)
    }

    private func handleCanShowContentForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["tag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "tag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let canShow = TapResearch.canShowContent(forPlacement: tag, error: { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "canShowContentForPlacement"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
        })
        result(canShow)
    }

    private func handleSendUserAttributes(args: [String: Any], result: @escaping FlutterResult) {
        guard let userAttributes = args["userAttributes"] as? [String: Any] else {
            return result(FlutterError(code: "INVALID_ARG", message: "userAttributes required", details: nil))
        }
        let clearPrevious = args["clearPreviousAttributes"] as? Bool ?? false
        _ = TapResearch.sendUserAttributes(attributes: userAttributes, clearPreviousAttributes: clearPrevious)
        result(nil)
    }

    private func handleShowContentForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["tag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "tag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let hasContentCallback = args["hasContentCallback"] as? Bool ?? false
        let customParameters = args["customParameters"] as? [String: Any]

        let delegate: TapResearchContentDelegate
        if hasContentCallback {
            let wrapper = ContentDelegateWrapper(
                onShown: { [weak self] placement in
                    self?.invokeOnMain("onContentShown", arguments: ["callId": callId, "placementTag": placement])
                },
                onDismissed: { [weak self] placement in
                    self?.invokeOnMain("onContentDismissed", arguments: ["callId": callId, "placementTag": placement])
                    self?.contentDelegates.removeValue(forKey: callId)
                }
            )
            contentDelegates[callId] = wrapper
            delegate = wrapper
        } else {
            delegate = NoOpContentDelegate.shared
        }

        let errorHandler: (NSError?) -> Void = { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "showContentForPlacement"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
            self.contentDelegates.removeValue(forKey: callId)
        }

        if let cp = customParameters {
            TapResearch.showContent(forPlacement: tag, delegate: delegate, customParameters: cp, completion: errorHandler)
        } else {
            TapResearch.showContent(forPlacement: tag, delegate: delegate, completion: errorHandler)
        }
        result(nil)
    }

    private func handleHasSurveysForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let has = TapResearch.hasSurveys(for: tag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "hasSurveysForPlacement"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
        })
        result(has)
    }

    private func handleGetSurveysForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let surveys = TapResearch.getSurveys(for: tag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "getSurveysForPlacement"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
        })
        result(surveys.map { surveyToDict($0) })
    }

    private func handleShowSurveyForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementTag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        guard let surveyId = args["surveyId"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "surveyId required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let hasContentCallback = args["hasContentCallback"] as? Bool ?? false
        let customParameters = args["customParameters"] as? [String: Any]

        let delegate: TapResearchContentDelegate
        if hasContentCallback {
            let wrapper = ContentDelegateWrapper(
                onShown: { [weak self] pt in
                    self?.invokeOnMain("onContentShown", arguments: ["callId": callId, "placementTag": pt])
                },
                onDismissed: { [weak self] pt in
                    self?.invokeOnMain("onContentDismissed", arguments: ["callId": callId, "placementTag": pt])
                    self?.contentDelegates.removeValue(forKey: callId)
                }
            )
            contentDelegates[callId] = wrapper
            delegate = wrapper
        } else {
            delegate = NoOpContentDelegate.shared
        }

        let errorHandler: (NSError?) -> Void = { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "showSurveyForPlacement"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
            self.contentDelegates.removeValue(forKey: callId)
        }

        if let cp = customParameters {
            TapResearch.showSurvey(surveyId: surveyId, placementTag: placementTag, delegate: delegate, customParameters: cp, errorHandler: errorHandler)
        } else {
            TapResearch.showSurvey(surveyId: surveyId, placementTag: placementTag, delegate: delegate, errorHandler: errorHandler)
        }
        result(nil)
    }

    private func handleGrantBoost(args: [String: Any], result: @escaping FlutterResult) {
        guard let boostTag = args["boostTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "boostTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let hasListener = args["hasListener"] as? Bool ?? false

        let delegate: TapResearchGrantBoostResponseDelegate
        if hasListener {
            let wrapper = GrantBoostDelegateWrapper { [weak self] response in
                guard let self else { return }
                var dict = self.grantBoostResponseToDict(response)
                dict["callId"] = callId
                self.invokeOnMain("onGrantBoostResponse", arguments: dict)
                self.grantBoostDelegates.removeValue(forKey: callId)
            }
            grantBoostDelegates[callId] = wrapper
            delegate = wrapper
        } else {
            delegate = NoOpGrantBoostDelegate.shared
        }

        TapResearch.grantBoost(boostTag, delegate: delegate, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "grantBoost"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
            self.grantBoostDelegates.removeValue(forKey: callId)
        })
        result(nil)
    }

    private func handleGetPlacementDetails(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementTag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let details = TapResearch.getPlacementDetails(placementTag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeOnMain("onError", arguments: (["callId": callId, "source": "getPlacementDetails"] as [String: Any]).merging(self.errorToDict(error)) { $1 })
        })
        result(details.map { placementDetailsToDict($0) })
    }

    // MARK: - Serialization helpers

    private func errorToDict(_ error: NSError) -> [String: Any] {
        ["error_code": error.code, "message": error.localizedDescription]
    }

    private func rewardToDict(_ reward: TRReward) -> [String: Any?] {
        [
            "transactionIdentifier": reward.transactionIdentifier,
            "placementIdentifier": reward.placementIdentifier,
            "currencyName": reward.currencyName,
            "rewardAmount": reward.rewardAmount,
            "payoutEventType": reward.payoutEvent,
            "placementTag": reward.placementTag,
        ]
    }

    private func surveyToDict(_ survey: TRSurvey) -> [String: Any?] {
        [
            "survey_identifier": survey.surveyIdentifier,
            "length_in_minutes": survey.lengthInMinutes,
            "reward_amount": survey.rewardAmount,
            "currency_name": survey.currencyName,
            "is_sale": survey.isSale,
            "sale_end_date": survey.saleEndDate,
            "sale_multiplier": survey.saleMultiplier,
            "pre_sale_reward_amount": survey.preSaleRewardAmount,
            "is_hot_tile": survey.isHotTile,
            "category": survey.category,
        ]
    }

    private func placementDetailsToDict(_ details: TRPlacementDetails) -> [String: Any?] {
        [
            "name": details.name,
            "content_type": details.contentType,
            "currency_name": details.currencyName,
            "is_sale": details.isSale,
            "sale_type": details.saleType,
            "sale_end_date": details.saleEndDate,
            "sale_multiplier": details.saleMultiplier,
            "sale_display_name": details.saleDisplayName,
            "sale_tag": details.saleTag,
            "bonus_bar_progress": details.bonusBarProgress.map { bonusBarProgressToDict($0) },
        ]
    }

    private func bonusBarProgressToDict(_ progress: TRBonusBarProgress) -> [String: Any?] {
        [
            "is_active": progress.isActive,
            "current_completes": progress.currentCompletes,
            "bonus_window_end_at": progress.bonusWindowEndAt,
            "bonus_tiers": progress.bonusTiers?.map { bonusTierToDict($0) },
            "error": progress.error.map { errorToDict($0) },
        ]
    }

    private func bonusTierToDict(_ tier: TRBonusTier) -> [String: Any?] {
        [
            "tier_number": tier.tierNumber,
            "completes_needed": tier.completesNeeded,
            "reward_amount": tier.rewardAmount,
            "status": tier.status,
        ]
    }

    private func grantBoostResponseToDict(_ response: TRGrantBoostResponse) -> [String: Any?] {
        [
            "boost_tag": response.boostTag,
            "success": response.success,
            "error": response.error.map { errorToDict($0) },
        ]
    }

    private func qqDataToDict(_ data: TRQQDataPayload) -> [String: Any?] {
        [
            "survey_identifier": data.survey_identifier,
            "app_name": data.app_name,
            "api_token": data.api_token,
            "sdk_version": data.sdk_version,
            "platform": data.platform,
            "placement_tag": data.placement_tag,
            "user_identifier": data.user_identifier,
            "user_locale": data.user_locale,
            "seen_at": data.seen_at,
            "complete": data.complete.map {
                ["complete_identifier": $0.complete_identifier, "completed_at": $0.completed_at]
            },
            "questions": data.questions.map { q -> [String: Any?] in
                [
                    "question_identifier": q.question_identifier,
                    "question_text": q.question_text,
                    "question_type": q.question_type,
                    "user_answer": q.user_answer.map {
                        ["value": $0.value, "identifiers": $0.identifiers]
                    },
                ]
            },
            "target_audience": data.target_audience?.map { ta -> [String: Any] in
                [
                    "filter_attribute_name": ta.filter_attribute_name,
                    "filter_operator": ta.filter_operator,
                    "filter_value": ta.filter_value,
                    "user_value": ta.user_value,
                ]
            },
        ]
    }
}
