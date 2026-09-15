{{flutter_js}}
{{flutter_build_config}}

// Démarrage explicite de l'application Flutter.
// Sans ce callback, l'engine est téléchargé mais `runApp()` n'est jamais
// appelé : le navigateur reste bloqué sur le fond bleu de index.html.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: "{{flutter_service_worker_version}}",
  },
  onEntrypointLoaded: function (engineInitializer) {
    engineInitializer.initializeEngine().then(function (appRunner) {
      appRunner.runApp();
    });
  },
});
