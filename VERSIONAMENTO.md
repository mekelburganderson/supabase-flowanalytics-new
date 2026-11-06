# Versionamento do FlowAnalytics App New

Padrão de versões, branches, changelog, tags e releases para os três repositórios do FlowAnalytics. Vale para qualquer alteração enviada à `main`, por menor que seja: **cada envio aprovado gera uma nova versão e um release em cada repositório alterado.**

| Componente | Repositório | Hospedagem | Onde fica a versão |
|---|---|---|---|
| Web | `flowanalytics-app-new` | GitLab (`mekelburganderson-group`) | `version` do `package.json` (aparece no menu lateral e no login) |
| API | `api-flowanalytics` | GitLab (`mekelburganderson-group`) | `<Version>` de `src/FlowAnalytics.Api/FlowAnalytics.Api.csproj` (aparece no `/health`) |
| Supabase | `supabase-flowanalytics-new` | GitHub (`mekelburganderson`) | `CHANGELOG.md` e tag (não há arquivo de pacote) |

Cada repositório tem a **sua própria versão**. Elas não andam juntas: a Web pode estar na 1.5.0 enquanto a API está na 1.5.2.

---

## 1. Formato da versão: `MAJOR.MINOR.PATCH`

Seguimos o [Versionamento Semântico](https://semver.org/lang/pt-BR/). A tag leva o prefixo `v` (`v1.5.2`); o `package.json`, o `.csproj` e o CHANGELOG não levam (`1.5.2`).

| Parte | Quando sobe | Zera |
|---|---|---|
| **MAJOR** | Mudança que quebra quem usa: contrato da API removido ou alterado sem compatibilidade, migration destrutiva, fluxo da Web refeito a ponto de mudar como o usuário trabalha. | MINOR e PATCH |
| **MINOR** | Funcionalidade nova que não quebra nada: endpoint novo, campo novo na resposta, tela ou botão novo, nova etapa de sincronização, tabela/view nova. | PATCH |
| **PATCH** | Correção, ajuste de texto, layout, configuração, desempenho ou refatoração sem mudança de comportamento para o usuário. | — |

Exemplos tirados do próprio histórico:

- API 1.4.0: nova análise com IA (`POST .../visao-geral/ia`) → **MINOR**.
- API 1.4.1: secret `OpenAI__ApiKey` não chegava ao container → **PATCH**.
- Web 1.3.1: botão "Analisar com IA" renomeado para "Analisar" → **PATCH**.
- Web 1.5.0: botão Exportar PDF → **MINOR**.

Na dúvida entre MINOR e PATCH: se o usuário (ou quem consome a API) ganha algo que não tinha antes, é MINOR.

### Versão da rota da API ≠ versão do release

O `v1` em `/api/flow-analytics/v1/...` é a versão do **contrato** e só muda quando um endpoint quebra compatibilidade (ver "Versões" no README da API). O release da API pode ir de 1.0.0 a 1.99.0 sem a rota sair de `v1`. Uma nova versão de rota (`v2`) normalmente acompanha um MAJOR do release.

### Regras para o Supabase

| Mudança | Versão |
|---|---|
| Migration nova que só acrescenta (tabela, coluna anulável, view, índice, função) | MINOR |
| Correção de migration, policy, grant, comentário ou ajuste no `config.toml` | PATCH |
| Migration que remove ou renomeia tabela/coluna, muda tipo ou exige ajuste na API | MAJOR |

Migration já aplicada em produção não é editada: a correção vai numa migration nova. O nome segue `AAAAMMDDhhmmss_descricao_em_snake_case.sql`.

---

## 2. Branches

| Branch | Uso | Exemplo |
|---|---|---|
| `main` | O que está (ou vai) em produção. Push na `main` da API dispara o deploy no Cloudflare. | — |
| `feature/<descricao>` | Funcionalidade nova (vira MINOR) | `feature/exportar-pdf-analise` |
| `fix/<descricao>` | Correção ou ajuste (vira PATCH) | `fix/openai-secret-worker` |

- Descrição em português, minúsculas, com hífen, sem acento.
- Sempre `feature/` (não `feat/`) para manter o mesmo prefixo nos três repositórios.
- Quando a mesma demanda mexe em mais de um repositório, use o **mesmo nome de branch** em todos (ex.: `feature/tasks-de-issues` na API e no Supabase).
- A branch nasce da `main` atualizada e volta para ela por merge (merge request no GitLab, pull request no GitHub ou merge local). Depois do merge, pode ser apagada.

---

## 3. Commits

- Mensagem em português, no imperativo ou descrevendo o resultado, começando pela área afetada:
  `Análise com IA: botão Exportar PDF com layout formatado (1.5.0)`
- O commit que fecha a versão leva o número entre parênteses no fim, como acima.
- Um commit por mudança lógica; não misture correção e funcionalidade sem relação.

---

## 4. CHANGELOG.md

Cada repositório tem um `CHANGELOG.md` na raiz, com a versão mais nova no topo:

```markdown
# Changelog

Versões no formato major.minor.patch. Cada versão lançada ganha uma tag `vX.Y.Z` e um release no GitLab.

## [1.6.0] - em desenvolvimento

### Adicionado
- Tela: o que o usuário passa a conseguir fazer.

### Alterado
- O que mudou de comportamento ou de texto (e como era antes).

### Corrigido
- O problema, a causa quando ajuda, e o que muda agora.

### Removido
- O que saiu e o que usar no lugar.
```

- Seções na ordem **Adicionado, Alterado, Corrigido, Removido**; inclua só as que tiverem itens.
- Enquanto a versão está sendo feita, a data é `em desenvolvimento`. No release, troque pela data (`AAAA-MM-DD`).
- Escreva para quem usa o sistema: tela e comportamento na Web, endpoint e contrato na API, tabela e migration no Supabase.
- Quando a mudança depende de outro repositório, diga qual versão: "Usa a api-flowanalytics 1.1.0", "Banco: migration `20261027120000_create_gitlab_issue_tasks`, no repositório supabase-flowanalytics-new".
- O texto do release é o trecho da versão no CHANGELOG.

---

## 5. Tags e releases

- Tag **anotada**, no commit da `main` que fecha a versão: `git tag -a vX.Y.Z -m "Versão X.Y.Z"`.
- Tag publicada não é movida nem apagada. Se saiu errado, lance a próxima versão PATCH.
- Release criado a partir da tag, com o título `vX.Y.Z` e a descrição copiada do CHANGELOG:
  - GitLab (Web e API): Deploy > Releases > New release, ou `glab release create vX.Y.Z --notes-file notas.md`.
  - GitHub (Supabase): Releases > Draft a new release, ou `gh release create vX.Y.Z --notes-file notas.md`.

---

## 6. Passo a passo de um release

1. Crie a branch (`feature/...` ou `fix/...`) a partir da `main` atualizada.
2. Faça a alteração e acrescente a entrada no CHANGELOG com a data `em desenvolvimento`.
3. Defina a versão (seção 1) e atualize:
   - Web: `npm version X.Y.Z --no-git-tag-version` (atualiza `package.json` e `package-lock.json`).
   - API: `<Version>X.Y.Z</Version>` no `.csproj`.
   - Supabase: só o CHANGELOG.
4. Teste localmente (Web: `npm run lint` e `npm run build`; API: `dotnet build`; Supabase: `supabase db reset` ou aplicar a migration no ambiente local).
5. Troque `em desenvolvimento` pela data do dia e faça o commit com a versão no fim da mensagem.
6. Merge na `main`.
7. **Confirmação:** antes do push, apresente o resumo das alterações e os repositórios envolvidos e aguarde a aprovação.
8. Push da `main` e da tag: `git push origin main` e `git push origin vX.Y.Z`.
9. Crie o release no GitLab ou GitHub (seção 5).

---

## 7. Demandas que envolvem mais de um repositório

Cada repositório alterado ganha a sua versão, a sua tag e o seu release. Publique nesta ordem, para nunca existir código esperando algo que ainda não está no ar:

1. **Supabase**: migration aplicada no banco e release publicado.
2. **API**: release que usa a migration (o CHANGELOG cita o nome da migration).
3. **Web**: release que usa a API (o CHANGELOG cita a versão da API).

Se só a API mudar, só a API ganha versão. Um repositório sem alteração não ganha release.

---

## 8. Situação atual (6 de novembro de 2026)

| Repositório | Versão atual | Tags existentes | O que falta |
|---|---|---|---|
| Web | 1.5.0 | v1.1.0 a v1.5.0 | Não há tag `v1.0.0` (o histórico começa na 1.1.0). Pode ficar assim. |
| API | 1.5.2 | v1.0.0 a v1.5.2 | Nada; já segue este padrão. |
| Supabase | sem versão | nenhuma | Criar `CHANGELOG.md`, lançar **v1.0.0** com as migrations atuais (até `20261027120000_create_gitlab_issue_tasks`) e publicar o release no GitHub. |

---

## Checklist rápido

- [ ] Branch `feature/` ou `fix/` com nome em português
- [ ] Versão definida pela regra MAJOR / MINOR / PATCH
- [ ] `package.json` ou `.csproj` atualizado (Web e API)
- [ ] Entrada no CHANGELOG com data, nas seções certas e citando dependências
- [ ] Build e testes locais passando
- [ ] Resumo apresentado e push aprovado
- [ ] Push da `main` e da tag `vX.Y.Z`
- [ ] Release criado com o texto do CHANGELOG
- [ ] Ordem Supabase → API → Web quando houver mais de um repositório
