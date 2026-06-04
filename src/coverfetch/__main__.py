import argparse
import os

import uvicorn


def parse_args():
    parser = argparse.ArgumentParser(description="Run the coverfetch API server")
    parser.add_argument(
        "--host",
        default=os.environ.get("COVERFETCH_HOST", "127.0.0.1"),
        help="Host to bind to",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("COVERFETCH_PORT", "8000")),
        help="Port to bind to",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    uvicorn.run("coverfetch.app:app", host=args.host, port=args.port)


if __name__ == "__main__":
    main()
