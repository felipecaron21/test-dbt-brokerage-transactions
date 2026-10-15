# Brokerage Transactions — dbt

Projeto dbt que transforma dados brutos de transações e cadastro de clientes de uma corretora em modelos analíticos testados e documentados, organizados em staging, intermediate e marts.

Roda localmente com DuckDB. Não precisa de servidor, conta ou credencial.

---

## Como rodar

**Pré-requisitos:** Python 3.10+ (testado com 3.13) e Git.

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd test-dbt-brokerage-transactions

# 2. Criar e ativar o ambiente virtual
python -m venv .venv
source .venv/bin/activate          # macOS/Linux
# .venv\Scripts\Activate.ps1       # Windows (PowerShell)

# 3. Instalar as dependências
pip install -r requirements.txt

# 4. Rodar o projeto
dbt seed
dbt run
dbt test
```

O `profiles.yml` já está na raiz do projeto, e o dbt o encontra automaticamente. O banco é criado em `brokerage.duckdb` na primeira execução.

### Resultado esperado

| Comando | Resultado |
|---|---|
| `dbt seed` | 2 seeds carregados (27 clientes, 100 transações) |
| `dbt run` | 6 modelos criados |
| `dbt test` | `PASS=65 WARN=7 ERROR=0` |

Os **7 warnings são intencionais**. Eles sinalizam os problemas de qualidade presentes nos dados de origem, explicados na seção abaixo. O comando termina com sucesso (exit code 0).

---

## Estrutura

```
seeds/
  transactions.csv              # dado bruto de transações
  clients.csv                   # dado bruto de clientes
  _seeds.yml                    # documentação e testes de qualidade da origem
models/
  staging/
    stg_transactions.sql        # limpeza, tipagem e filtro de registros inválidos
    stg_clients.sql             # limpeza, tipagem e deduplicação
  intermediate/
    int_transactions.sql        # join com clientes e regras de negócio
  marts/
    fact_transactions.sql       # tabela fato de transações (incremental)
    dim_clients.sql             # dimensão de clientes
    mart_client_portfolio.sql   # posição líquida por cliente e ativo
macros/
  clean_string.sql              # padronização de colunas de texto
tests/
  assert_no_negative_position.sql   # teste singular de posição negativa
  generic/
    positive_value.sql              # teste genérico de valor positivo
    unique_combination_of_columns.sql   # teste genérico de chave composta
```

| Camada | Materialização | Papel |
|---|---|---|
| seeds | tabela | dado bruto, preservado sem alteração |
| staging | view | limpeza, tipagem e filtro, uma fonte por modelo |
| intermediate | view | joins e regras de negócio |
| marts | table / incremental | modelos de consumo |

---

## Qualidade de dados

Os testes estão em duas frentes:

- **Testes nos seeds** expõem os problemas da origem, com severidade `warn`.
- **Testes do staging em diante** garantem que o pipeline tratou os problemas, com severidade `error`.

A severidade `warn` nos problemas da origem permite que o `dbt test` detecte e reporte os problemas e, ao mesmo tempo, termine com sucesso. Um problema na origem gera aviso para triagem. Um problema no pipeline interrompe a execução.

Com `store_failures` ativado, cada teste que falha grava as linhas encontradas no schema `main_dbt_test__audit`, para consulta.

### Problemas encontrados

| Problema | Registro | Teste que sinaliza | Tratamento |
|---|---|---|---|
| Transação sem cliente | T021 | `not_null` | removida no staging |
| Quantidade negativa em compra | T037 | `positive_value` | removida no staging |
| Cliente duplicado (cópia idêntica) | C1 | `unique` | deduplicado no staging |
| Cliente duplicado sem cidade | C6 | `unique`, `not_null` | deduplicado no staging, mantendo o registro completo |
| Transações idênticas com IDs diferentes | T035, T036 | `unique_combination_of_columns` | mantidas e sinalizadas, sem evidência de que sejam erro |
| Posição líquida negativa | 6 posições | `assert_no_negative_position` | sinalizada no mart |

### Posições negativas

O teste singular encontra 6 posições com quantidade líquida negativa:

- **C5 em BBDC4 (−400):** comprou 200 e vendeu 600.
- **C1 BBDC4, C3 WEGE3, C6 ITUB4, C7 WEGE3, C8 VALE3:** vendas sem nenhuma compra na janela dos dados, o que pode indicar custódia anterior a janeiro de 2024.

Cada transação desses casos é válida individualmente. A inconsistência só aparece na soma, por isso ela é sinalizada e não filtrada.

O teste verifica apenas a quantidade. Valor líquido negativo não indica erro: acontece quando o cliente vende parte da posição com lucro.

---

## Detalhes de implementação

**Posição líquida.** O `int_transactions` calcula `signed_quantity` e `signed_amount`, positivos em compra e negativos em venda. O `mart_client_portfolio` apenas soma esses valores por cliente e ativo.

**Incremental.** A `fact_transactions` usa `transaction_date` como controle, com estratégia `delete+insert` e `unique_key = transaction_id`. A carga reprocessa a partir da maior data já carregada (`>=`), cobrindo transações que chegam depois no mesmo dia, sem duplicar linhas. Para reconstruir a tabela inteira:

```bash
dbt run --select fact_transactions --full-refresh
```

**Macro.** A `clean_string` centraliza a limpeza de texto usada nos dois modelos de staging: remove espaços, converte string vazia em `NULL` e, opcionalmente, converte para maiúsculas.

**Join.** O `int_transactions` usa `LEFT JOIN` com teste `not_null` no nome do cliente. Uma transação de cliente inexistente quebra o pipeline em vez de ser descartada em silêncio.

---

## Comandos úteis

```bash
# Rodar e testar em ordem de dependência
dbt build

# Ver as posições negativas encontradas
dbt show --inline "select * from main_dbt_test__audit.assert_no_negative_position" --limit 10

# Gerar e abrir a documentação
dbt docs generate
dbt docs serve
```