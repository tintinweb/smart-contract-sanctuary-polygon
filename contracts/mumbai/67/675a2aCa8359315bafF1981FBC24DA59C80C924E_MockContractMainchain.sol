// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISyncProtocol {
    event LogMessagePublished(address indexed sender, bytes payload);

    event DepositSideChain(uint256 amount, address token, address receiver);

    // Publish a message to be attested by the SyncProtocol network
    function pushData(bytes memory payload) external payable;

    // Publish a message to be attested by the SyncProtocol network
    function pushMeta(string memory contractAbi, bool emitter)
        external
        returns (uint256);

    function depositSideChain(uint256 amount, address token) external;

    function syncData(
        uint256 nonce,
        address from, // from contract address
        address sender,
        string memory functionSignature,
        bytes memory payload,
        address destination,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "../interfaces/ISyncProtocol.sol";

contract MockContractMainchain {
    address public syncProtocol;

    function setSyncProtocol(address _newAddr) external {
        syncProtocol = _newAddr;
    }

    function pushData(bytes memory payload) external {
        ISyncProtocol(syncProtocol).pushData(payload);
    }
}