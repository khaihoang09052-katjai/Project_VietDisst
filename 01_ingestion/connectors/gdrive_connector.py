from io import BytesIO
from pathlib import Path
import os
from dotenv import load_dotenv
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")


def get_service(): 
    '''Tạo đối tượng kết nối Google Drive'''
    key_path = Path(os.environ["GOOGLE_SERVICE_ACCOUNT_JSON"])
    if not key_path.is_absolute():
        key_path = ROOT / key_path
    creds = service_account.Credentials.from_service_account_file(
        str(key_path),
        scopes=["https://www.googleapis.com/auth/drive.readonly"],
    )
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def list_files_in_folder(folder_id):
    '''Lấy danh sách các mục trong thư mục'''
    service = get_service()
    files = []
    page_token = None
    while True:
        result = service.files().list(
            q=f"'{folder_id}' in parents and trashed = false",
            fields="nextPageToken, files(id, name, mimeType, modifiedTime)",
            pageSize=1000,
            pageToken=page_token,
            supportsAllDrives=True,
            includeItemsFromAllDrives=True,
        ).execute()
        files.extend(result.get("files", []))
        page_token = result.get("nextPageToken")
        if not page_token:
            return files


def download_file_as_bytes(file_id):
    '''Lấy nội dung file'''
    service = get_service()
    meta = service.files().get(
        fileId=file_id,
        fields="id,name,mimeType,capabilities(canDownload)",
        supportsAllDrives=True,
    ).execute()
    if meta["mimeType"].startswith("application/vnd.google-apps."):
        raise ValueError("File Google-native cần export hoặc API riêng")
    if not meta.get("capabilities", {}).get("canDownload", False):
        raise PermissionError("Tài khoản hiện tại không được tải nội dung file")

    request = service.files().get_media(
        fileId=file_id, supportsAllDrives=True
    )
    buffer = BytesIO()
    downloader = MediaIoBaseDownload(buffer, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    return buffer.getvalue()

if __name__ == "__main__":

    folder_id = os.environ["GDRIVE_FOLDER_ID"]

    files = list_files_in_folder(folder_id)

    print(f"Drive API phản hồi thành công. Tìm thấy {len(files)} mục.")
    for file in files:
        print(f"Name: {file['name']} | ID: {file['id']}")

