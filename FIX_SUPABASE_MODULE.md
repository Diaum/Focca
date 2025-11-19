# Como Resolver o Erro "Unable to find module dependency: 'Supabase'"

O pacote Supabase já está adicionado ao projeto, mas precisa ser vinculado ao target. Siga estes passos:

## Solução Rápida

1. **No Xcode, abra o projeto**
2. **Selecione o projeto** no Navigator (ícone azul no topo)
3. **Selecione o target "Focca"** (não o projeto, mas o target)
4. **Vá na aba "General"** (ou "Build Phases")
5. **Role até "Frameworks, Libraries, and Embedded Content"**
6. **Clique no botão "+"**
7. **Procure por "Supabase"** na lista
8. **Selecione e adicione**

## Alternativa: Via Package Dependencies

1. **No Xcode, selecione o projeto** no Navigator
2. **Vá na aba "Package Dependencies"**
3. **Verifique se "supabase-swift" está listado**
4. **Se não estiver, clique em "+" e adicione:**
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Up to Next Major Version (2.5.1 ou superior)

## Se ainda não funcionar

1. **Limpe o build:**
   - Product → Clean Build Folder (Shift + Cmd + K)

2. **Resolva os pacotes:**
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions

3. **Feche e reabra o Xcode**

4. **Tente compilar novamente**

## Verificação

Após seguir os passos, o import deve funcionar:
```swift
import Supabase
```

Se ainda der erro, verifique se o pacote está sendo baixado corretamente na aba "Package Dependencies".

