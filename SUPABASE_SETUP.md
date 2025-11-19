# Checklist de Configuração do Supabase

## 1. Criar Projeto no Supabase
- [ ] Acessar https://supabase.com
- [ ] Criar nova conta ou fazer login
- [ ] Clicar em "New Project"
- [ ] Preencher:
  - Nome do projeto: `focca` (ou seu nome preferido)
  - Database Password: (anotar em local seguro)
  - Region: escolher mais próxima
- [ ] Aguardar criação do projeto (~2 minutos)

## 2. Habilitar Auth OTP por E-mail
- [ ] No menu lateral, ir em **Authentication** → **Providers**
- [ ] Encontrar **Email** provider
- [ ] Habilitar o toggle "Enable Email provider"
- [ ] Em **Email Auth**, verificar que está habilitado
- [ ] Opcional: configurar "Confirm email" (pode deixar desabilitado para OTP)

## 3. Obter Credenciais (supabaseURL e anonKey)
- [ ] No menu lateral, ir em **Project Settings** → **API**
- [ ] Copiar **Project URL** (será o `supabaseURL`)
- [ ] Copiar **anon public** key (será o `anonKey`)
- [ ] Guardar essas credenciais para usar no código Swift

## 4. Configurar Templates de E-mail (Opcional)
- [ ] No menu lateral, ir em **Authentication** → **Email Templates**
- [ ] Editar template **Magic Link** (ou criar template customizado)
- [ ] O template padrão já funciona para OTP
- [ ] Variáveis disponíveis: `{{ .Token }}` (código OTP), `{{ .Email }}`
- [ ] Exemplo de template:
  ```
  Seu código de verificação Focca: {{ .Token }}
  
  Este código expira em 1 hora.
  ```

## 5. Criar Tabela de Sessões
- [ ] No menu lateral, ir em **SQL Editor**
- [ ] Executar o seguinte SQL:

```sql
CREATE TABLE focus_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  duration_minutes INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_focus_sessions_user_id ON focus_sessions(user_id);
CREATE INDEX idx_focus_sessions_date ON focus_sessions(date);
```

## 6. Configurar Row Level Security (RLS)
- [ ] No menu lateral, ir em **Authentication** → **Policies**
- [ ] Selecionar tabela `focus_sessions`
- [ ] Criar política para INSERT:
  - Policy name: `Users can insert their own sessions`
  - Allowed operation: `INSERT`
  - Target roles: `authenticated`
  - USING expression: `auth.uid() = user_id`
  - WITH CHECK expression: `auth.uid() = user_id`

- [ ] Criar política para SELECT:
  - Policy name: `Users can view their own sessions`
  - Allowed operation: `SELECT`
  - Target roles: `authenticated`
  - USING expression: `auth.uid() = user_id`

- [ ] Criar política para UPDATE (opcional, se necessário):
  - Policy name: `Users can update their own sessions`
  - Allowed operation: `UPDATE`
  - Target roles: `authenticated`
  - USING expression: `auth.uid() = user_id`
  - WITH CHECK expression: `auth.uid() = user_id`

- [ ] Criar política para DELETE (opcional, se necessário):
  - Policy name: `Users can delete their own sessions`
  - Allowed operation: `DELETE`
  - Target roles: `authenticated`
  - USING expression: `auth.uid() = user_id`

## 7. Verificar Configuração
- [ ] Testar autenticação OTP no Supabase Dashboard:
  - Ir em **Authentication** → **Users**
  - Tentar criar usuário manualmente (opcional, para teste)
- [ ] Verificar que a tabela `focus_sessions` foi criada:
  - Ir em **Table Editor** → verificar se `focus_sessions` aparece
- [ ] Verificar políticas RLS:
  - Ir em **Authentication** → **Policies**
  - Confirmar que as políticas estão ativas

## 8. Configurações Adicionais (Opcional)
- [ ] Configurar redirect URLs (se necessário):
  - **Authentication** → **URL Configuration**
  - Adicionar URL do app se usar deep linking
- [ ] Configurar rate limiting (recomendado):
  - **Project Settings** → **API** → **Rate Limiting**
  - Ajustar limites conforme necessário

## Notas Importantes
- Guarde as credenciais (`supabaseURL` e `anonKey`) em local seguro
- As políticas RLS são essenciais para segurança
- O código OTP expira em 1 hora por padrão (pode ser configurado)
- A tabela `focus_sessions` usa `ON DELETE CASCADE` para remover sessões quando usuário é deletado

