from fastapi import FastAPI, APIRouter
from datetime import datetime
import os

app = FastAPI()
router = APIRouter()


@router.get("/info")
def hello_world():
    current_time = datetime.now().strftime("%I:%M %p")
    env = os.getenv("ENV", "development")
    return {"message": "Prabhmeets Server", "time": current_time, "env": env}


app.include_router(router)
