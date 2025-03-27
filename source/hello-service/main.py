from fastapi import FastAPI
import psycopg2
import os

db_host = os.getenv("DB_HOST", "localhost")
db_user = os.getenv("DB_USER", "myuser")
db_pass = os.getenv("DB_PASSWORD", "mypassword")
db_name = os.getenv("DB_NAME", "mydb")
db_port = os.getenv("DB_PORT", "5432")


app = FastAPI()

@app.get("/")
async def root():
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_pass,
        host=db_host,
        port=db_port
    )

    with conn:
        with conn.cursor() as cur:
            cur.execute("SELECT message FROM messages LIMIT 1;")
            result = cur.fetchone()        
    conn.close()

    return {"message": result[0] if result else None}
