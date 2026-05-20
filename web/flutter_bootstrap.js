{{flutter_js}}
{{flutter_build_config}}

// Use Google's official CDN for CanvasKit — avoids shipping 32 MB of WASM in git.
// The engine revision is baked into buildConfig at compile time so this always
// resolves to the exact matching CanvasKit version.
(function () {
  var engineRev = (_flutter.buildConfig || {}).engineRevision;
  var canvasKitBaseUrl = engineRev
    ? 'https://www.gstatic.com/flutter-canvaskit/' + engineRev + '/'
    : undefined;

  _flutter.loader.load({
    config: canvasKitBaseUrl ? { canvasKitBaseUrl: canvasKitBaseUrl } : {},
  });
})();
