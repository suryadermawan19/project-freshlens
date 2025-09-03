# functions/main.py

# Impor library yang dibutuhkan
import firebase_functions
from firebase_functions import firestore_fn, options, scheduler_fn, https_fn
from firebase_admin import initialize_app, storage, firestore
import pandas as pd
import xgboost as xgb
import os
import tempfile
from datetime import datetime, timezone
from google.cloud import vision
import base64

# Inisialisasi Firebase Admin SDK
initialize_app()
options.set_global_options(region="asia-southeast2") # Set region ke Jakarta

# --- Variabel Global & Konfigurasi ---
model = None
TRAINING_COLUMNS = [
    'avg_temp', 'std_temp', 'max_temp', 'min_temp', 'avg_humid', 'std_humid',
    'max_humid', 'min_humid', 'durasi_observasi', 'Nama_Item_Alpukat',
    'Nama_Item_Anggur', 'Nama_Item_Apel', 'Nama_Item_Jeruk', 'Nama_Item_Mangga',
    'Nama_Item_Pisang', 'Nama_Item_Stroberi', 'Nama_Item_Tomat',
    'Kondisi_Awal_Matang', 'Kondisi_Awal_Mentah', 'Kondisi_Awal_Segar',
    'Kondisi_Awal_Setengah Matang', 'Kondisi_Penyimpanan_Kulkas',
    'Kondisi_Penyimpanan_Suhu Ruang'
]

# --- 1. FUNGSI HELPER UNTUK MEMUAT MODEL (LAZY LOADING) ---
def load_model_if_needed():
    """
    Memeriksa apakah model sudah ada di memori. Jika belum, unduh dan muat.
    """
    global model
    if model is None:
        print("Model belum dimuat. Memulai proses pemuatan...")
        try:
            # Pastikan nama bucket sesuai dengan proyek Anda
            bucket = storage.bucket("freshlens-1caf5.appspot.com") 
            source_blob_name = "freshlens_model_dynamic.json" # Pastikan nama file model benar
            temp_model_path = os.path.join(tempfile.gettempdir(), source_blob_name)
            
            blob = bucket.blob(source_blob_name)
            blob.download_to_filename(temp_model_path)

            print(f"Memuat model dari: {temp_model_path}")
            model_instance = xgb.XGBRegressor()
            model_instance.load_model(temp_model_path)
            model = model_instance
            print("Model XGBoost berhasil dimuat.")
        except Exception as e:
            print(f"FATAL: Error saat memuat model: {e}")
            model = None
    else:
        print("Model sudah ada di memori, tidak perlu memuat ulang.")

# --- 2. FUNGSI PREDIKSI AWAL (SAAT ITEM DIBUAT) ---
@firestore_fn.on_document_created(document="users/{userId}/items/{itemId}")
def predict_initial_shelflife(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    load_model_if_needed()
    if model is None:
        print("Model tidak ada. Fungsi prediksi awal berhenti.")
        return

    user_id = event.params["userId"]
    item_id = event.params["itemId"]
    item_data = event.data.to_dict()
    item_name = item_data.get("itemName")
    initial_condition = item_data.get("initialCondition")
    
    if not item_name or not initial_condition: return

    db = firestore.client()
    sensor_ref = db.collection("users").document(user_id).collection("sensor_data").document("latest")
    sensor_snapshot = sensor_ref.get()
    
    current_temp = 25.0
    current_humid = 80.0
    if sensor_snapshot.exists:
        sensor_data = sensor_snapshot.to_dict()
        current_temp = sensor_data.get("temperature", 25.0)
        current_humid = sensor_data.get("humidity", 80.0)

    feature_dict = {'avg_temp': current_temp, 'std_temp': 0, 'max_temp': current_temp, 'min_temp': current_temp, 'avg_humid': current_humid, 'std_humid': 0, 'max_humid': current_humid, 'min_humid': current_humid, 'durasi_observasi': 0, f'Nama_Item_{item_name}': 1, f'Kondisi_Awal_{initial_condition}': 1, 'Kondisi_Penyimpanan_Suhu Ruang': 1}
    predict_df = pd.DataFrame([feature_dict]).reindex(columns=TRAINING_COLUMNS, fill_value=0)
    prediction_result = model.predict(predict_df)
    predicted_days = int(round(prediction_result[0]))
    
    print(f"Prediksi awal untuk {item_name}: {predicted_days} hari")
    event.data.reference.update({"predictedShelfLife": predicted_days})

# --- 3. FUNGSI TERJADWAL UNTUK PREDIKSI DINAMIS ---
@scheduler_fn.on_schedule(schedule="every 3 minutes")
def update_all_shelflives(event: scheduler_fn.ScheduledEvent) -> None:
    load_model_if_needed()
    if model is None:
        print("Model tidak ada. Fungsi terjadwal berhenti.")
        return

    print(f"Fungsi terjadwal berjalan pada: {event.timestamp}")
    db = firestore.client()
    users = db.collection("users").stream()

    for user in users:
        user_id = user.id
        sensor_ref = db.collection("users").document(user_id).collection("sensor_data").document("latest")
        sensor_snapshot = sensor_ref.get()
        if not sensor_snapshot.exists: continue
        
        sensor_data = sensor_snapshot.to_dict()
        current_temp = sensor_data.get("temperature")
        current_humid = sensor_data.get("humidity")
        if current_temp is None or current_humid is None: continue

        items_ref = db.collection("users").document(user_id).collection("items")
        all_items = items_ref.stream()
        batch = db.batch()

        for item in all_items:
            item_data = item.to_dict()
            item_name = item_data.get("itemName")
            initial_condition = item_data.get("initialCondition")
            entry_timestamp = item_data.get("entryDate")
            if not all([item_name, initial_condition, entry_timestamp]): continue

            entry_date = entry_timestamp.replace(tzinfo=None)
            days_since_entry = (datetime.utcnow() - entry_date).total_seconds() / (60 * 60 * 24)

            feature_dict = {'avg_temp': current_temp, 'std_temp': 0, 'max_temp': current_temp, 'min_temp': current_temp, 'avg_humid': current_humid, 'std_humid': 0, 'max_humid': current_humid, 'min_humid': current_humid, 'durasi_observasi': days_since_entry, f'Nama_Item_{item_name}': 1, f'Kondisi_Awal_{initial_condition}': 1, 'Kondisi_Penyimpanan_Suhu Ruang': 1}
            predict_df = pd.DataFrame([feature_dict]).reindex(columns=TRAINING_COLUMNS, fill_value=0)
            prediction_result = model.predict(predict_df)
            predicted_days = int(round(prediction_result[0]))
            
            batch.update(item.reference, {"predictedShelfLife": predicted_days})
        
        batch.commit()
    print("Update terjadwal selesai.")

# --- 4. FUNGSI UNTUK MEMANGGIL CLOUD VISION API ---
@https_fn.on_call(region="asia-southeast2", memory=options.MemoryOption.MB_512)
def annotate_image(req: https_fn.CallableRequest) -> https_fn.Response:
    if req.auth is None:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Anda harus login.")

    image_data_base64 = req.data.get("image")
    if not image_data_base64:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message="Request harus menyertakan data gambar.")

    try:
        print("Memanggil Cloud Vision API...")
        client = vision.ImageAnnotatorClient()
        image_bytes = base64.b64decode(image_data_base64)
        image = vision.Image(content=image_bytes)
        
        response = client.label_detection(image=image)
        labels = response.label_annotations

        if labels:
            top_label = labels[0].description
            print(f"Gambar terdeteksi sebagai: {top_label}")
            return {"label": top_label}
        else:
            print("Tidak ada label yang terdeteksi.")
            return {"label": "Tidak terdeteksi"}

    except Exception as e:
        print(f"Error saat memanggil Vision API: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message="Terjadi kesalahan saat menganalisis gambar.")