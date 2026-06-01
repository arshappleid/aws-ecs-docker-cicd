from fastapi import FastAPI, APIRouter
from datetime import datetime

app = FastAPI()
router = APIRouter()


@router.get("/info")
def hello_world():
    current_time = datetime.now().strftime("%I:%M %p")
    return {"message": "Prabhmeets Server", "time": current_time}


app.include_router(router)
