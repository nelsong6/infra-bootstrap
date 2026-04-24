import os


class Config:
    entra_tenant_id: str
    entra_audience: str
    entra_instance: str
    github_app_id: str
    github_app_installation_id: str
    github_app_private_key: str
    port: int

    def __init__(self) -> None:
        self.entra_tenant_id = _req("ENTRA_TENANT_ID")
        self.entra_audience = _req("ENTRA_AUDIENCE")
        self.entra_instance = os.environ.get("ENTRA_INSTANCE", "https://login.microsoftonline.com/").rstrip("/") + "/"
        self.github_app_id = _req("GITHUB_APP_ID")
        self.github_app_installation_id = _req("GITHUB_APP_INSTALLATION_ID")
        self.github_app_private_key = _req("GITHUB_APP_PRIVATE_KEY")
        self.port = int(os.environ.get("PORT", "8080"))

    @property
    def issuer(self) -> str:
        return f"{self.entra_instance}{self.entra_tenant_id}/v2.0"

    @property
    def jwks_uri(self) -> str:
        return f"{self.entra_instance}{self.entra_tenant_id}/discovery/v2.0/keys"


def _req(name: str) -> str:
    v = os.environ.get(name)
    if not v:
        raise RuntimeError(f"missing env var: {name}")
    return v
