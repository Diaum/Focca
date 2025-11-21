# Configuração do Supabase

## Arquivos

- `SupabaseConfig.example.swift` - Template com credenciais de exemplo (pode ser commitado)
- `SupabaseConfig.swift` - Arquivo real com suas credenciais (NÃO será commitado)

## Como configurar

1. Copie o arquivo `SupabaseConfig.example.swift` para `SupabaseConfig.swift`
2. Substitua as credenciais de exemplo pelas suas credenciais reais:
   - `url`: URL do seu projeto Supabase
   - `anonKey`: Chave anon public do Supabase

## Importante

- O arquivo `SupabaseConfig.swift` está no `.gitignore` e **NÃO será commitado**
- Use `SupabaseConfig.example.swift` como referência
- Nunca commite credenciais reais no GitHub

