from fastapi import FastAPI
import psycopg2

app = FastAPI()

@app.get("/")
async def root():
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        dbname="mydb",
        user="myuser",
        password="mypassword",
        host="postgres",  # or your DB host
        port="5432"
    )

    with conn:
        with conn.cursor() as cur:
            cur.execute("SELECT message FROM messages LIMIT 1;")
            result = cur.fetchone()        
    conn.close()

    return {"message": result[0] if result else None}
