# functions/main.py

# Impor library yang dibutuhkan
import firebase_functions
from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, storage, firestore
import pandas as pd
import xgboost as xgb
import numpy as np
import os
import tempfile

# Inisialisasi Firebase Admin SDK
initialize_app()
options.set_global_options(region="asia-southeast2") # Set region ke Jakarta

# --- 1. MEMUAT MODEL SAAT FUNGSI PERTAMA KALI JALAN (COLD START) ---
try:
    # Dapatkan bucket default dari Firebase Storage
    bucket = storage.bucket()
    # Tentukan path ke model Anda di Storage
    source_blob_name = "freshlens_model.json"
    # Tentukan path sementara di memori server untuk menyimpan model
    temp_model_path = os.path.join(tempfile.gettempdir(), source_blob_name)

    # Unduh model dari Storage ke path sementara
    blob = bucket.blob(source_blob_name)
    blob.download_to_filename(temp_model_path)

    # Muat model XGBoost ke dalam memori
    print(f"Memuat model dari: {temp_model_path}")
    model = xgb.XGBRegressor()
    model.load_model(temp_model_path)
    print("Model XGBoost berhasil dimuat.")

    # Simpan kolom fitur yang digunakan saat training (ini SANGAT PENTING)
    # Urutan dan nama harus sama persis dengan yang ada di notebook Colab
    TRAINING_COLUMNS = [
        'avg_temp', 'std_temp', 'max_temp', 'min_temp', 'avg_humid', 'std_humid',
        'max_humid', 'min_humid', 'durasi_observasi', 'Nama_Item_Alpukat',
        'Nama_Item_Anggur', 'Nama_Item_Apel', 'Nama_Item_Jeruk', 'Nama_Item_Mangga',
        'Nama_Item_Pisang', 'Nama_Item_Stroberi', 'Nama_Item_Tomat',
        'Kondisi_Awal_Matang', 'Kondisi_Awal_Mentah', 'Kondisi_Awal_Segar',
        'Kondisi_Awal_Setengah Matang', 'Kondisi_Penyimpanan_Kulkas',
        'Kondisi_Penyimpanan_Suhu Ruang'
    ]
except Exception as e:
    print(f"Error saat memuat model: {e}")
    model = None

# --- 2. CLOUD FUNCTION YANG AKAN BERJALAN ---
@firestore_fn.on_document_created("users/{userId}/items/{itemId}")
def predict_initial_shelflife(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Dipicu saat item baru ditambahkan.
    Fungsi ini akan membuat prediksi umur simpan awal.
    """
    if model is None:
        print("Model tidak berhasil dimuat, fungsi tidak bisa berjalan.")
        return

    # Dapatkan ID pengguna dan ID item dari path
    user_id = event.params["userId"]
    item_id = event.params["itemId"]
    
    print(f"Fungsi dipicu untuk user: {user_id}, item: {item_id}")

    # Dapatkan data dari item yang baru dibuat
    item_data = event.data.to_dict()
    item_name = item_data.get("itemName")
    initial_condition = item_data.get("initialCondition")
    
    if not item_name or not initial_condition:
        print("Nama item atau kondisi awal tidak ada. Fungsi berhenti.")
        return

    # --- 3. AMBIL DATA SENSOR TERBARU ---
    db = firestore.client()
    sensor_ref = db.collection("users").document(user_id).collection("sensor_data").document("latest")
    sensor_snapshot = sensor_ref.get()
    
    if not sensor_snapshot.exists:
        print("Data sensor tidak ditemukan. Menggunakan nilai default.")
        current_temp = 25.0
        current_humid = 80.0
    else:
        sensor_data = sensor_snapshot.to_dict()
        current_temp = sensor_data.get("temperature", 25.0)
        current_humid = sensor_data.get("humidity", 80.0)

    # --- 4. BUAT FITUR UNTUK PREDIKSI (SESUAI FORMAT TRAINING) ---
    feature_dict = {
        'avg_temp': current_temp, 'std_temp': 0, 'max_temp': current_temp,
        'min_temp': current_temp, 'avg_humid': current_humid, 'std_humid': 0,
        'max_humid': current_humid, 'min_humid': current_humid,
        'durasi_observasi': 0,
        f'Nama_Item_{item_name}': 1,
        f'Kondisi_Awal_{initial_condition}': 1,
        # Asumsi default, ini bisa dikembangkan lebih lanjut
        'Kondisi_Penyimpanan_Suhu Ruang': 1 
    }
    
    predict_df = pd.DataFrame([feature_dict])
    predict_df = predict_df.reindex(columns=TRAINING_COLUMNS, fill_value=0)

    # --- 5. LAKUKAN PREDIKSI ---
    prediction_result = model.predict(predict_df)
    predicted_days = int(round(prediction_result[0]))

    print(f"Hasil prediksi untuk {item_name}: {predicted_days} hari")

    # --- 6. SIMPAN HASIL PREDIKSI KEMBALI KE FIRESTORE ---
    item_ref = db.collection("users").document(user_id).collection("items").document(item_id)
    item_ref.update({"predictedShelfLife": predicted_days})

    print(f"Firestore berhasil diupdate untuk item {item_id} dengan umur simpan {predicted_days} hari.")