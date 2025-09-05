# functions/main.py

# ===============================
# Imports
# ===============================
import os
import json
import base64
import time
import tempfile
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, List

import numpy as np
import pandas as pd
import xgboost as xgb

from firebase_functions import firestore_fn, https_fn, options, scheduler_fn
from firebase_admin import initialize_app, storage, firestore

# Cloud Vision (opsional)
try:
    from google.cloud import vision
except Exception:
    vision = None


# ===============================
# Konfigurasi Global
# ===============================
PROJECT_ID = os.getenv("GCP_PROJECT") or os.getenv("GCLOUD_PROJECT")

# Ambil bucket dari FIREBASE_CONFIG (atau env), fallback ke <project>.appspot.com
_FIREBASE_CONFIG = json.loads(os.environ.get("FIREBASE_CONFIG", "{}"))
DEFAULT_BUCKET = (
    os.getenv("STORAGE_BUCKET")
    or _FIREBASE_CONFIG.get("storageBucket")
    or f"{PROJECT_ID}.appspot.com"
)

# Ganti sesuai nama/path model di Storage
MODEL_BLOB_PATH = "freshlens_model.json"

# Region default
options.set_global_options(region="asia-southeast2")

# Init Admin + bucket default
initialize_app(options={"storageBucket": DEFAULT_BUCKET})

# Cache booster global (tanpa scikit-learn)
_booster_cache: Optional[xgb.Booster] = None

# Kolom fitur (SAMAKAN dengan saat training!)
TRAINING_COLUMNS: List[str] = [
    "avg_temp", "std_temp", "max_temp", "min_temp",
    "avg_humid", "std_humid", "max_humid", "min_humid",
    "durasi_observasi",
    # One-hot item
    "Nama_Item_Apel", "Nama_Item_Pisang", "Nama_Item_Mangga", "Nama_Item_Jeruk",
    "Nama_Item_Anggur", "Nama_Item_Stroberi", "Nama_Item_Tomat", "Nama_Item_Alpukat",
]


# ===============================
# Helper: Loader Booster (tanpa sklearn) + retry
# ===============================
def _load_booster_if_needed() -> xgb.Booster:
    """Download + load XGBoost Booster (JSON) dari Cloud Storage; cache di memori."""
    global _booster_cache
    if _booster_cache is not None:
        return _booster_cache

    print(f"[ModelLoader] Bucket in use: {DEFAULT_BUCKET}")
    print(f"[ModelLoader] Blob path   : {MODEL_BLOB_PATH}")

    bucket = storage.bucket(DEFAULT_BUCKET)
    blob = bucket.blob(MODEL_BLOB_PATH)
    if not blob.exists():
        raise FileNotFoundError(f"Model NOT FOUND at gs://{DEFAULT_BUCKET}/{MODEL_BLOB_PATH}")

    last_err = None
    for attempt in range(1, 4):
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as tmp:
                tmp_path = tmp.name

            blob.download_to_filename(tmp_path)
            size_bytes = os.path.getsize(tmp_path)
            print(f"[ModelLoader] (try {attempt}) Downloaded -> {tmp_path} ({size_bytes} bytes)")

            booster = xgb.Booster()
            booster.load_model(tmp_path)

            try:
                os.remove(tmp_path)
            except Exception:
                pass

            _booster_cache = booster
            print("[ModelLoader] Booster loaded successfully")
            return _booster_cache
        except Exception as e:
            last_err = e
            print(f"[ModelLoader][WARN] Failed to load booster (try {attempt}): {e}")
            time.sleep(1.0)

    raise RuntimeError(f"Failed to load model after retries: {last_err}")


# ===============================
# Helper: Sensor & Feature Builder
# ===============================
def _get_latest_sensor(uid: str) -> Dict[str, float]:
    """Ambil suhu/RH dari users/{uid}/sensor_data/latest; fallback default."""
    db = firestore.client()
    doc = db.collection("users").document(uid).collection("sensor_data").document("latest").get()
    if doc.exists:
        data = doc.to_dict() or {}
        return {
            "temperature": float(data.get("temperature", 25.0)),
            "humidity": float(data.get("humidity", 80.0)),
        }
    return {"temperature": 25.0, "humidity": 80.0}


_ITEM_KEYS = [
    "Nama_Item_Apel", "Nama_Item_Pisang", "Nama_Item_Mangga", "Nama_Item_Jeruk",
    "Nama_Item_Anggur", "Nama_Item_Stroberi", "Nama_Item_Tomat", "Nama_Item_Alpukat",
]
_COND_KEYS = [
    "Kondisi_Awal_Matang", "Kondisi_Awal_Mentah", "Kondisi_Awal_Segar", "Kondisi_Awal_Setengah_Matang",
]

_ITEM_ALIASES = {
    "apel": "Nama_Item_Apel",
    "pisang": "Nama_Item_Pisang",
    "mangga": "Nama_Item_Mangga",
    "jeruk": "Nama_Item_Jeruk",
    "anggur": "Nama_Item_Anggur",
    "stroberi": "Nama_Item_Stroberi",
    "strawberry": "Nama_Item_Stroberi",
    "tomat": "Nama_Item_Tomat",
    "alpukat": "Nama_Item_Alpukat",
    "avocado": "Nama_Item_Alpukat",
    "avokad": "Nama_Item_Alpukat",
}

_COND_ALIASES = {
    "matang": "Kondisi_Awal_Matang",
    "mentah": "Kondisi_Awal_Mentah",
    "segar": "Kondisi_Awal_Segar",
    "setengah matang": "Kondisi_Awal_Setengah_Matang",
    "setengah_matang": "Kondisi_Awal_Setengah_Matang",
}


def _one_hot(keys: List[str], selected_key: Optional[str]) -> Dict[str, int]:
    return {k: (1 if k == selected_key else 0) for k in keys}


def _build_features_for_item(uid: str, item_doc: firestore.DocumentSnapshot) -> pd.DataFrame:
    """Bangun feature vector: sensor terbaru, durasi hari, one-hot item & kondisi awal."""
    data = item_doc.to_dict() or {}
    raw_item = (data.get("itemName") or "").strip().lower()
    raw_cond = (data.get("initialCondition") or "").strip().lower()

    item_key = _ITEM_ALIASES.get(raw_item)  # bisa None
    cond_key = _COND_ALIASES.get(raw_cond)

    # Durasi (hari) sejak entryDate
    entry_ts = data.get("entryDate")
    durasi_hari = 0.0
    try:
        if entry_ts is not None:
            dt_entry = entry_ts.to_datetime() if hasattr(entry_ts, "to_datetime") else entry_ts
            if isinstance(dt_entry, datetime):
                durasi_hari = (datetime.now(timezone.utc) - dt_entry.replace(tzinfo=timezone.utc)).total_seconds() / 86400.0
    except Exception:
        pass

    s = _get_latest_sensor(uid)
    t = float(s["temperature"])
    h = float(s["humidity"])

    base = {
        "avg_temp": t, "std_temp": 0.0, "max_temp": t, "min_temp": t,
        "avg_humid": h, "std_humid": 0.0, "max_humid": h, "min_humid": h,
        "durasi_observasi": float(max(durasi_hari, 0.0)),
    }
    base.update(_one_hot(_ITEM_KEYS, item_key))
    base.update(_one_hot(_COND_KEYS, cond_key))

    row = {col: base.get(col, 0) for col in TRAINING_COLUMNS}
    return pd.DataFrame([row])


def _predict_days(booster: xgb.Booster, df: pd.DataFrame) -> int:
    """Prediksi hari dengan Booster.inplace_predict (tanpa sklearn)."""
    # Pastikan urutan kolom sesuai
    X = df[TRAINING_COLUMNS].to_numpy(dtype=np.float32, copy=False)
    y = booster.inplace_predict(X)  # shape: (n_samples,)
    pred_days = int(round(float(np.clip(y[0], 0, 365))))
    return pred_days


# ===============================
# Callable: Cloud Vision label detection
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
        print(f"[AnnotateImage][ERROR] {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Gagal menganotasi gambar: {e}"
        )


# ===============================
# Trigger: Prediksi awal saat item dibuat
# ===============================
@firestore_fn.on_document_created(document="users/{uid}/items/{itemId}", memory=options.MemoryOption.MB_512)
def predict_initial_shelflife(event: firestore_fn.Event[firestore.DocumentSnapshot]):
    uid = event.params["uid"]
    ref = event.data.reference
    try:
        booster = _load_booster_if_needed()
        df = _build_features_for_item(uid, event.data)
        pred_days = _predict_days(booster, df)

        ref.update({
            "predictedShelfLife": pred_days,
            "predictionStatus": "ok",
            "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
        })
        print(f"[PredictInitial] OK uid={uid} item={event.params['itemId']} days={pred_days}")
    except Exception as e:
        print(f"[PredictInitial][ERROR] {e}")
        ref.update({
            "predictionStatus": f"error model load: {e}",
            "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
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
        db.collection("users").document(uid)
        .collection("sensor_data").document("history")
        .collection("entries")
    )
    history_entries.add({
        "temperature": temperature,
        "humidity": humidity,
        "source": "iot-latest",
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    # Optional: trim history agar hemat
    try:
        old = (
            history_entries.order_by("createdAt", direction=firestore.Query.DESCENDING)
            .offset(1000).limit(100).stream()
        )
        batch = db.batch()
        cnt = 0
        for doc in old:
            batch.delete(doc.reference)
            cnt += 1
        if cnt:
            batch.commit()
    except Exception as e:
        print(f"[SensorHistory][WARN] trim failed: {e}")


# ===============================
# Trigger: Re-predict saat sensor latest berubah
# ===============================
@firestore_fn.on_document_updated(document="users/{uid}/sensor_data/latest", memory=options.MemoryOption.MB_512)
def on_sensor_data_update_and_repredict(event: firestore_fn.Event[firestore.DocumentSnapshot]):
    uid = event.params["uid"]
    try:
        booster = _load_booster_if_needed()
        db = firestore.client()
        items_ref = db.collection("users").document(uid).collection("items")

        total_updated = 0
        for item in items_ref.stream():
            try:
                df = _build_features_for_item(uid, item)
                pred_days = _predict_days(booster, df)
                item.reference.update({
                    "predictedShelfLife": pred_days,
                    "predictionStatus": "ok",
                    "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                })
                total_updated += 1
            except Exception as ie:
                item.reference.update({
                    "predictionStatus": f"error model load: {ie}",
                    "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"[RePredictOnSensor][ITEM ERROR] uid={uid} item={item.id} err={ie}")

        print(f"[RePredictOnSensor] uid={uid} updated items: {total_updated}")
    except Exception as e:
        print(f"[RePredictOnSensor][FATAL] {e}")


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
                    df = _build_features_for_item(uid, item)
                    pred_days = _predict_days(booster, df)
                    item.reference.update({
                        "predictedShelfLife": pred_days,
                        "predictionStatus": "ok",
                        "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    total_updated += 1
                except Exception as ie:
                    item.reference.update({
                        "predictionStatus": f"error model load: {ie}",
                        "predictionUpdatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    print(f"[UpdateAll][ITEM ERROR] uid={uid} item={item.id} err={ie}")

        print(f"[UpdateAll] Done. Updated items: {total_updated}")
    except Exception as e:
        print(f"[UpdateAll][FATAL] {e}")