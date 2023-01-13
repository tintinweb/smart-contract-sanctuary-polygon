// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./interface/ICircuitVerifier.sol";

// this a test
contract CosmosUpdater {

    event ModCircuitVerifier(
        address oldCircuitVerifier,
        address newCircuitVerifier
    );

    struct BlockInfo {
        uint256 height;
        bytes32 blockHash;
        bytes32 validatorHash;
        bytes32 appHash;
    }

    uint256 public currentHeight;

    ICircuitVerifier public circuitVerifier;

    mapping(uint256 => BlockInfo) public blockInfos;

//    constructor(address circuitVerifierAddress) {
//        circuitVerifier = ICircuitVerifier(circuitVerifierAddress);
//    }

    function updateBlock(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[7] calldata inputs
    ) external {
        //        require(
        //            circuitVerifier.verifyProof(a, b, c, inputs),
        //            "verifyProof failed"
        //        );
        BlockInfo memory blockInfo = _parseInput(inputs);
        require(blockInfo.height > currentHeight, "height error");
        blockInfos[blockInfo.height] = blockInfo;
    }

    function _parseInput(uint256[7] memory inputs)
    internal
    pure
    returns (BlockInfo memory)
    {
        BlockInfo memory result;
        uint256 validatorHash = (inputs[1] << 128) | inputs[0];
        result.validatorHash = bytes32(validatorHash);

        uint256 appHash = (inputs[3] << 128) | inputs[2];
        result.appHash = bytes32(appHash);

        result.height = inputs[4];

        uint256 blockHash = (inputs[6] << 128) | inputs[5];
        result.blockHash = bytes32(blockHash);
        return result;
    }

    function setCircuitVerifier(address circuitVerifierAddress) external {
        require(address(circuitVerifier) != circuitVerifierAddress, "Incorrect circuitVerifierAddress");
        emit ModCircuitVerifier(address(circuitVerifier), circuitVerifierAddress);
        circuitVerifier = ICircuitVerifier(circuitVerifierAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICircuitVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view returns (bool);
}