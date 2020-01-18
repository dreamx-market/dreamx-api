def etherscan_not_found
  api_response = {
    "status": "0",
    "message": "No records found",
    "result": []
  }
  api_response.convert_keys_to_underscore_symbols!
end

def etherscan_deposits
  api_response = {
    "status": "1",
    "message": "OK",
    "result": [
      {
        "address": "0x7f6a01dcebe266779e00a4cf15e9432cb1423203",
        "topics": [
          "0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7"
        ],
        "data": "0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bfdc3b9a56f7d5c756c5104da016762970160f8200000000000000000000000000000000000000000000000006f05b59d3b2000000000000000000000000000000000000000000000000000066cfe601cede9a65",
        "blockNumber": "0x6c44e7",
        "timeStamp": "0x5e173778",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0x8c55",
        "logIndex": "0x",
        "transactionHash": "0x624c55566e2e3f88e73cb351e6a0f93d0c12bb2ace175a8e073b342c3887ff85",
        "transactionIndex": "0x6"
      },
      {
        "address": "0x7f6a01dcebe266779e00a4cf15e9432cb1423203",
        "topics": [
          "0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7"
        ],
        "data": "0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bfdc3b9a56f7d5c756c5104da016762970160f8200000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000006dc0415ba2909a65",
        "blockNumber": "0x6c44e7",
        "timeStamp": "0x5e173778",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0x7bed",
        "logIndex": "0x1",
        "transactionHash": "0xc6d303147bce126744ea487c86a4f4c7b540b9a12383921e55d90e3dcb6b7a2c",
        "transactionIndex": "0x7"
      }
    ]
  }
  api_response.convert_keys_to_underscore_symbols!
end

def etherscan_approvals
  api_response = {
    "status": "1",
    "message": "OK",
    "result": [
      {
        "address": "0xe62cc4212610289d7374f72c2390a40e78583350",
        "topics": [
          "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
          "0x000000000000000000000000bfdc3b9a56f7d5c756c5104da016762970160f82",
          "0x000000000000000000000000f675cf9c811022a8d934df1c96bb8af884dc92ee"
        ],
        "data": "0x0000000000000000000000000000000000000000000000000de0b6b3a7640000",
        "blockNumber": "0x6d1820",
        "timeStamp": "0x5e234fb9",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xabbc",
        "logIndex": "0x8",
        "transactionHash": "0x9376c0923d9a608d7532203d587f27fa872866a0583a918f2f9067282ad3f097",
        "transactionIndex": "0x2e"
      },
      {
        "address": "0xe62cc4212610289d7374f72c2390a40e78583350",
        "topics": [
          "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
          "0x0000000000000000000000001a8da111ceb99a85823cb0fc0076d6c21aa7e02d",
          "0x000000000000000000000000f675cf9c811022a8d934df1c96bb8af884dc92ee"
        ],
        "data": "0x00000000000000000000000000000000000000000000000029a2241af62c0000",
        "blockNumber": "0x6d1822",
        "timeStamp": "0x5e234ff1",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xabbc",
        "logIndex": "0x7",
        "transactionHash": "0x07a94fbb3f9e0aca0b4d8a2f0cc727f0aaae8ebdd76c9ae20f1b2e31636dfba8",
        "transactionIndex": "0x3f"
      }
    ]
  }
  api_response.convert_keys_to_underscore_symbols!
end