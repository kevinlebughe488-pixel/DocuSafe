# Règles de R8 (l'optimiseur qui allège la version compilée) propres à DocSafe.
# Les paquets fournissent leurs propres règles ; celles-ci comblent un manque.

# ML Kit (scanner) : ses « registrars » de composants sont créés par réflexion
# au démarrage (ComponentDiscovery). En mode complet, R8 retire leur
# constructeur sans paramètre : ML Kit ne s'initialise pas et le scanner passe
# directement en mode de secours. Constaté sur l'émulateur le 15/11/2026 :
# « Could not instantiate com.google.mlkit.common.internal.CommonComponentRegistrar ».
# Contrôlé à chaque compilation par tool/smoke_test.py.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
-keep class com.google.mlkit.**Registrar {
    <init>();
}
