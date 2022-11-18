pragma solidity ^0.8.17;

/// @title Decoder library
/// @notice Library for decoding the OBI-encoded input parameters of a FlaggedItems data request
library FlaggedItemsDecoder {
    using Obi for Obi.Data;

    struct Params {
        address collection;
        uint256[] itemIds;
    }

    struct Result {
        bool[] flaggedStatus;
    }

    function bytesToAddress(bytes memory addressBytes) internal pure returns(address addr) {
        require(addressBytes.length == 20, "DATA_DECODE_INVALID_SIZE_FOR_ADDRESS");
        assembly {
            addr := mload(add(addressBytes, 20))
        }
    }

    /// @notice Decodes the encoded request input parameters
    /// @param encodedParams Encoded paramter data
    function decodeParams(bytes memory encodedParams)
        internal
        pure
        returns (Params memory params)
    {
        Obi.Data memory decoder = Obi.from(encodedParams);
        params.collection = bytesToAddress(decoder.decodeBytes());
        bytes memory encodedItemIds = decoder.decodeBytes();
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");

        uint256 size = encodedItemIds.length >> 5;
        require(size << 5 == encodedItemIds.length, "INVALID_LENGTH_FOR_ENCODE_ITEM_IDS");

        params.itemIds = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 itemId;
            uint256 j = i<<5;
            assembly {
                itemId := mload(add(add(encodedItemIds, 32), j))
            }
            params.itemIds[i] = itemId;
        }
    }

    /// @notice Decodes the encoded data request response result
    /// @param encodedResult Encoded result data
    function decodeResult(bytes memory encodedResult)
        internal
        pure
        returns (bool[] memory flaggedStatus)
    {
        Obi.Data memory decoder = Obi.from(encodedResult);
        bytes memory encodedFlaggedItems = decoder.decodeBytes();
        require(decoder.finished(), "DATA_DECODE_NOT_FINISHED");

        flaggedStatus = new bool[](encodedFlaggedItems.length);
        for (uint256 i = 0; i < encodedFlaggedItems.length; i++) {
            if (encodedFlaggedItems[i] == 0x00) {
                flaggedStatus[i] = false;
            } else if (encodedFlaggedItems[i] == 0x01) {
                flaggedStatus[i] = true;
            } else {
                revert("INVALID_BYTES_FOR_ENCODED_FLAGGED_ITEMS");
            }
        }
    }
}
