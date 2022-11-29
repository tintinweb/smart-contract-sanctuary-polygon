// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ModuleBase.sol";

contract LandBlindBoxData is ModuleBase {
    uint32 internal roundIndex;

    struct NodeData {
        address account;
        uint256 amount;
        uint8 count;
        uint8 bingoNum;
        uint256 utoPrice;
    }

    struct PrizeNumber {
        uint8 n1;
        uint8 n2;
        uint8 n3;
        uint8 n4;
        uint8 n5;
    }

    //container of all nodes
    //key: roundIndex => NodeData
    mapping(uint32 => NodeData) internal mapNodeData;

    mapping(uint32 => PrizeNumber) internal mapPrizeNumber;

    constructor(address _auth, address _moduleMgr)
        ModuleBase(_auth, _moduleMgr)
    {}

    function getCurrentRoundIndex() external view returns (uint32 res) {
        res = roundIndex;
    }

    function increaseRoundIndex(uint32 n) external onlyCaller {
        roundIndex += n;
    }

    function newNodeData(
        address account,
        uint256 amount,
        uint8 count,
        uint8 bingoNum,
        uint256 utoPrice
    ) external onlyCaller {
        mapNodeData[roundIndex] = NodeData(
            account,
            amount,
            count,
            bingoNum,
            utoPrice
        );
    }

    function setPrizeNumber(uint32 roundNumber, uint8 n1, uint8 n2, uint8 n3, uint8 n4, uint8 n5) external onlyCaller {
        mapPrizeNumber[roundNumber] = PrizeNumber(n1, n2, n3, n4, n5);
    }

    function getNodeData(uint32 roundNumber)
        external
        view
        returns (
            bool res,
            address account,
            uint256 amount,
            uint8 count,
            uint8 bingoNum,
            uint256 utoPrice
        )
    {
        if (mapNodeData[roundNumber].count > 0) {
            res = true;
            account = mapNodeData[roundNumber].account;
            amount = mapNodeData[roundNumber].amount;
            count = mapNodeData[roundNumber].count;
            bingoNum = mapNodeData[roundNumber].bingoNum;
            utoPrice = mapNodeData[roundNumber].bingoNum;
        }
    }

    function getPrizeNumbers(uint32 roundNumber)
        external
        view
        returns (
            bool res,
            uint8[] memory positions
        )
    {
        if (mapPrizeNumber[roundNumber].n1 > 0) {
            res = true;
            positions = new uint8[](5);
            positions[0] = mapPrizeNumber[roundNumber].n1;
            positions[1] = mapPrizeNumber[roundNumber].n2;
            positions[2] = mapPrizeNumber[roundNumber].n3;
            positions[3] = mapPrizeNumber[roundNumber].n4;
            positions[4] = mapPrizeNumber[roundNumber].n5;
        }
    }
}