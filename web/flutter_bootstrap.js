{{flutter_js}}
{{flutter_build_config}}

// Forçar o carregamento do bundle JS com versão para burlar cache antigo do navegador
if (_flutter && _flutter.buildConfig && _flutter.buildConfig.builds) {
  for (var i = 0; i < _flutter.buildConfig.builds.length; i++) {
    var b = _flutter.buildConfig.builds[i];
    if (b.mainJsPath) {
      b.mainJsPath = b.mainJsPath + "?v=20260904_v7";
    }
  }
}

// Desativa completamente o Service Worker do Flutter
_flutter.loader.load({
  serviceWorkerSettings: null
});
