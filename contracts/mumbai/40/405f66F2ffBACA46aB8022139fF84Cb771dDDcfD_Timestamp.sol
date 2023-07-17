//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./interfaces/ITimestampTracking.sol";

contract Timestamp is ITimestampTracking {

    address public operatorAddress;
    mapping(uint32 => EventSubStageTimestamps[]) public eosIdEventSubStageTimestamps;

    // validate only tracking contract can call
    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Only operator");
        _;
    }

    constructor() {
        operatorAddress = msg.sender;
    }

    //change operator
    function setOperator(address newOperator) public onlyOperator {
        operatorAddress = newOperator;
    }

    // save timestamp by format of struct.
    function addEventSubStageTimestamps(uint32[] memory eosId, EventSubStageTimestamps[] memory data) override external onlyOperator {
        require(eosId.length == data.length, "Invalid length");
        uint256 len = eosId.length;
        for (uint32 i = 0; i < len; i++) {
            eosIdEventSubStageTimestamps[eosId[i]].push(data[i]);
        }
    }

    // verify timestamp
    function batchVerifyTimestamps(Timestamp[] memory data) view override public returns (bool[] memory) {
        bool[] memory output = new bool[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            Timestamp memory tms = data[i];
            uint256 eosLength = eosIdEventSubStageTimestamps[tms.eosId].length;
            for (uint256 j = 0; j < eosLength; j++) {
                EventSubStageTimestamps memory item = eosIdEventSubStageTimestamps[tms.eosId][j];
                if (
                    item.e1.eventSubStage == data[i].eventSubStage &&
                    item.e1.timestamp == data[i].timestamp &&
                    item.e1.field1 == data[i].field1 &&
                    item.e1.field2 == data[i].field2 &&
                    item.e1.field3 == data[i].field3 &&
                    item.e1.field4 == data[i].field4 &&
                    keccak256(abi.encodePacked(item.e1.field5)) == keccak256(abi.encodePacked(data[i].field5)) &&
                    keccak256(abi.encodePacked(item.e1.field6)) == keccak256(abi.encodePacked(data[i].field6)) &&
                    keccak256(abi.encodePacked(item.e1.field7)) == keccak256(abi.encodePacked(data[i].field7)) &&
                    keccak256(abi.encodePacked(item.e1.field8)) == keccak256(abi.encodePacked(data[i].field8)) &&
                    keccak256(abi.encodePacked(item.e1.field9)) == keccak256(abi.encodePacked(data[i].field9))
                ) {
                    output[i] = true;
                }

                if (
                    item.e2.eventSubStage == data[i].eventSubStage &&
                    item.e2.timestamp == data[i].timestamp &&
                    item.e2.field1 == data[i].field1 &&
                    item.e2.field2 == data[i].field2 &&
                    item.e2.field3 == data[i].field3 &&
                    item.e2.field4 == data[i].field4 &&
                    keccak256(abi.encodePacked(item.e2.field5)) == keccak256(abi.encodePacked(data[i].field5)) &&
                    keccak256(abi.encodePacked(item.e2.field6)) == keccak256(abi.encodePacked(data[i].field6)) &&
                    keccak256(abi.encodePacked(item.e2.field7)) == keccak256(abi.encodePacked(data[i].field7)) &&
                    keccak256(abi.encodePacked(item.e2.field8)) == keccak256(abi.encodePacked(data[i].field8)) &&
                    keccak256(abi.encodePacked(item.e2.field9)) == keccak256(abi.encodePacked(data[i].field9))
                ) {
                    output[i] = true;
                }
                if (
                    item.e3.eventSubStage == data[i].eventSubStage &&
                    item.e3.timestamp == data[i].timestamp &&
                    item.e3.field1 == data[i].field1 &&
                    item.e3.field2 == data[i].field2 &&
                    item.e3.field3 == data[i].field3 &&
                    item.e3.field4 == data[i].field4 &&
                    keccak256(abi.encodePacked(item.e3.field5)) == keccak256(abi.encodePacked(data[i].field5)) &&
                    keccak256(abi.encodePacked(item.e3.field6)) == keccak256(abi.encodePacked(data[i].field6)) &&
                    keccak256(abi.encodePacked(item.e3.field7)) == keccak256(abi.encodePacked(data[i].field7)) &&
                    keccak256(abi.encodePacked(item.e3.field8)) == keccak256(abi.encodePacked(data[i].field8)) &&
                    keccak256(abi.encodePacked(item.e3.field9)) == keccak256(abi.encodePacked(data[i].field9))
                ) {
                    output[i] = true;
                }
                if (
                    item.e4.eventSubStage == data[i].eventSubStage &&
                    item.e4.timestamp == data[i].timestamp &&
                    item.e4.field1 == data[i].field1 &&
                    item.e4.field2 == data[i].field2 &&
                    item.e4.field3 == data[i].field3 &&
                    item.e4.field4 == data[i].field4 &&
                    keccak256(abi.encodePacked(item.e4.field5)) == keccak256(abi.encodePacked(data[i].field5)) &&
                    keccak256(abi.encodePacked(item.e4.field6)) == keccak256(abi.encodePacked(data[i].field6)) &&
                    keccak256(abi.encodePacked(item.e4.field7)) == keccak256(abi.encodePacked(data[i].field7)) &&
                    keccak256(abi.encodePacked(item.e4.field8)) == keccak256(abi.encodePacked(data[i].field8)) &&
                    keccak256(abi.encodePacked(item.e4.field9)) == keccak256(abi.encodePacked(data[i].field9))
                ) {
                    output[i] = true;
                }

            }
        }
        return output;
    }

    // get list timestamp by eosid
    function getListTimestampByEOSID(uint32 eosId) public view override returns (EventSubStageTimestamps[] memory) {
        return eosIdEventSubStageTimestamps[eosId];
    }


}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ITimestampTracking {
    struct Timestamp {
        uint64 timestamp;
        uint32 eosId;
        uint32 eventSubStage;
        uint32 field1;
        uint32 field2;
        uint32 field3;
        uint32 field4;
        string field5;
        string field6;
        string field7;
        string field8;
        string field9;
    }

    struct EventSubStageTimestamp {
        uint32 eventSubStage;
        uint64 timestamp;
        uint32 field1;
        uint32 field2;
        uint32 field3;
        uint32 field4;
        string field5;
        string field6;
        string field7;
        string field8;
        string field9;
    }

    struct EventSubStageTimestamps {
        EventSubStageTimestamp e1;
        EventSubStageTimestamp e2;
        EventSubStageTimestamp e3;
        EventSubStageTimestamp e4;
    }

    function addEventSubStageTimestamps(uint32[] memory eosId, EventSubStageTimestamps[] memory data) external;
    function batchVerifyTimestamps(Timestamp[] memory data) view external returns (bool[] memory);
    function getListTimestampByEOSID(uint32 eosId) external view returns (EventSubStageTimestamps[] memory);
}