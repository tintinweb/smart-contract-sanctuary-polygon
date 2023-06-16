// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Receiver.sol)

pragma solidity ^0.8.0;

interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Spender.sol)

pragma solidity ^0.8.0;

interface IERC1363Spender {
    /*
     * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
     * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
     */

    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
     *  unless throwing
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC1363Receiver.sol";
import "./IERC1363Spender.sol";

contract MockERC1363Receiver is IERC1363Receiver, IERC1363Spender {
    event ApprovalReceived(address token, address owner, uint256 value, bytes data);
    event TransferReceived(
        address token,
        address operator,
        address from,
        uint256 value,
        bytes data
    );

    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        emit ApprovalReceived(msg.sender, owner, value, data);

        if (data.length > 0) {
            bool shouldRevert = abi.decode(data, (bool));

            if (shouldRevert) {
                revert("revert requested");
            }
        }

        return IERC1363Spender.onApprovalReceived.selector;
    }

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        emit TransferReceived(msg.sender, operator, from, value, data);

        if (data.length > 0) {
            bool shouldRevert = abi.decode(data, (bool));

            if (shouldRevert) {
                revert("revert requested");
            }
        }

        return IERC1363Receiver.onTransferReceived.selector;
    }
}