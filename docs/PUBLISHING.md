# Guia de Preparação e Publicação — PetCare

## 1. Identificação do Aplicativo

- **Nome do aplicativo:** PetCare
- **Identificador (Application ID / Bundle ID):** `com.petcare.app`
- **Versão:** `1.0.0+1` (`versionName: 1.0.0`, `versionCode: 1`)
- **Plataformas de destino:** Android e iOS

## 2. Permissões Utilizadas

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.POST_NOTIFICATIONS`: exibir lembretes locais de medicamentos, consultas e vacinas (Android 13+).
- `android.permission.RECEIVE_BOOT_COMPLETED`: reagendar notificações após reinicialização do aparelho.
- `android.permission.VIBRATE`: vibração nos alertas locais.
- Câmera/Galeria (via `image_picker` com Photo Picker do Android): selecionar foto do pet sem exigir permissão ampla de armazenamento.

### iOS (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription`: tirar foto do animal de estimação.
- `NSPhotoLibraryUsageDescription`: escolher foto do animal na galeria.
- Notificações locais: solicitadas em tempo de execução via `UNUserNotificationCenter`.

## 3. Política de Privacidade

O texto completo da Política de Privacidade está integrado no aplicativo em **Perfil → Política de Privacidade** (`lib/features/profile/privacy_policy_screen.dart`).
Principais pontos:
- Todos os dados são armazenados localmente no dispositivo (SQLite).
- Não há envio de dados para servidores externos, anúncios ou rastreamento.
- O aplicativo não realiza diagnósticos clínicos nem prescreve medicamentos.

## 4. Ícones do Aplicativo

- Ícone mestre: `assets/icon/app_icon.png`
- Configuração em `pubspec.yaml` via `flutter_launcher_icons`.
- Para regenerar os ícones Android e iOS após alterações:
  ```bash
  dart run flutter_launcher_icons
  ```

## 5. Geração do Android App Bundle (`.aab`) — Google Play Store

1. Gere uma chave de assinatura (`upload-keystore.jks`):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crie `android/key.properties` (não versionar no Git):
   ```properties
   storePassword=<sua-senha>
   keyPassword=<sua-senha>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Configure `signingConfigs.release` em `android/app/build.gradle.kts` para ler `key.properties`.
4. Gere o App Bundle assinado:
   ```bash
   flutter build appbundle --release
   ```
   O arquivo será gerado em `build/app/outputs/bundle/release/app-release.aab`.
5. Envie o `.aab` no Google Play Console, preencha a ficha da loja, classificação indicativa e link da Política de Privacidade.

## 6. Geração do pacote iOS (`.ipa`) — Apple App Store

> **Limitação de ambiente:** A compilação, assinatura e geração de `.ipa` para iOS exigem obrigatoriamente um computador com **macOS** e **Xcode** instalados, além de uma conta no **Apple Developer Program**. Não é possível compilar ou assinar builds iOS diretamente no Windows.

Em um ambiente macOS com Xcode:
1. Abra `ios/Runner.xcworkspace` no Xcode e configure:
   - **Bundle Identifier:** `com.petcare.app`
   - **Signing & Capabilities:** selecione sua equipe (*Team*) e ative *Automatically manage signing*.
2. Execute:
   ```bash
   flutter build ipa --release
   ```
   O arquivo `.ipa` será gerado em `build/ios/ipa/petcare.ipa`.
3. Envie para a App Store Connect usando o **Transporter** ou `xcrun altool` / Xcode Organizer.

