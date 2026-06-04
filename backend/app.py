from fastapi import FastAPI, APIRouter
from datetime import datetime
import os

app = FastAPI()
router = APIRouter()


@router.get("/info")
def hello_world():
    current_time = datetime.now().strftime("%I:%M %p")
    env = os.getenv("ENVIRONMENT", "Missing ENVIRONMENT variable")
    return {"message": "Prabhmeets Server", "time": current_time, "env": env}


@router.get("/health")
def health_check():
    return {"status": "healthy"}


app.include_router(router)
