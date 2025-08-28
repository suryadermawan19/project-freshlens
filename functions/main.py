# functions/main.py

# Impor library yang dibutuhkan
import firebase_functions
from firebase_functions import firestore_fn, options, scheduler_fn
from firebase_admin import initialize_app, storage, firestore
import pandas as pd
import xgboost as xgb
import numpy as np
import os
import tempfile
from datetime import datetime

# Inisialisasi Firebase Admin SDK
initialize_app()
options.set_global_options(region="asia-southeast2")  # Set region ke Jakarta

# Variabel global
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

# --- Fungsi helper untuk memuat model ---
def get_model():
    global model
    if model is None:
        try:
            bucket = storage.bucket()
            source_blob_name = "freshlens_model.json"
            temp_model_path = os.path.join(tempfile.gettempdir(), source_blob_name)

            blob = bucket.blob(source_blob_name)
            blob.download_to_filename(temp_model_path)

            print(f"Memuat model dari: {temp_model_path}")
            model = xgb.XGBRegressor()
            model.load_model(temp_model_path)
            print("Model XGBoost berhasil dimuat.")
        except Exception as e:
            print(f"Error saat memuat model: {e}")
            model = None
    return model


# --- 1. Fungsi prediksi awal saat item dibuat ---
@firestore_fn.on_document_created(document="users/{userId}/items/{itemId}")
def predict_initial_shelflife(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    model = get_model()
    if model is None:
        print("Model tidak berhasil dimuat, fungsi prediksi awal tidak bisa berjalan.")
        return

    user_id = event.params["userId"]
    item_id = event.params["itemId"]
    print(f"Fungsi prediksi awal dipicu untuk user: {user_id}, item: {item_id}")

    item_data = event.data.to_dict()
    item_name = item_data.get("itemName")
    initial_condition = item_data.get("initialCondition")

    if not item_name or not initial_condition:
        print("Nama item atau kondisi awal tidak ada. Fungsi berhenti.")
        return

    db = firestore.client()
    sensor_ref = db.collection("users").document(user_id).collection("sensor_data").document("latest")
    sensor_snapshot = sensor_ref.get()

    current_temp = 25.0
    current_humid = 80.0
    if sensor_snapshot.exists:
        sensor_data = sensor_snapshot.to_dict()
        current_temp = sensor_data.get("temperature", 25.0)
        current_humid = sensor_data.get("humidity", 80.0)
    else:
        print("Data sensor tidak ditemukan. Menggunakan nilai default.")

    feature_dict = {
        'avg_temp': current_temp, 'std_temp': 0, 'max_temp': current_temp,
        'min_temp': current_temp, 'avg_humid': current_humid, 'std_humid': 0,
        'max_humid': current_humid, 'min_humid': current_humid,
        'durasi_observasi': 0,
        f'Nama_Item_{item_name}': 1,
        f'Kondisi_Awal_{initial_condition}': 1,
        'Kondisi_Penyimpanan_Suhu Ruang': 1,
    }

    predict_df = pd.DataFrame([feature_dict])
    predict_df = predict_df.reindex(columns=TRAINING_COLUMNS, fill_value=0)

    prediction_result = model.predict(predict_df)
    predicted_days = int(round(prediction_result[0]))

    print(f"Hasil prediksi awal untuk {item_name}: {predicted_days} hari")

    item_ref = db.collection("users").document(user_id).collection("items").document(item_id)
    item_ref.update({"predictedShelfLife": predicted_days})
    print(f"Firestore berhasil diupdate untuk item {item_id}.")


# --- 2. Fungsi terjadwal untuk update prediksi ---
@scheduler_fn.on_schedule(schedule="every 3 minutes")
def update_all_shelflives(event: scheduler_fn.ScheduledEvent) -> None:
    model = get_model()
    if model is None:
        print("Model tidak berhasil dimuat, fungsi update terjadwal tidak bisa berjalan.")
        return

    print(f"Fungsi terjadwal berjalan pada: {event.timestamp}")
    db = firestore.client()
    users = db.collection("users").stream()

    for user in users:
        user_id = user.id
        print(f"Memproses item untuk user: {user_id}")

        sensor_ref = db.collection("users").document(user_id).collection("sensor_data").document("latest")
        sensor_snapshot = sensor_ref.get()

        if not sensor_snapshot.exists:
            print(f"Tidak ada data sensor untuk {user_id}, lewati.")
            continue

        sensor_data = sensor_snapshot.to_dict()
        current_temp = sensor_data.get("temperature")
        current_humid = sensor_data.get("humidity")

        if current_temp is None or current_humid is None:
            continue

        items_ref = db.collection("users").document(user_id).collection("items")
        all_items = items_ref.stream()
        batch = db.batch()

        for item in all_items:
            item_data = item.to_dict()
            item_name = item_data.get("itemName")
            initial_condition = item_data.get("initialCondition")
            entry_timestamp = item_data.get("entryDate")

            if not all([item_name, initial_condition, entry_timestamp]):
                continue

            entry_date = entry_timestamp.replace(tzinfo=None)
            days_since_entry = (datetime.utcnow() - entry_date).total_seconds() / (60 * 60 * 24)

            feature_dict = {
                'avg_temp': current_temp, 'std_temp': 0, 'max_temp': current_temp,
                'min_temp': current_temp, 'avg_humid': current_humid, 'std_humid': 0,
                'max_humid': current_humid, 'min_humid': current_humid,
                'durasi_observasi': days_since_entry,
                f'Nama_Item_{item_name}': 1,
                f'Kondisi_Awal_{initial_condition}': 1,
                'Kondisi_Penyimpanan_Suhu Ruang': 1,
            }

            predict_df = pd.DataFrame([feature_dict])
            predict_df = predict_df.reindex(columns=TRAINING_COLUMNS, fill_value=0)

            prediction_result = model.predict(predict_df)
            predicted_days = int(round(prediction_result[0]))

            batch.update(item.reference, {"predictedShelfLife": predicted_days})
            print(f"  -> Item '{item_name}' diupdate jadi {predicted_days} hari.")

        batch.commit()

    print("Semua item berhasil diupdate.")