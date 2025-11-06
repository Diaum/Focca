# Configuração do Deploy Automático para TestFlight

Este projeto está configurado para fazer deploy automático para o TestFlight sempre que houver push na branch `main`.

## 📋 Pré-requisitos

1. **App Store Connect API Key**
   - Acesse [App Store Connect](https://appstoreconnect.apple.com)
   - Vá em **Users and Access** > **Keys** > **App Store Connect API**
   - Crie uma nova chave com permissões de **App Manager** ou **Admin**
   - Baixe o arquivo `.p8` (você só pode baixar uma vez!)

2. **GitHub Secrets**
   - Acesse o repositório no GitHub
   - Vá em **Settings** > **Secrets and variables** > **Actions**
   - Adicione os seguintes secrets:

## 🔐 Configuração dos GitHub Secrets

Adicione os seguintes secrets no GitHub:

| Secret Name | Valor | Descrição |
|------------|-------|-----------|
| `APP_STORE_CONNECT_API_KEY_ID` | `ABC123XYZ` | O Key ID da sua API Key (ex: ABC123XYZ) |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | `12345678-1234-1234-1234-123456789012` | O Issuer ID da sua conta |
| `APP_STORE_CONNECT_API_KEY` | Conteúdo do arquivo `.p8` | O conteúdo completo do arquivo `.p8` baixado |

### Como obter os valores:

1. **Key ID**: Aparece na lista de keys no App Store Connect (ex: `ABC123XYZ`)
2. **Issuer ID**: Aparece no topo da página de Keys (ex: `12345678-1234-1234-1234-123456789012`)
3. **API Key**: Abra o arquivo `.p8` baixado em um editor de texto e copie TODO o conteúdo (incluindo `-----BEGIN PRIVATE KEY-----` e `-----END PRIVATE KEY-----`)

## 📁 Estrutura de Arquivos Necessária

Certifique-se de ter os seguintes arquivos no projeto:

```
.
├── .github/
│   └── workflows/
│       └── deploy_testflight.yml  ✅ Já criado
├── fastlane/
│   └── Fastfile                   ⚠️ Você precisa criar (veja fastlane/Fastfile.example)
├── Gemfile                        ⚠️ Você precisa criar (veja Gemfile.example)
└── Focca.xcodeproj               ✅ Já existe
```

## 🚀 Como Funciona

1. **Push na branch `main`** → GitHub Action é acionada automaticamente
2. **Checkout** → Código é baixado
3. **Setup Ruby** → Ruby e Bundler são configurados
4. **Install dependencies** → `bundle install` instala as gems do Fastlane
5. **Build and Upload** → `fastlane beta` builda e envia para TestFlight

## 📝 Próximos Passos

1. **Criar o Fastfile**:
   ```bash
   mkdir -p fastlane
   cp fastlane/Fastfile.example fastlane/Fastfile
   # Edite o Fastfile conforme suas necessidades
   ```

2. **Criar o Gemfile**:
   ```bash
   cp Gemfile.example Gemfile
   bundle install
   ```

3. **Configurar os GitHub Secrets** (veja seção acima)

4. **Testar localmente** (opcional):
   ```bash
   bundle exec fastlane beta
   ```

5. **Fazer push na branch main**:
   ```bash
   git push origin main
   ```

## 🔍 Verificar o Status do Deploy

- Acesse **Actions** no GitHub para ver o progresso do deploy
- O build aparecerá no TestFlight em alguns minutos após o sucesso da Action

## ⚠️ Troubleshooting

- **Erro de autenticação**: Verifique se os secrets estão configurados corretamente
- **Erro de build**: Verifique se o `Fastfile` está configurado corretamente para seu projeto
- **Erro de certificado**: Certifique-se de que os certificados estão configurados no Xcode ou via Match

