"""Entry point — wires JWT middleware + FastMCP streamable-http + discovery route."""
import json
import logging

from mcp.server.fastmcp import FastMCP
from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.routing import Mount, Route

from .auth import EntraJWTValidator, GitHubAppTokenMinter
from .config import Config
from .github_client import GitHubClient
from .tools import register_tools


class BearerAuthMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, validator: EntraJWTValidator, exempt: set[str]) -> None:
        super().__init__(app)
        self._validator = validator
        self._exempt = exempt

    async def dispatch(self, request: Request, call_next):
        if request.url.path in self._exempt:
            return await call_next(request)
        auth = request.headers.get("Authorization", "")
        if not auth.lower().startswith("bearer "):
            return JSONResponse({"error": "unauthorized"}, status_code=401, headers={"WWW-Authenticate": f'Bearer resource_metadata="{request.url.scheme}://{request.url.netloc}/.well-known/oauth-protected-resource"'})
        token = auth.split(None, 1)[1]
        try:
            self._validator.validate(token)
        except Exception as e:
            logging.warning("jwt validation failed: %s", e)
            return JSONResponse({"error": "invalid_token", "detail": str(e)}, status_code=401)
        return await call_next(request)


def build_app(config: Config) -> Starlette:
    mcp = FastMCP("github-mcp", stateless_http=True)
    gh = GitHubClient(GitHubAppTokenMinter(config))
    register_tools(mcp, gh)

    validator = EntraJWTValidator(config)

    async def oauth_resource_doc(request: Request) -> Response:
        body = {
            "resource": f"{request.url.scheme}://{request.url.netloc}",
            "authorization_servers": [config.issuer],
            "scopes_supported": ["Mcp.Tools.ReadWrite"],
            "bearer_methods_supported": ["header"],
        }
        return Response(json.dumps(body), media_type="application/json")

    async def healthz(_: Request) -> Response:
        return Response("ok", media_type="text/plain")

    return Starlette(
        routes=[
            Route("/.well-known/oauth-protected-resource", oauth_resource_doc),
            Route("/healthz", healthz),
            Mount("/", app=mcp.streamable_http_app()),
        ],
        middleware=[
            Middleware(
                BearerAuthMiddleware,
                validator=validator,
                exempt={"/.well-known/oauth-protected-resource", "/healthz"},
            ),
        ],
    )


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    import uvicorn

    config = Config()
    uvicorn.run(build_app(config), host="0.0.0.0", port=config.port)


if __name__ == "__main__":
    main()
