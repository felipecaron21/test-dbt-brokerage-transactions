# Brokerage Transactions dbt

Projeto dbt com DuckDB para o teste técnico de Engenharia de Dados.

## Como rodar

Requisito: Python 3.10 ou superior.

```bash
git clone <url-do-repositorio>
cd test-dbt-brokerage-transactions

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

dbt seed
dbt run
dbt test
```

No Windows, ative o ambiente com `.venv\Scripts\Activate.ps1`.

## Resultado esperado

`dbt test` termina com `PASS=65 WARN=7 ERROR=0`.

Os 7 avisos são os problemas de qualidade dos dados de origem, sinalizados pelos testes com severidade `warn`.
