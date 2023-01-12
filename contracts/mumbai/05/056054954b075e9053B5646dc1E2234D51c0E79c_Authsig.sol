// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract Authsig is IERC1271 {
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external override view returns (bytes4) {
        if (owner == msg.sender) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}