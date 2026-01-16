import 'dart:html' as html;

String? getCurrentHostname() {
  return html.window.location.hostname;
}

void openUrlInNewWindow(String url) {
  html.window.open(url, '_blank');
}
