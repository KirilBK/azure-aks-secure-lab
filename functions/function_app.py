import logging
import os

import azure.functions as func
import pyodbc

app = func.FunctionApp()


def _connect() -> pyodbc.Connection:
    """Build a pyodbc connection from the Key Vault-referenced app setting.

    SQL_CONNECTION_STRING is delivered by the platform as a Key Vault
    reference resolved through the Function App's managed identity, so the
    password is never present in code or in plaintext configuration.
    """
    raw = os.environ["SQL_CONNECTION_STRING"]
    parts = {}
    for kv in raw.split(";"):
        if "=" not in kv:
            continue
        k, v = kv.split("=", 1)
        parts[k.strip().lower()] = v.strip()

    server = parts.get("server", "").replace("tcp:", "").split(",")[0]
    odbc = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={server},1433;Database={parts.get('database','')};"
        f"Uid={parts.get('user id','')};Pwd={parts.get('password','')};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    return pyodbc.connect(odbc)


def _insert(name: str, source: str) -> None:
    with _connect() as cnx:
        cnx.cursor().execute(
            "INSERT INTO dbo.SubmittedItems (SubmittedName, Source) VALUES (?, ?)",
            name, source,
        )
        cnx.commit()


# T503: Timer trigger every three minutes -> inserts SubmittedName=SCHEDULE.
@app.timer_trigger(schedule="0 */3 * * * *", arg_name="timer", run_on_startup=False)
def ExamTimerTrigger(timer: func.TimerRequest) -> None:
    _insert("SCHEDULE", "timer")
    logging.info("ExamTimerTrigger inserted SubmittedName=SCHEDULE")


# T504: HTTP trigger -> stores ?item=<value>, or NONE when called without it.
@app.route(route="ExamHTTPTrigger", auth_level=func.AuthLevel.FUNCTION)
def ExamHTTPTrigger(req: func.HttpRequest) -> func.HttpResponse:
    item = req.params.get("item")
    if not item:
        try:
            item = (req.get_json() or {}).get("item")
        except ValueError:
            item = None
    name = item if item else "NONE"
    _insert(name, "http")
    logging.info("ExamHTTPTrigger inserted SubmittedName=%s", name)
    return func.HttpResponse(f"Stored SubmittedName={name}", status_code=200)
