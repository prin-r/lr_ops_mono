#!/usr/bin/env python3
import sys
import requests


def main(asset_contract_address, encode_token_ids):
    if len(encode_token_ids) == 0:
        raise ValueError("encode_token_ids can't be empty")

    if len(encode_token_ids) % 64 != 0:
        raise ValueError("Wrong format for encode_token_ids")

    token_ids = []
    while len(encode_token_ids) > 0:
        token_ids.append(int(encode_token_ids[:64], 16))
        encode_token_ids = encode_token_ids[64:]

    """
    res = requests.get(
        "https://api.opensea.io/api/v1/assets",
        params={
            "token_ids": token_ids,
            "asset_contract_address": asset_contract_address,
            "include_orders": "false",
            "format": "json"
        }
    )
    """

    res = requests.get("https://raw.githubusercontent.com/prin-r/ipfs/main/mock_opensea_api.json")
    res.raise_for_status()

    data = res.json()
    token_mapping = {}
    for asset in data["assets"]:
        flag = asset["supports_wyvern"]
        if type(flag) is not bool:
            raise ValueError(f"Flag should be bool but got {flag}")

        token_id = int(asset["token_id"])
        token_mapping[token_id] = asset["supports_wyvern"]

    result = ""
    for t in token_ids:
        if t not in token_mapping:
            raise ValueError(f"Token id not found for {t}")
        result += '1' if token_mapping[t] else '0'

    return result


if __name__ == "__main__":
    try:
        print(main(*sys.argv[1:]))
    except Exception as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
