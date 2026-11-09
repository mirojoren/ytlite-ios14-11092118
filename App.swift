import UIKit
import WebKit

private let kHomeURL = "https://m.youtube.com/"
private let kMobileUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1 Mobile/15E148 Safari/604.1"
private let kDesktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        win.backgroundColor = .black
        let nav = UINavigationController(rootViewController: RootViewController())
        nav.navigationBar.barStyle = .black
        nav.navigationBar.isTranslucent = false
        win.rootViewController = nav
        win.makeKeyAndVisible()
        window = win
        return true
    }
}

final class RootViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private var web: WKWebView!
    private var progress: UIProgressView!
    private var progressTimer: Timer?
    private var desktop = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "YT Lite"
        view.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()

        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.customUserAgent = kMobileUA
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)

        progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = UIColor(red: 1.0, green: 0.0, blue: 0.2, alpha: 1.0)
        progress.trackTintColor = .clear
        view.addSubview(progress)

        NSLayoutConstraint.activate([
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            web.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            web.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progress.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(reloadPage), for: .valueChanged)
        web.scrollView.refreshControl = rc

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "<", style: .plain, target: self, action: #selector(goBack)),
            UIBarButtonItem(title: "首页", style: .plain, target: self, action: #selector(goHome))
        ]
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "刷新", style: .plain, target: self, action: #selector(reloadPage)),
            UIBarButtonItem(title: "粘贴", style: .plain, target: self, action: #selector(openFromPasteboard)),
            UIBarButtonItem(title: "UA", style: .plain, target: self, action: #selector(toggleUA))
        ]

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let s = self else { return }
            let p = Float(s.web.estimatedProgress)
            s.progress.setProgress(p, animated: p > s.progress.progress)
            s.progress.isHidden = (p >= 0.999 || p <= 0.001)
        }

        if let url = URL(string: kHomeURL) { load(url) }
    }

    deinit { progressTimer?.invalidate() }

    private func load(_ url: URL) {
        web.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    @objc private func goHome() {
        if let url = URL(string: kHomeURL) { load(url) }
    }

    @objc private func goBack() {
        if web.canGoBack { web.goBack() } else { goHome() }
    }

    @objc private func reloadPage() {
        web.scrollView.refreshControl?.endRefreshing()
        web.reload()
    }

    @objc private func toggleUA() {
        desktop = !desktop
        web.customUserAgent = desktop ? kDesktopUA : kMobileUA
        web.reload()
    }

    @objc private func openFromPasteboard() {
        guard let text = UIPasteboard.general.string,
              let range = text.range(of: "https?://[^\\s]+", options: .regularExpression),
              let url = URL(string: String(text[range])) else { return }
        load(url)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow)
            return
        }
        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" || scheme == "blob" {
            if url.host?.lowercased() == "apps.apple.com" {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progress.isHidden = false
        progress.setProgress(0.05, animated: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress.setProgress(1.0, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.progress.isHidden = true
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let msg = error.localizedDescription
        let html = "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>body{background:#111;color:#eee;font:16px -apple-system;text-align:center;padding:60px 24px}h2{color:#fff}button{background:#ff0033;color:#fff;border:0;border-radius:10px;padding:12px 26px;font-size:16px}</style></head><body><h2>页面加载失败</h2><p>" + msg + "</p><p>请检查设备网络后重试。</p><button onclick='location.reload()'>重试</button></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
