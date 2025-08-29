# Configuração do Netlify para Flutter Finance App

Este guia detalha como configurar e fazer deploy da aplicação Flutter no Netlify com variáveis de ambiente seguras.

## 📋 Pré-requisitos

- Conta no [Netlify](https://netlify.com)
- Conta no [Supabase](https://supabase.com)
- Repositório no GitHub com o código da aplicação

## 🔧 Configuração do Supabase

1. **Acesse seu projeto no Supabase**
2. **Vá para Settings > API**
3. **Copie as seguintes informações:**
   - Project URL (ex: `https://abc123.supabase.co`)
   - anon/public key (chave longa começando com `eyJ...`)

## 🚀 Deploy no Netlify

### Passo 1: Conectar Repositório

1. **Login no Netlify**
2. **Clique em "New site from Git"**
3. **Conecte com GitHub** e selecione seu repositório
4. **Configure as opções de build:**
   - Build command: `flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY`
   - Publish directory: `build/web`

### Passo 2: Configurar Variáveis de Ambiente

1. **No dashboard do Netlify, vá para:**
   `Site settings > Environment variables`

2. **Adicione as seguintes variáveis:**

   | Key | Value |
   |-----|-------|
   | `SUPABASE_URL` | `https://seu-projeto.supabase.co` |
   | `SUPABASE_ANON_KEY` | `sua-chave-anon-completa` |

3. **Clique em "Save"**

### Passo 3: Configurar Build Settings

O arquivo `netlify.toml` já está configurado com:

```toml
[build]
  publish = "build/web"
  command = "flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

[build.environment]
  FLUTTER_VERSION = "3.16.0"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Passo 4: Deploy

1. **Faça push do código para GitHub**
2. **O Netlify fará o build automaticamente**
3. **Aguarde o deploy completar**
4. **Acesse a URL fornecida pelo Netlify**

## 🔒 Segurança

### ✅ O que está protegido:
- Credenciais do Supabase não estão no código
- Variáveis de ambiente são injetadas apenas no build
- Arquivos `.env*` estão no `.gitignore`

### ⚠️ Importante:
- Nunca commite arquivos `.env` com credenciais reais
- Use sempre variáveis de ambiente no Netlify
- A chave anônima do Supabase é segura para uso público

## 🐛 Troubleshooting

### Build falha com erro de variáveis de ambiente:
```
Exception: SUPABASE_URL environment variable not set
```

**Solução:**
1. Verifique se as variáveis estão configuradas no Netlify
2. Confirme que os nomes estão corretos (case-sensitive)
3. Refaça o deploy após configurar

### App carrega mas não conecta ao Supabase:
1. Verifique se as credenciais estão corretas
2. Confirme se o projeto Supabase está ativo
3. Verifique o console do navegador para erros

### Redirecionamento não funciona:
- O arquivo `netlify.toml` deve estar na raiz do projeto
- Confirme se a configuração de redirects está correta

## 📱 Testando o Deploy

1. **Acesse a URL do Netlify**
2. **Teste o login/cadastro**
3. **Verifique se as transações são salvas**
4. **Confirme se todos os recursos funcionam**

## 🔄 Atualizações

Para atualizar a aplicação:
1. Faça as alterações no código
2. Commit e push para GitHub
3. O Netlify fará o redeploy automaticamente

## 📞 Suporte

Se encontrar problemas:
1. Verifique os logs de build no Netlify
2. Confirme as variáveis de ambiente
3. Teste localmente primeiro com as mesmas variáveis
