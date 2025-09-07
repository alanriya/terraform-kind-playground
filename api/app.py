from fastapi import FastAPI, Request
import time, os
app = FastAPI()
@app.get("/health")
def health(): return {"status":"ok"}

@app.get("/time")
def now(): return {"epoch": int(time.time())}

@app.post("/echo")
async def echo(req: Request):
    payload = await req.json()
    return {"pod": os.getenv("HOSTNAME","unknown"), "payload": payload}