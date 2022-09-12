/*
 <samplecode>
     <abstract>
         WKWebView Testbed
     </abstract>
 </samplecode>
 */

import UIKit
import WebKit

class MyCustomSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        print("webView - start urlSchemeTask url: \(String(describing: urlSchemeTask.request.url?.absoluteString))")

        // We don't care about what happens inside here, this is not the point.
        // The issue is not related to loading from a HTTPS url in the custom URL scheme handler method,
        // but accessing a custom URL scheme from HTML loaded via HTTPS.
        let url = urlSchemeTask.request.url!
        let dataStr = ">>Response to " + url.absoluteString
        let data = dataStr.data(using: String.Encoding.utf8)!

        print(dataStr)

        urlSchemeTask.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Access-Control-Allow-Origin": "*", "Content-Type": "text/plain"])!)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        print("webView - stop urlSchemeTask: \(String(describing: urlSchemeTask.debugDescription))")
    }
}

class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    var webView: WKWebView!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let schemeHandler = MyCustomSchemeHandler()
        webConfiguration.setURLSchemeHandler(schemeHandler, forURLScheme: "o3h")

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "unityControl")

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlockingRules",
            encodedContentRuleList: "[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"make-https\"}}]")
        { contentRuleList, error in
            if let error = error {
                debugPrint(error)
                return
            }
            webConfiguration.userContentController.add(contentRuleList!)
        }
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // WORKS: Access o3h: from HTML loaded via file:///
//        let url = Bundle.main.url(forResource: "index", withExtension: "html")!
//        webView.loadFileURL(url, allowingReadAccessTo: url)

        // WORKS: Access o3h: from HTML loaded via http://
//        let url = URL(string: "http://oooh-tv.s3.us-east-2.amazonaws.com/modules/__temp/index.html")!
//        let request = URLRequest(url: url)
//        webView.load(request)

        // DOES NOT WORK: Access o3h: from HTML loaded via https://
        let url = URL(string: "https://oooh-tv.s3.us-east-2.amazonaws.com/modules/__temp/index.html")!
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "unityControl" {
            // ...
        }
    }
}

extension ViewController: WKNavigationDelegate {
    /** @abstract Decides whether to allow or cancel a navigation.
        @param webView The web view invoking the delegate method.
        @param navigationAction Descriptive information about the action triggering the navigation request.
        @param decisionHandler The decision handler to call to allow or cancel the navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
        @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("Request Headers: \(String(describing: navigationAction.request.allHTTPHeaderFields?.description))")
        print("Request URL: \(String(describing: navigationAction.request.url?.absoluteString))")
        decisionHandler(.allow)
    }

    /** @abstract Decides whether to allow or cancel a navigation after its
     response is known.
     @param webView The web view invoking the delegate method.
     @param navigationResponse Descriptive information about the navigation
     response.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     @discussion If you do not implement this method, the web view will allow the response, if the web view can show it.
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("Response: \(String(describing: navigationResponse.response.description))")
        print("Response URL: \(String(describing: navigationResponse.response.url?.absoluteString))")
        if let headers = navigationResponse.response as? HTTPURLResponse {
            let allHeaders = headers.allHeaderFields
            print("HTTP Response Headers: \(allHeaders.description)")
        }
        decisionHandler(.allow)
    }

    /** @abstract Invoked when a main frame navigation starts.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStartProvisionalNavigation navigation: \(navigation.debugDescription)")
    }

    /** @abstract Invoked when a server redirect is received for the main
     frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("didReceiveServerRedirectForProvisionalNavigation navigation: \(navigation.debugDescription)")
    }

    /** @abstract Invoked when an error occurs while starting to load data for
     the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation navigation: \(navigation.debugDescription) - error: \(error.localizedDescription)")
    }

    /** @abstract Invoked when content starts arriving for the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit navigation: \(navigation.debugDescription)")
    }

    /** @abstract Invoked when a main frame navigation completes.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish navigation: \(navigation.debugDescription)")
    }

    /** @abstract Invoked when an error occurs during a committed main frame
     navigation.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail navigation: \(navigation.debugDescription) - error: \(error.localizedDescription)")
    }

    /** @abstract Invoked when the web view needs to respond to an authentication challenge.
     @param webView The web view that received the authentication challenge.
     @param challenge The authentication challenge.
     @param completionHandler The completion handler you must invoke to respond to the challenge. The
     disposition argument is one of the constants of the enumerated type
     NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
     the credential argument is the credential to use, or nil to indicate continuing without a
     credential.
     @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
     */
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Received challenge (\(challenge.previousFailureCount))")
        print("For host: \(challenge.protectionSpace.host)")

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNegotiate {
            print("Negotiate authentication request received!")
            completionHandler(.performDefaultHandling, nil)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM {
            print("NTML authentication request received!")
            completionHandler(.performDefaultHandling, nil)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            print("Server Trust authentication request received!")
            completionHandler(.performDefaultHandling, nil)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            print("HTTPBasic authentication request received!")
            completionHandler(.performDefaultHandling, nil)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            print("Client Certificate authentication request received!")
            completionHandler(.performDefaultHandling, nil)
        } else {
            print("Unknwon authentication request received! \(challenge.protectionSpace.authenticationMethod)")
            completionHandler(.performDefaultHandling, nil)
        }
    }

    /** @abstract Invoked when the web view's web content process is terminated.
     @param webView The web view whose underlying web content process was terminated.
     */
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("webViewWebContentProcessDidTerminate: \(webView.debugDescription)")
    }
}
