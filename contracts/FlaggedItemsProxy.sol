pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IBridge} from "./IBridge.sol";
import {IFlaggedItemConsumer} from "./IFlaggedItemConsumer.sol";
import {FlaggedItemsDecoder} from "./FlaggedItemsDecoder.sol";

/// @title FlaggedItemsProxy contract
/// @notice Contract for working with BandChain's flagged items oracle-script
contract FlaggedItemsProxy is Ownable, ReentrancyGuard {
    using FlaggedItemsDecoder for bytes;
    using Address for address;

    uint8 public minCount;
    uint8 public askCount;
    uint64 public oracleScriptID;

    IBridge public bridge;
    IFlaggedItemConsumer public consumer;

    event SetBridge(address indexed newBridge);
    event SetFlaggedItemConsumer(address indexed newConsumer);
    event SetOracleScriptID(uint64 newOID);
    event SetMinCount(uint8 newMinCount);
    event SetMinAsk(uint8 newMinAsk);

    constructor(
        uint8 _minCount,
        uint8 _askCount,
        uint64 _oracleScriptID,
        IBridge _bridge,
        IFlaggedItemConsumer _consumer
    ) {
        minCount = _minCount;
        askCount = _askCount;
        oracleScriptID = _oracleScriptID;
        bridge = _bridge;
        consumer = _consumer;

        emit SetMinCount(_minCount);
        emit SetMinAsk(_askCount);
        emit SetOracleScriptID(_oracleScriptID);
        emit SetBridge(address(_bridge));
        emit SetFlaggedItemConsumer(address(_consumer));
    }

    function setMinCount(uint8 _minCount) external onlyOwner {
        minCount = _minCount;
        emit SetMinCount(_minCount);
    }

    function setMinAsk(uint8 _askCount) external onlyOwner {
        askCount = _askCount;
        emit SetMinAsk(_askCount);
    }

    function setOracleScriptID(uint64 _oracleScriptID) external onlyOwner {
        oracleScriptID = _oracleScriptID;
        emit SetOracleScriptID(_oracleScriptID);
    }

    function setBridge(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit SetBridge(address(_bridge));
    }

    function setFlaggedItemConsumer(IFlaggedItemConsumer _consumer) external onlyOwner {
        consumer = _consumer;
        emit SetFlaggedItemConsumer(address(_consumer));
    }

    function relayProof(bytes calldata _proof) external nonReentrant {
        // Verify proof using Bridge and extract the result
        IBridge.Result memory res = bridge.relayAndVerify(_proof);

        // check oracle script id, min count, ask count
        require(res.oracleScriptID == oracleScriptID, "Oracle Script ID not match");
        require(res.minCount == uint8(minCount), "Min Count not match");
        require(res.askCount == uint8(askCount), "Ask Count not match");

        // Check that the request on Band was successfully resolved
        require(res.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS, "Request not successfully resolved");

        // Check if sender is a worker
        FlaggedItemsDecoder.Params memory params = res.params.decodeParams();
        // Extract the task's result
        bool[] memory flaggedStatus = res.result.decodeResult();

        require(params.itemIds.length == flaggedStatus.length, "Size of flags and itemIds not match");

        consumer.submitFlaggedItems(
            uint256(res.resolveTime),
            params.collection,
            params.itemIds,
            flaggedStatus
        );
    }
}
