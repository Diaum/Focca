# Configuração do Supabase

## Variáveis e Keys Necessárias

O projeto usa o arquivo `Focca/Core/Auth/SupabaseConfig.swift` para armazenar as credenciais do Supabase.

### Variáveis Obrigatórias

```swift
struct SupabaseConfig {
    static let url = "https://seu-projeto.supabase.co"        // URL do projeto Supabase
    static let anonKey = "sua-chave-anon-public-aqui"        // Chave anon public do Supabase
}
```

### Como Obter as Credenciais

1. Acesse https://supabase.com e faça login
2. Vá em **Project Settings** → **API**
3. Copie:
   - **Project URL** → `url`
   - **anon public** key → `anonKey`

### Configuração

1. O arquivo `SupabaseConfig.swift` está no `.gitignore` e **não será commitado**
2. Use `SupabaseConfig.example.swift` como template
3. Copie o exemplo e preencha com suas credenciais reais

### Segurança

- A chave `anonKey` é pública por design e é protegida pelas políticas RLS do Supabase
- O arquivo `SupabaseConfig.swift` não deve ser commitado no Git
- As políticas RLS garantem que usuários só acessem seus próprios dados

