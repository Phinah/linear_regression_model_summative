
from fastapi import FastAPI
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and scaler
model = joblib.load("best_model.pkl")
scaler = joblib.load("scaler.pkl")

# Define input schema using Pydantic
class PredictionInput(BaseModel):
    T_TL: float = Field(..., gt=0, description="Total population")
    T_00_004: float = Field(..., ge=0, description="Population aged 0-4")
    Total_Measles_GE1: float = Field(..., ge=0)
    Total_Measles_L1: float = Field(..., ge=0)
    Total_Measles2_GE1: float = Field(..., ge=0)
    Total_Measles2_L1: float = Field(..., ge=0)
    Total_YF_L1: float = Field(..., ge=0)
    Total_YF_GE1: float = Field(..., ge=0)

@app.post("/predict")
def predict(input: PredictionInput):
    data = np.array([[input.T_TL, input.T_00_004, input.Total_Measles_GE1,
                      input.Total_Measles_L1, input.Total_Measles2_GE1,
                      input.Total_Measles2_L1, input.Total_YF_L1,
                      input.Total_YF_GE1]])
    data_scaled = scaler.transform(data)
    prediction = model.predict(data_scaled)
    return {"predicted_measles_outbreak": prediction[0]}
