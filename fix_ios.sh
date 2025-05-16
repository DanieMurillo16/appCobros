#!/bin/bash

echo "🚀 Cerrando Xcode si está abierto..."
killall Xcode

echo "🧹 Limpiando proyecto Flutter..."
flutter clean

echo "📦 Instalando dependencias de Flutter..."
flutter pub get

echo "🗑️ Borrando Pods, Podfile.lock y Runner.xcworkspace..."
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf Runner.xcworkspace

echo "🍎 Instalando Pods..."
pod install

echo "✅ Todo listo! Abriendo proyecto en Runner.xcworkspace..."
open Runner.xcworkspace