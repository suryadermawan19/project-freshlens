# functions/main.py

# ===============================
# Imports
# ===============================
import os
import json
import base64
import time
import tempfile
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, List

# Import berat: tetap di top-level sesuai permintaan
import numpy as np
import pandas as pd
import lightgbm as lgb

from firebase_functions import scheduler_fn
from firebase_functions import firestore_fn, https_fn, options
from firebase_admin import initialize_app, storage, firestore, messaging

try:
    from google.cloud import vision
except ImportError:
    vision = None

# ===============================
# Konfigurasi Global
# ===============================
logging.basicConfig(level=logging.INFO)
PROJECT_ID = os.getenv("GCP_PROJECT") or os.getenv("GCLOUD_PROJECT")
_FIREBASE_CONFIG = json.loads(os.environ.get("FIREBASE_CONFIG", "{}"))

DEFAULT_BUCKET = (
    os.getenv("STORAGE_BUCKET")
    or _FIREBASE_CONFIG.get("storageBucket")
    or (f"{PROJECT_ID}.appspot.com" if PROJECT_ID else None)
)


# ---- NAMA FILE MODEL DI STORAGE (root bucket)
MODEL_BLOB_PATH = "freshlens_lgbm.txt"

options.set_global_options(region="asia-southeast2")
initialize_app(options={"storageBucket": DEFAULT_BUCKET})

# Cache booster di memori proses
_booster_cache: Optional[lgb.Booster] = None

# --- TRAINING_COLUMNS (17 fitur final) ---
TRAINING_COLUMNS: List[str] = [
    "Hari_Ke", "Suhu (°C)", "Kelembapan (%)", "temp_x_humid",
    "Nama_Item_Alpukat", "Nama_Item_Anggur", "Nama_Item_Apel",
    "Nama_Item_Jeruk", "Nama_Item_Mangga", "Nama_Item_Pisang",
    "Nama_Item_Stroberi", "Nama_Item_Tomat",
    "Kondisi_Awal_Matang", "Kondisi_Awal_Mentah",
    "Kondisi_Awal_Segar", "Kondisi_Awal_Setengah Matang",
    "Kondisi_Penyimpanan_Kulkas"
]

# ===============================
# Helper: Loader Model (LightGBM)
# ===============================
def _load_booster_if_needed() -> lgb.Booster:
    """Lazy-load LightGBM booster dari Firebase Storage dan cache di memori."""
    global _booster_cache
    if _booster_cache is not None:
        return _booster_cache

    logging.info(f"[ModelLoader] Bucket: {DEFAULT_BUCKET}, Blob: {MODEL_BLOB_PATH}")
    bucket = storage.bucket(DEFAULT_BUCKET)
    blob = bucket.blob(MODEL_BLOB_PATH)
    if not blob.exists():
        raise FileNotFoundError(f"Model NOT FOUND at gs://{DEFAULT_BUCKET}/{MODEL_BLOB_PATH}")

    last_err: Optional[Exception] = None
    for attempt in range(1, 4):
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".txt") as tmp:
                tmp_path = tmp.name
            blob.download_to_filename(tmp_path)

            booster = lgb.Booster(model_file=tmp_path)

            os.remove(tmp_path)
            _booster_cache = booster
            logging.info("[ModelLoader] LightGBM Booster loaded successfully")
            return _booster_cache
        except Exception as e:
            last_err = e
            logging.warning(f"[ModelLoader] Failed (try {attempt}): {e}")
            time.sleep(1.0)
    raise RuntimeError(f"Failed to load model after retries: {last_err}")

# ===============================
# Helper: Sensor & Feature Builder
# ===============================
def _get_sensor_statistics(uid: str, hours: int = 24) -> Dict[str, float]:
    """Ambil ringkasan suhu/RH dari 24 jam terakhir; fallback ke 'latest' atau default."""
    db = firestore.client()
    now = datetime.now(timezone.utc)
    start_time = now - timedelta(hours=hours)

    history_ref = (
        db.collection("users")
        .document(uid)
        .collection("sensor_data")
        .document("history")
        .collection("entries")
    )
    query = history_ref.where("createdAt", ">=", start_time).stream()

    temps, humids = [], []
    for doc in query:
        data = doc.to_dict() or {}
        if data.get("temperature") is not None:
            temps.append(data["temperature"])
        if data.get("humidity") is not None:
            humids.append(data["humidity"])

    # Fallback: pakai 'latest' jika history kosong
    if not temps or not humids:
        latest_doc = (
            db.collection("users")
            .document(uid)
            .collection("sensor_data")
            .document("latest")
            .get()
        )
        if latest_doc.exists:
            latest_data = latest_doc.to_dict() or {}
            if not temps and latest_data.get("temperature") is not None:
                temps.append(latest_data["temperature"])
            if not humids and latest_data.get("humidity") is not None:
                humids.append(latest_data["humidity"])

    # Fallback final: default wajar
    if not temps:
        temps = [25.0]
    if not humids:
        humids = [80.0]

    return {
        "avg_temp": float(np.mean(temps)),
        "avg_humid": float(np.mean(humids)),
    }

# Alias untuk one-hot
_ITEM_ALIASES = {
    "alpukat": "Nama_Item_Alpukat",
    "anggur": "Nama_Item_Anggur",
    "apel": "Nama_Item_Apel",
    "jeruk": "Nama_Item_Jeruk",
    "mangga": "Nama_Item_Mangga",
    "pisang": "Nama_Item_Pisang",
    "stroberi": "Nama_Item_Stroberi",
    "tomat": "Nama_Item_Tomat",
}
_COND_ALIASES = {
    "matang": "Kondisi_Awal_Matang",
    "mentah": "Kondisi_Awal_Mentah",
    "segar": "Kondisi_Awal_Segar",
    "setengah matang": "Kondisi_Awal_Setengah Matang",
    "setengah_matang": "Kondisi_Awal_Setengah Matang",
}

def _one_hot(keys: List[str], selected_key: Optional[str]) -> Dict[str, int]:
    return {k: (1 if k == selected_key else 0) for k in keys}

def _build_features_for_item(uid: str, item_doc_data: Dict) -> pd.DataFrame:
    """
    Bangun 17 kolom fitur final:
      Numerik: Hari_Ke, Suhu (°C), Kelembapan (%), temp_x_humid
      One-hot: 8 Nama_Item, 4 Kondisi_Awal, 1 Kondisi_Penyimpanan_Kulkas
    """
    # Durasi hari sejak entryDate
    entry_ts = item_doc_data.get("entryDate")
    durasi_hari = 0.0
    if entry_ts:
        dt_entry = entry_ts if isinstance(entry_ts, datetime) else entry_ts.to_datetime()
        durasi_hari = (datetime.now(timezone.utc) - dt_entry.replace(tzinfo=timezone.utc)).total_seconds() / 86400.0

    # Sensor (pakai AVG saja)
    sensor_stats = _get_sensor_statistics(uid)
    suhu = float(sensor_stats.get("avg_temp", 25.0))
    rh = float(sensor_stats.get("avg_humid", 80.0))

    base_features: Dict[str, float] = {
        "Hari_Ke": int(round(durasi_hari)),
        "Suhu (°C)": suhu,
        "Kelembapan (%)": rh,
        "temp_x_humid": suhu * rh,  # sesuai training; tidak dinormalisasi
    }

    # One-hot Nama Item & Kondisi Awal
    raw_item = (item_doc_data.get("itemName") or "").strip().lower()
    raw_cond = (item_doc_data.get("initialCondition") or "").strip().lower()

    item_keys = [
        "Nama_Item_Alpukat",
        "Nama_Item_Anggur",
        "Nama_Item_Apel",
        "Nama_Item_Jeruk",
        "Nama_Item_Mangga",
        "Nama_Item_Pisang",
        "Nama_Item_Stroberi",
        "Nama_Item_Tomat",
    ]
    cond_keys = [
        "Kondisi_Awal_Matang",
        "Kondisi_Awal_Mentah",
        "Kondisi_Awal_Segar",
        "Kondisi_Awal_Setengah Matang",
    ]

    base_features.update(_one_hot(item_keys, _ITEM_ALIASES.get(raw_item)))
    base_features.update(_one_hot(cond_keys, _COND_ALIASES.get(raw_cond)))

    # Penyimpanan: 1 biner saja -> Kulkas
    storage_mode = (item_doc_data.get("storageMode") or "suhu ruang").strip().lower()
    base_features["Kondisi_Penyimpanan_Kulkas"] = 1 if storage_mode == "kulkas" else 0

    # Reindex agar urutan & kolom persis
    return pd.DataFrame([base_features]).reindex(columns=TRAINING_COLUMNS, fill_value=0)

def _predict_days(booster: lgb.Booster, df: pd.DataFrame) -> int:
    """Infer sisa umur (hari) dan clamp 0..365, lalu bulatkan ke int."""
    X = df[TRAINING_COLUMNS].to_numpy(dtype=np.float32)
    y = booster.predict(X)
    return int(round(float(np.clip(y[0], 0, 365))))

# ===============================
# Callable: Cloud Vision (opsional)
# ===============================
@https_fn.on_call(memory=options.MemoryOption.MB_512)
def annotate_image(req: https_fn.CallableRequest):
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Anda harus login."
        )
    if vision is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="google-cloud-vision tidak terpasang di environment Functions."
        )

    body = req.data or {}
    img_b64 = body.get("image")
    if not img_b64 or not isinstance(img_b64, str):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Field 'image' (base64 string) wajib dikirim."
        )

    try:
        # Bersihkan prefix data URI jika ada
        if img_b64.startswith("data:"):
            comma = img_b64.find(",")
            img_b64 = img_b64[comma + 1:] if comma != -1 else img_b64

        raw_bytes = base64.b64decode(img_b64)

        if len(raw_bytes) > 6 * 1024 * 1024:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Gambar terlalu besar ({len(raw_bytes)} B). Kompres/resize di client dulu."
            )

        client = vision.ImageAnnotatorClient()
        image = vision.Image(content=raw_bytes)
        response = client.label_detection(image=image, max_results=5)

        if response.error.message:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message=f"Vision error: {response.error.message}"
            )

        labels = response.label_annotations or []
        top = labels[0].description if labels else "Tidak terdeteksi"
        return {"label": top}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logging.exception("[AnnotateImage] ERROR")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Gagal menganotasi gambar: {e}"
        )

# ===============================
# Trigger: Prediksi awal saat item dibuat
# ===============================
@firestore_fn.on_document_created(document="users/{uid}/items/{itemId}", memory=options.MemoryOption.MB_512)
def predict_initial_shelflife(event: firestore_fn.Event[firestore.DocumentSnapshot]):
    uid, ref = event.params["uid"], event.data.reference
    try:
        booster = _load_booster_if_needed()
        df = _build_features_for_item(uid, event.data.to_dict())
        pred_days = _predict_days(booster, df)
        ref.update({
            "predictedShelfLife": pred_days,
            "predictionStatus": "ok",
            "predictionUpdatedAt": firestore.SERVER_TIMESTAMP
        })
        logging.info(f"[PredictInitial] OK uid={uid} item={event.params['itemId']} days={pred_days}")
    except Exception as e:
        logging.exception(f"[PredictInitial] ERROR for uid={uid}")
        ref.update({
            "predictionStatus": f"error: {e}",
            "predictionUpdatedAt": firestore.SERVER_TIMESTAMP
        })

# ===============================
# Trigger: Log setiap update sensor ke 'history'
# ===============================
@firestore_fn.on_document_written(document="users/{uid}/sensor_data/latest")
def log_sensor_data_to_history(event: firestore_fn.Event[firestore.DocumentSnapshot]):
    uid = event.params["uid"]
    after = event.data
    if not after.exists:
        return

    data = after.to_dict() or {}
    temperature = float(data.get("temperature", 25.0))
    humidity = float(data.get("humidity", 80.0))

    db = firestore.client()
    history_entries = (
        db.collection("users")
        .document(uid)
        .collection("sensor_data")
        .document("history")
        .collection("entries")
    )
    history_entries.add({
        "temperature": temperature,
        "humidity": humidity,
        "source": "iot-latest",
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    # Trim history agar tidak tumbuh tak terbatas
    try:
        old = history_entries.order_by("createdAt", direction=firestore.Query.DESCENDING).offset(1000).limit(100).stream()
        batch = db.batch()
        cnt = 0
        for doc in old:
            batch.delete(doc.reference)
            cnt += 1
        if cnt:
            batch.commit()
    except Exception as e:
        logging.warning(f"[SensorHistory] trim failed: {e}")

# ===============================
# Trigger: Re-predict saat sensor berubah
# ===============================
@firestore_fn.on_document_updated(document="users/{uid}/sensor_data/latest", memory=options.MemoryOption.MB_512)
def on_sensor_data_update_and_repredict(event: firestore_fn.Event[firestore.DocumentSnapshot]):
    uid = event.params["uid"]
    try:
        before, after = {}, {}
        try:
            before = event.data.before.to_dict() or {}
            after = event.data.after.to_dict() or {}
        except AttributeError:
            after = event.data.to_dict() or {}

        if before and after and before.get("temperature") == after.get("temperature") and before.get("humidity") == after.get("humidity"):
            logging.info("[RePredictOnSensor] No sensor change; skip recompute.")
            return

        booster = _load_booster_if_needed()
        db = firestore.client()
        items_ref = db.collection("users").document(uid).collection("items")

        total_updated = 0
        for item in items_ref.stream():
            try:
                df = _build_features_for_item(uid, item.to_dict())
                pred_days = _predict_days(booster, df)
                item.reference.update({
                    "predictedShelfLife": pred_days,
                    "predictionStatus": "ok",
                    "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                })
                total_updated += 1
            except Exception as ie:
                item.reference.update({
                    "predictionStatus": f"error: {ie}",
                    "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                })
                logging.warning(f"[RePredictOnSensor][ITEM] uid={uid} item={item.id} err={ie}")

        logging.info(f"[RePredictOnSensor] uid={uid} updated items: {total_updated}")
    except Exception as e:
        logging.exception("[RePredictOnSensor][FATAL]")

# ===============================
# Scheduler: Recalc setiap 3 jam
# ===============================
@scheduler_fn.on_schedule(schedule="every 3 hours", memory=options.MemoryOption.MB_512)
def update_all_shelflives(event: scheduler_fn.ScheduledEvent):
    db = firestore.client()
    try:
        booster = _load_booster_if_needed()
        cutoff = datetime.now(timezone.utc) - timedelta(hours=3)

        users = db.collection("users").stream()
        total_updated = 0

        for u in users:
            uid = u.id
            items_ref = db.collection("users").document(uid).collection("items")
            try:
                candidates = items_ref.where("predictionUpdatedAt", "<", cutoff).stream()
            except Exception:
                candidates = items_ref.stream()

            for item in candidates:
                try:
                    df = _build_features_for_item(uid, item.to_dict())
                    pred_days = _predict_days(booster, df)
                    item.reference.update({
                        "predictedShelfLife": pred_days,
                        "predictionStatus": "ok",
                        "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    total_updated += 1
                except Exception as ie:
                    item.reference.update({
                        "predictionStatus": f"error: {ie}",
                        "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    logging.warning(f"[UpdateAll][ITEM] uid={uid} item={item.id} err={ie}")

        logging.info(f"[UpdateAll] Done. Updated items: {total_updated}")
    except Exception as e:
        logging.exception("[UpdateAll][FATAL]")

# ===============================
# Scheduler: Recalc harian pukul 00:00 WIB
# ===============================
@scheduler_fn.on_schedule(schedule="0 0 * * *", timezone="Asia/Jakarta", memory=options.MemoryOption.MB_512)
def daily_shelflife_recalculation(event: scheduler_fn.ScheduledEvent):
    
    wib_tz = timezone(timedelta(hours=7))
    
    logging.info(f"Fungsi terjadwal harian berjalan pada: {datetime.now(wib_tz)}")
    
    db = firestore.client()
    try:
        booster = _load_booster_if_needed()
        users = db.collection("users").stream()
        total_updated = 0
        for user in users:
            uid = user.id
            items_ref = db.collection("users").document(uid).collection("items")
            for item in items_ref.stream():
                try:
                    df = _build_features_for_item(uid, item.to_dict())
                    pred_days = _predict_days(booster, df)
                    item.reference.update({
                        "predictedShelfLife": pred_days,
                        "predictionStatus": "repredicted_daily",
                        "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    total_updated += 1
                except Exception as ie:
                    logging.error(f"[DailyRecalc][ITEM] uid={uid} item={item.id} err={ie}")
        logging.info(f"[DailyRecalc] Selesai. Total item diperbarui: {total_updated}")
    except Exception as e:
        logging.critical(f"[DailyRecalc][FATAL] {e}")

# ===============================
# Scheduler: Notifikasi harian item kadaluarsa (FCM)
# ===============================
@scheduler_fn.on_schedule(schedule="every day 09:00", timezone="Asia/Jakarta", memory=options.MemoryOption.MB_512)
def check_expiring_items(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Memeriksa semua item di inventaris semua pengguna dan mengirim notifikasi
    jika ada item yang akan kedaluwarsa dalam <= 2 hari.
    """
    logging.info("[FCM] Menjalankan pengecekan item kedaluwarsa...")
    db = firestore.client()

    try:
        # Ambil semua item dari semua pengguna yang akan habis dalam 2 hari
        expiring_items_query = db.collection_group('items').where('predictedShelfLife', '<=', 2)
        expiring_items = expiring_items_query.stream()

        # Cache token per user agar tidak query user doc berulang-ulang
        token_cache: Dict[str, Optional[str]] = {}

        for item in expiring_items:
            item_data = item.to_dict() or {}
            item_name = item_data.get('itemName', 'Item')

            # Dapatkan ID pemilik dari path dokumen (users/{uid}/items/{itemId})
            owner_ref = item.reference.parent.parent  # type: ignore[assignment]
            if owner_ref is None:
                logging.warning("[FCM] Gagal temukan owner_ref untuk item %s", item.id)
                continue
            owner_id = owner_ref.id

            if owner_id not in token_cache:
                user_doc = db.collection('users').document(owner_id).get()
                token_cache[owner_id] = (user_doc.to_dict() or {}).get('fcmToken') if user_doc.exists else None

            token = token_cache.get(owner_id)
            if not token:
                logging.info(f"[FCM] Lewati {owner_id}: tidak ada fcmToken")
                continue

            # Buat dan kirim pesan notifikasi
            msg = messaging.Message(
                notification=messaging.Notification(
                    title='Segera Habis!',
                    body=f"Jangan lupa, {item_name} Anda akan segera habis masa simpannya. Yuk, segera diolah!",
                ),
                token=token,
            )
            try:
                resp = messaging.send(msg)
                logging.info(f"[FCM] Notifikasi terkirim ke {owner_id}: {resp}")
            except Exception as e:
                logging.error(f"[FCM] Gagal mengirim notifikasi ke {owner_id}: {e}")

    except Exception as e:
        logging.error(f"[FCM] Error saat query/pengiriman notifikasi: {e}")
    
# Di dalam functions/main.py

# ... (kode import dan fungsi notifikasi yang sudah ada) ...

# ===============================
# Cloud Function: Registrasi Perangkat IoT
# ===============================
@https_fn.on_call(region="asia-southeast2", memory=options.MemoryOption.MB_512)
def registerDevice(req: https_fn.CallableRequest) -> Dict[str, any]:
    """
    Menghubungkan perangkat IoT ke akun pengguna yang sedang login.
    Menerima deviceId dari aplikasi Flutter.
    """
    db = firestore.client()
    if not req.auth:
        raise https_fn.HttpsError(code="unauthenticated", message="Anda harus login untuk mendaftarkan perangkat.")

    uid = req.auth.uid
    device_id = req.data.get("deviceId")

    if not device_id:
        raise https_fn.HttpsError(code="invalid-argument", message="deviceId tidak boleh kosong.")

    logging.info(f"User '{uid}' mencoba mendaftarkan perangkat '{device_id}'")
    
    device_ref = db.collection('iot_devices').document(device_id)
    user_ref = db.collection('users').document(uid)

    try:
        device_doc = device_ref.get()
        if not device_doc.exists:
            raise https_fn.HttpsError(code="not-found", message="Perangkat dengan ID ini tidak ditemukan.")

        device_data = device_doc.to_dict()
        if device_data.get('ownerUid') is not None:
            raise https_fn.HttpsError(code="already-exists", message="Perangkat ini sudah terhubung dengan akun lain.")

        # Lakukan update secara transaksional untuk keamanan
        @firestore.transactional
        def update_in_transaction(transaction, device_ref, user_ref):
            transaction.update(device_ref, {
                'ownerUid': uid,
                'status': 'active'
            })
            transaction.update(user_ref, {
                'linkedDeviceId': device_id
            })
        
        transaction = db.transaction()
        update_in_transaction(transaction, device_ref, user_ref)
        
        logging.info(f"Perangkat '{device_id}' berhasil terhubung dengan user '{uid}'")
        return {"status": "success", "message": "Perangkat berhasil terhubung!"}

    except Exception as e:
        logging.error(f"Gagal mendaftarkan perangkat '{device_id}': {e}")
        raise https_fn.HttpsError(code="internal", message=f"Terjadi kesalahan: {e}")


# ===============================
# Cloud Function: Menerima Data Sensor IoT
# ===============================
@https_fn.on_request(region="asia-southeast2")
def ingestSensorData(req: https_fn.Request) -> https_fn.Response:
    """
    Endpoint HTTP untuk menerima data dari perangkat ESP32.
    """
    db = firestore.client()

    if req.method != "POST":
        return https_fn.Response("Metode tidak diizinkan", status=405)
    
    try:
        data = req.get_json()
        device_id = data.get("deviceId")
        temperature = data.get("temperature")
        humidity = data.get("humidity")

        if not device_id or temperature is None or humidity is None:
            return https_fn.Response("Data tidak lengkap: deviceId, temperature, dan humidity wajib diisi.", status=400)

        logging.info(f"Menerima data dari perangkat '{device_id}': Temp={temperature}, Humid={humidity}")

        device_ref = db.collection('iot_devices').document(device_id)
        device_doc = device_ref.get()

        if not device_doc.exists:
            return https_fn.Response("Perangkat tidak terdaftar.", status=404)
        
        owner_uid = device_doc.to_dict().get('ownerUid')

        if not owner_uid:
            return https_fn.Response("Perangkat belum terhubung dengan pengguna.", status=403)
            
        # Simpan data sensor ke path pengguna yang benar
        sensor_latest_ref = db.collection('users').document(owner_uid).collection('sensor_data').document('latest')
        sensor_latest_ref.set({
            'temperature': float(temperature),
            'humidity': float(humidity),
            'lastUpdate': firestore.SERVER_TIMESTAMP
        })
        
        return https_fn.Response("Data berhasil diterima.", status=200)

    except Exception as e:
        logging.error(f"Error saat memproses data sensor: {e}")
        return https_fn.Response("Terjadi kesalahan internal.", status=500)

@https_fn.on_call(region="asia-southeast2",)
def unregisterDevice(req: https_fn.CallableRequest) -> Dict[str, any]:
    """
    Memutuskan hubungan perangkat IoT dari akun pengguna yang sedang login.
    """
    if not req.auth:
        raise https_fn.HttpsError(code="unauthenticated", message="Anda harus login untuk melakukan aksi ini.")

    uid = req.auth.uid
    db = firestore.client()
    logging.info(f"User '{uid}' mencoba memutuskan hubungan perangkat.")
    
    user_ref = db.collection('users').document(uid)

    try:
        user_doc = user_ref.get()
        if not user_doc.exists:
            raise https_fn.HttpsError(code="not-found", message="Profil pengguna tidak ditemukan.")

        user_data = user_doc.to_dict()
        device_id = user_data.get('linkedDeviceId')

        if not device_id:
            raise https_fn.HttpsError(code="failed-precondition", message="Tidak ada perangkat yang terhubung dengan akun ini.")

        device_ref = db.collection('iot_devices').document(device_id)

        # Lakukan update secara transaksional
        @firestore.transactional
        def update_in_transaction(transaction, device_ref, user_ref):
            # 1. Hapus hubungan di dokumen perangkat
            transaction.update(device_ref, {
                'ownerUid': None, # Set kembali ke null
                'status': 'unclaimed'
            })
            # 2. Hapus hubungan di dokumen pengguna
            transaction.update(user_ref, {
                'linkedDeviceId': firestore.DELETE_FIELD
            })
        
        transaction = db.transaction()
        update_in_transaction(transaction, device_ref, user_ref)
        
        logging.info(f"Perangkat '{device_id}' berhasil diputuskan dari user '{uid}'")
        return {"status": "success", "message": "Perangkat berhasil diputuskan!"}

    except Exception as e:
        logging.error(f"Gagal memutuskan perangkat untuk user '{uid}': {e}")
        raise https_fn.HttpsError(code="internal", message=f"Terjadi kesalahan: {e}")

