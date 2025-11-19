# Configuração do Supabase no Projeto

## 1. Adicionar Pacote Supabase via SPM

1. No Xcode, vá em **File** → **Add Package Dependencies...**
2. Cole a URL: `https://github.com/supabase/supabase-swift`
3. Selecione a versão mais recente
4. Adicione o pacote ao target **Focca**

## 2. Adicionar Credenciais ao Info.plist

1. No Xcode, abra o arquivo `Info.plist` (ou adicione ao `Info.plist` se não existir)
2. Adicione as seguintes chaves:

```xml
<key>SUPABASE_URL</key>
<string>https://seu-projeto.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>sua-chave-anon-aqui</string>
```

**IMPORTANTE**: Substitua pelos valores reais do seu projeto Supabase:
- `SUPABASE_URL`: A URL do projeto (encontrada em Project Settings → API → Project URL)
- `SUPABASE_ANON_KEY`: A chave anon public (encontrada em Project Settings → API → anon public)

## 3. Alternativa: Criar arquivo de configuração

Se preferir não colocar as credenciais no Info.plist, você pode criar um arquivo `SupabaseConfig.swift`:

```swift
import Foundation

struct SupabaseConfig {
    static let url = "https://seu-projeto.supabase.co"
    static let anonKey = "sua-chave-anon-aqui"
}
```

E então atualizar o `SupabaseManager.swift` para usar:

```swift
private func setupClient() {
    let url = URL(string: SupabaseConfig.url)!
    client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
}
```

**NOTA**: Se usar este método, adicione `SupabaseConfig.swift` ao `.gitignore` para não commitar as credenciais.

## 4. Verificar Imports

Certifique-se de que o arquivo `SupabaseManager.swift` importa:

```swift
import Foundation
import Supabase
```

## 5. Testar

Após configurar, compile o projeto e teste o fluxo de login OTP.

