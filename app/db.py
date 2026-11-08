"""MySQL connector helpers for calling Section 2 procedures/functions."""

from __future__ import annotations

from contextlib import contextmanager
from typing import Any, Iterable, Optional

import mysql.connector
from mysql.connector import Error as MySQLError

from config import Config


def get_connection():
    return mysql.connector.connect(
        host=Config.MYSQL_HOST,
        port=Config.MYSQL_PORT,
        user=Config.MYSQL_USER,
        password=Config.MYSQL_PASSWORD,
        database=Config.MYSQL_DATABASE,
    )


@contextmanager
def db_cursor(dictionary: bool = True):
    conn = get_connection()
    cursor = conn.cursor(dictionary=dictionary)
    try:
        yield conn, cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def call_proc(name: str, args: Iterable[Any] = ()) -> tuple[list[dict], Optional[str]]:
    """
    Call a stored procedure.
    Returns (rows, error_message). On SIGNAL 45000, rows is [] and error_message is set.
    """
    try:
        with db_cursor() as (conn, cursor):
            cursor.callproc(name, list(args))
            rows: list[dict] = []
            for result in cursor.stored_results():
                rows.extend(result.fetchall())
            return rows, None
    except MySQLError as exc:
        # 1644 = unhandled user-defined exception (SIGNAL SQLSTATE '45000')
        return [], str(exc.msg if hasattr(exc, "msg") else exc)


def fetch_all(sql: str, params: Optional[tuple] = None) -> tuple[list[dict], Optional[str]]:
    try:
        with db_cursor() as (_conn, cursor):
            cursor.execute(sql, params or ())
            return cursor.fetchall(), None
    except MySQLError as exc:
        return [], str(exc.msg if hasattr(exc, "msg") else exc)


def call_function(sql_expr: str, params: Optional[tuple] = None) -> tuple[Any, Optional[str]]:
    """Run e.g. SELECT fn_CalculateDriverNetSettlement(%s, %s, %s) AS result."""
    rows, err = fetch_all(sql_expr, params)
    if err:
        return None, err
    if not rows:
        return None, None
    first = rows[0]
    return next(iter(first.values())), None
