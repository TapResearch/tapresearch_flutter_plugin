import Flutter
import Foundation
import TapResearchSDK

// MARK: - ContentDelegateWrapper
/// ---------------------------------------------------------------------------------------------
/// ---------------------------------------------------------------------------------------------
private final class ContentDelegateWrapper: NSObject, TapResearchContentDelegate {
    private let onShown: (String) -> Void
    private let onDismissed: (String) -> Void

    /// ---------------------------------------------------------------------------------------------
    /// Creates a content delegate wrapper.
    ///
    /// - Parameters:
    ///   - onShown: Closure invoked when TapResearch content is shown for a placement.
    ///   - onDismissed: Closure invoked when TapResearch content is dismissed for a placement.
    /// - Returns: A wrapper that forwards TapResearch content delegate events.
    init(onShown: @escaping (String) -> Void, onDismissed: @escaping (String) -> Void) {
        self.onShown = onShown
        self.onDismissed = onDismissed
    }

    /// ---------------------------------------------------------------------------------------------
    /// Forwards a TapResearch content-shown event.
    ///
    /// - Parameter placement: Placement tag that displayed content.
    /// - Returns: Nothing.
    func onTapResearchContentShown(forPlacement placement: String) {
        onShown(placement)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Forwards a TapResearch content-dismissed event.
    ///
    /// - Parameter placement: Placement tag that dismissed content.
    /// - Returns: Nothing.
    func onTapResearchContentDismissed(forPlacement placement: String) {
        onDismissed(placement)
    }
}

// MARK: - GrantBoostDelegateWrapper
/// ---------------------------------------------------------------------------------------------
/// ---------------------------------------------------------------------------------------------
private final class GrantBoostDelegateWrapper: NSObject, TapResearchGrantBoostResponseDelegate {
    private let onResponse: (TRGrantBoostResponse) -> Void

    /// ---------------------------------------------------------------------------------------------
    /// Creates a grant-boost response delegate wrapper.
    ///
    /// - Parameter onResponse: Closure invoked with the TapResearch grant-boost response.
    /// - Returns: A wrapper that forwards grant-boost delegate responses.
    init(onResponse: @escaping (TRGrantBoostResponse) -> Void) {
        self.onResponse = onResponse
    }

    /// ---------------------------------------------------------------------------------------------
    /// Forwards a TapResearch grant-boost response event.
    ///
    /// - Parameter response: Grant-boost response emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    func onTapResearchGrantBoostResponse(_ response: TRGrantBoostResponse) {
        onResponse(response)
    }
}

// MARK: - NoOpContentDelegate
/// ---------------------------------------------------------------------------------------------
/// ---------------------------------------------------------------------------------------------
private final class NoOpContentDelegate: NSObject, TapResearchContentDelegate {
    static let shared = NoOpContentDelegate()

    /// ---------------------------------------------------------------------------------------------
    /// Ignores a TapResearch content-shown event when Dart did not request a callback.
    ///
    /// - Parameter placement: Placement tag that displayed content.
    /// - Returns: Nothing.
    func onTapResearchContentShown(forPlacement placement: String) {}

    /// ---------------------------------------------------------------------------------------------
    /// Ignores a TapResearch content-dismissed event when Dart did not request a callback.
    ///
    /// - Parameter placement: Placement tag that dismissed content.
    /// - Returns: Nothing.
    func onTapResearchContentDismissed(forPlacement placement: String) {}
}

// MARK: - NoOpGrantBoostDelegate
/// ---------------------------------------------------------------------------------------------
/// ---------------------------------------------------------------------------------------------
private final class NoOpGrantBoostDelegate: NSObject, TapResearchGrantBoostResponseDelegate {
    static let shared = NoOpGrantBoostDelegate()

    /// ---------------------------------------------------------------------------------------------
    /// Ignores a TapResearch grant-boost response when Dart did not request a callback.
    ///
    /// - Parameter response: Grant-boost response emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    func onTapResearchGrantBoostResponse(_ response: TRGrantBoostResponse) {}
}
// MARK: - TapresearchFlutterPlugin
/// ---------------------------------------------------------------------------------------------
/// ---------------------------------------------------------------------------------------------
@objc(TapresearchFlutterPlugin)
public final class TapresearchFlutterPlugin: NSObject, FlutterPlugin,
    TapResearchSDKDelegate, TapResearchRewardDelegate,
    TapResearchQuickQuestionDelegate, TapResearchSurveysDelegate {

	@objc public static let packageVersion: String = "3.8.0--rc1"

    private var channel: FlutterMethodChannel!
    private var hasRewardCallback = false
    private var hasQqCallback = false
    private var contentDelegates: [Int: ContentDelegateWrapper] = [:]
    private var grantBoostDelegates: [Int: GrantBoostDelegateWrapper] = [:]

    /// ---------------------------------------------------------------------------------------------
    /// Registers the TapResearch Flutter plugin with the Flutter engine.
    ///
    /// - Parameter registrar: Flutter registrar used to create and attach the method channel.
    /// - Returns: Nothing.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "tapresearch_flutter_plugin",
            binaryMessenger: registrar.messenger()
        )
        let instance = TapresearchFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Invokes a Dart method-channel callback on the main thread.
    ///
    /// - Parameters:
    ///   - method: Dart method name to invoke.
    ///   - arguments: Optional payload sent with the method invocation.
    /// - Returns: Nothing.
    private func invokeOnMain(_ method: String, arguments: Any?) {
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(method, arguments: arguments)
        }
    }

    /// ---------------------------------------------------------------------------------------------
    /// Reports that the TapResearch SDK is ready.
    ///
    /// - Returns: Nothing.
    public func onTapResearchSdkReady() {
        invokeOnMain("onSdkReady", arguments: nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Reports a TapResearch SDK initialization error to Dart.
    ///
    /// - Parameter error: NSError emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    public func onTapResearchDidError(_ error: NSError) {
        invokeError(callId: nil, source: "initialize", error: error)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Reports TapResearch rewards to Dart when a reward callback was registered.
    ///
    /// - Parameter rewards: Rewards emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    public func onTapResearchDidReceiveRewards(_ rewards: [TRReward]) {
        guard hasRewardCallback else { return }
        invokeOnMain("onReward", arguments: rewards.map { rewardToDict($0) })
    }

    /// ---------------------------------------------------------------------------------------------
    /// Reports quick-question data to Dart when a quick-question callback was registered.
    ///
    /// - Parameter qqPayload: Quick-question payload emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    public func onTapResearchQuickQuestionResponse(_ qqPayload: TRQQDataPayload) {
        guard hasQqCallback else { return }
        invokeOnMain("onQuickQuestionData", arguments: qqDataToDict(qqPayload))
    }

    /// ---------------------------------------------------------------------------------------------
    /// Reports refreshed surveys for a placement to Dart.
    ///
    /// - Parameter placementTag: Placement tag whose surveys were refreshed.
    /// - Returns: Nothing.
    public func onTapResearchSurveysRefreshed(forPlacement placementTag: String) {
        invokeOnMain("onSurveysRefreshed", arguments: ["placementTag": placementTag])
    }

    /// ---------------------------------------------------------------------------------------------
    /// Handles method-channel calls from Dart and forwards them to the TapResearch SDK.
    ///
    /// - Parameters:
    ///   - call: Flutter method call containing a method name and arguments.
    ///   - result: Flutter result callback used to return values or errors to Dart.
    /// - Returns: Nothing.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "initialize":
            handleInitialize(args: args, result: result)
        case "setUserIdentifier":
            handleSetUserIdentifier(args: args, result: result)
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

    /// ---------------------------------------------------------------------------------------------
    /// Initializes the TapResearch SDK from Dart arguments.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing API token, user identifier, callbacks, and attributes.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleInitialize(args: [String: Any], result: @escaping FlutterResult) {
        guard let flutterVersion = args["flutterVersion"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "flutterVersion required", details: nil))
        }
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

		UserDefaults.standard.set("flutter", forKey: "TRDevPlatform")
		UserDefaults.standard.set(packageVersion, forKey: "TRDevPlatformVersion")
		UserDefaults.standard.set(flutterVersion, forKey: "TREngineVersion")
		
        if let userAttributes {
            TapResearch.initialize(
                withAPIToken: apiToken,
                userIdentifier: userIdentifier,
                userAttributes: userAttributes,
                clearPreviousAttributes: clearPrevious,
                sdkDelegate: self
            )
        } else {
            TapResearch.initialize(withAPIToken: apiToken, userIdentifier: userIdentifier, sdkDelegate: self)
        }

        TapResearch.setRewardDelegate(hasRewardCallback ? self : nil)
        TapResearch.setQuickQuestionDelegate(hasQqCallback ? self : nil)
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Sets the TapResearch user identifier from Dart arguments.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing the user identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleSetUserIdentifier(args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["userIdentifier"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "userIdentifier required", details: nil))
        }
        TapResearch.setUserIdentifier(id)
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Checks whether TapResearch content can be shown for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing the placement tag and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleCanShowContentForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["tag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "tag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let canShow = TapResearch.canShowContent(forPlacement: tag, error: { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: "canShowContentForPlacement", error: error)
        })
        result(canShow)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Sends user attributes to TapResearch and forwards any returned error to Dart.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing attributes, clear flag, and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleSendUserAttributes(args: [String: Any], result: @escaping FlutterResult) {
        guard let userAttributes = args["userAttributes"] as? [String: Any] else {
            return result(FlutterError(code: "INVALID_ARG", message: "userAttributes required", details: nil))
        }

        let callId = args["callId"] as? Int ?? 0
        let clearPrevious = args["clearPreviousAttributes"] as? Bool ?? false
        if let error = TapResearch.sendUserAttributes(attributes: userAttributes, clearPreviousAttributes: clearPrevious) {
            invokeError(callId: callId, source: "sendUserAttributes", error: error)
        }
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Shows TapResearch content for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing placement, callbacks, and custom parameters.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleShowContentForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["tag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "tag required", details: nil))
        }

        let callId = args["callId"] as? Int ?? 0
        let hasContentCallback = args["hasContentCallback"] as? Bool ?? false
        let customParameters = args["customParameters"] as? [AnyHashable: Any]
        let delegate = makeContentDelegate(callId: callId, enabled: hasContentCallback)
        let errorHandler = makeContentErrorHandler(callId: callId, source: "showContentForPlacement")

        if let customParameters {
            TapResearch.showContent(forPlacement: tag, delegate: delegate, customParameters: customParameters, completion: errorHandler)
        } else {
            TapResearch.showContent(forPlacement: tag, delegate: delegate, completion: errorHandler)
        }
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Checks whether TapResearch has surveys for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing placement tag and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleHasSurveysForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let has = TapResearch.hasSurveys(for: tag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: "hasSurveysForPlacement", error: error)
        })
        result(has)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Gets TapResearch surveys for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing placement tag and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleGetSurveysForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let tag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let surveys = TapResearch.getSurveys(for: tag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: "getSurveysForPlacement", error: error)
        })
        result(surveys.map { surveyToDict($0) })
    }

    /// ---------------------------------------------------------------------------------------------
    /// Shows a specific TapResearch survey for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing placement, survey, callbacks, and custom parameters.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleShowSurveyForPlacement(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementTag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        guard let surveyId = args["surveyId"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "surveyId required", details: nil))
        }

        let callId = args["callId"] as? Int ?? 0
        let hasContentCallback = args["hasContentCallback"] as? Bool ?? false
        let customParameters = args["customParameters"] as? [AnyHashable: Any]
        let delegate = makeContentDelegate(callId: callId, enabled: hasContentCallback)
        let errorHandler = makeContentErrorHandler(callId: callId, source: "showSurveyForPlacement")

        if let customParameters {
            TapResearch.showSurvey(
                surveyId: surveyId,
                placementTag: placementTag,
                delegate: delegate,
                customParameters: customParameters,
                errorHandler: errorHandler
            )
        } else {
            TapResearch.showSurvey(
                surveyId: surveyId,
                placementTag: placementTag,
                delegate: delegate,
                errorHandler: errorHandler
            )
        }
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Grants a TapResearch boost.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing boost tag, callback flag, and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleGrantBoost(args: [String: Any], result: @escaping FlutterResult) {
        guard let boostTag = args["boostTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "boostTag required", details: nil))
        }

        let callId = args["callId"] as? Int ?? 0
        let hasListener = args["hasListener"] as? Bool ?? false
        let delegate = makeGrantBoostDelegate(callId: callId, enabled: hasListener)

        TapResearch.grantBoost(boostTag, delegate: delegate, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: "grantBoost", error: error)
            self.grantBoostDelegates.removeValue(forKey: callId)
        })
        result(nil)
    }

    /// ---------------------------------------------------------------------------------------------
    /// Gets TapResearch placement details for a placement.
    ///
    /// - Parameters:
    ///   - args: Method arguments containing placement tag and call identifier.
    ///   - result: Flutter result callback.
    /// - Returns: Nothing.
    private func handleGetPlacementDetails(args: [String: Any], result: @escaping FlutterResult) {
        guard let placementTag = args["placementTag"] as? String else {
            return result(FlutterError(code: "INVALID_ARG", message: "placementTag required", details: nil))
        }
        let callId = args["callId"] as? Int ?? 0
        let details = TapResearch.getPlacementDetails(placementTag, errorHandler: { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: "getPlacementDetails", error: error)
        })
        result(details.map { placementDetailsToDict($0) })
    }

    /// ---------------------------------------------------------------------------------------------
    /// Creates a content delegate for a call and retains it while content is visible.
    ///
    /// - Parameters:
    ///   - callId: Dart call identifier used to route callbacks.
    ///   - enabled: Whether Dart requested content callbacks for the call.
    /// - Returns: A TapResearch content delegate.
    private func makeContentDelegate(callId: Int, enabled: Bool) -> TapResearchContentDelegate {
        guard enabled else { return NoOpContentDelegate.shared }

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
        return wrapper
    }

    /// ---------------------------------------------------------------------------------------------
    /// Creates a content error handler that forwards errors and releases retained delegates.
    ///
    /// - Parameters:
    ///   - callId: Dart call identifier used to route callbacks.
    ///   - source: Method name associated with the TapResearch operation.
    /// - Returns: Closure suitable for TapResearch content error handling.
    private func makeContentErrorHandler(callId: Int, source: String) -> (NSError?) -> Void {
        { [weak self] error in
            guard let self, let error else { return }
            self.invokeError(callId: callId, source: source, error: error)
            self.contentDelegates.removeValue(forKey: callId)
        }
    }

    /// ---------------------------------------------------------------------------------------------
    /// Creates a grant-boost delegate for a call and retains it until a response or error.
    ///
    /// - Parameters:
    ///   - callId: Dart call identifier used to route callbacks.
    ///   - enabled: Whether Dart requested a grant-boost response callback for the call.
    /// - Returns: A TapResearch grant-boost response delegate.
    private func makeGrantBoostDelegate(callId: Int, enabled: Bool) -> TapResearchGrantBoostResponseDelegate {
        guard enabled else { return NoOpGrantBoostDelegate.shared }

        let wrapper = GrantBoostDelegateWrapper { [weak self] response in
            guard let self else { return }
            var dict = self.grantBoostResponseToDict(response)
            dict["callId"] = callId
            self.invokeOnMain("onGrantBoostResponse", arguments: dict)
            self.grantBoostDelegates.removeValue(forKey: callId)
        }
        grantBoostDelegates[callId] = wrapper
        return wrapper
    }

    /// ---------------------------------------------------------------------------------------------
    /// Sends a normalized TapResearch error payload to Dart.
    ///
    /// - Parameters:
    ///   - callId: Optional Dart call identifier used for per-call error callbacks.
    ///   - source: Method name associated with the TapResearch operation.
    ///   - error: NSError emitted by the TapResearch SDK.
    /// - Returns: Nothing.
    private func invokeError(callId: Int?, source: String, error: NSError) {
        var args: [String: Any] = ["source": source]
        if let callId {
            args["callId"] = callId
        }
        invokeOnMain("onError", arguments: args.merging(errorToDict(error)) { $1 })
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts a TapResearch NSError to the Dart error payload shape.
    ///
    /// - Parameter error: NSError emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing error code and message.
    private func errorToDict(_ error: NSError) -> [String: Any] {
        ["error_code": error.code, "message": error.localizedDescription]
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts a TapResearch reward to the Dart reward payload shape.
    ///
    /// - Parameter reward: Reward emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing reward fields expected by Dart models.
    private func rewardToDict(_ reward: TRReward) -> [String: Any?] {
        [
            "transactionIdentifier": reward.transactionIdentifier,
            "placementIdentifier": reward.placementIdentifier,
            "currencyName": reward.currencyName,
            "rewardAmount": reward.rewardAmount,
            "payoutEventType": payoutEventToValue(reward.payoutEvent),
            "placementTag": reward.placementTag,
        ]
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts an iOS TapResearch payout event string to the Dart enum wire value.
    ///
    /// - Parameter payoutEvent: Optional payout event string emitted by the iOS SDK.
    /// - Returns: Integer payout type value when recognized; otherwise nil.
    private func payoutEventToValue(_ payoutEvent: String?) -> Int? {
        guard let normalized = payoutEvent?
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .lowercased() else {
            return nil
        }

        switch normalized {
        case "profilereward":
            return 0
        case "partialpayout":
            return 1
        case "fullpayout":
            return 3
        case "quickquestionspayout":
            return 9
        default:
            return Int(normalized)
        }
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts a TapResearch survey to the Dart survey payload shape.
    ///
    /// - Parameter survey: Survey emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing survey fields expected by Dart models.
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

    /// ---------------------------------------------------------------------------------------------
    /// Converts TapResearch placement details to the Dart placement details payload shape.
    ///
    /// - Parameter details: Placement details emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing placement details fields expected by Dart models.
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

    /// ---------------------------------------------------------------------------------------------
    /// Converts TapResearch bonus bar progress to the Dart bonus bar payload shape.
    ///
    /// - Parameter progress: Bonus bar progress emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing bonus bar progress fields expected by Dart models.
    private func bonusBarProgressToDict(_ progress: TRBonusBarProgress) -> [String: Any?] {
        [
            "is_active": progress.isActive,
            "current_completes": progress.currentCompletes,
            "bonus_window_end_at": progress.bonusWindowEndAt,
            "bonus_tiers": progress.bonusTiers?.map { bonusTierToDict($0) },
            "error": progress.error.map { errorToDict($0) },
        ]
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts a TapResearch bonus tier to the Dart bonus tier payload shape.
    ///
    /// - Parameter tier: Bonus tier emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing bonus tier fields expected by Dart models.
    private func bonusTierToDict(_ tier: TRBonusTier) -> [String: Any?] {
        [
            "tier_number": tier.tierNumber,
            "completes_needed": tier.completesNeeded,
            "reward_amount": tier.rewardAmount,
            "status": tier.status,
        ]
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts a TapResearch grant-boost response to the Dart payload shape.
    ///
    /// - Parameter response: Grant-boost response emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing grant-boost response fields expected by Dart models.
    private func grantBoostResponseToDict(_ response: TRGrantBoostResponse) -> [String: Any?] {
        [
            "boost_tag": response.boostTag,
            "success": response.success,
            "error": response.error.map { errorToDict($0) },
        ]
    }

    /// ---------------------------------------------------------------------------------------------
    /// Converts TapResearch quick-question data to the Dart payload shape.
    ///
    /// - Parameter data: Quick-question payload emitted by the TapResearch SDK.
    /// - Returns: Dictionary containing quick-question fields expected by Dart models.
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
