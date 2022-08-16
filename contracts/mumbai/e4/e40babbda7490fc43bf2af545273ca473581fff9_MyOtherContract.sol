// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

contract MyOtherContract {
    /// @dev Name of this feature.
    string public constant FEATURE_NAME = "MyOtherContract";
    bytes32 public immutable MTX_EIP712_TYPEHASH = keccak256(
        "MyOtherContract("
            "address signer,"
            "address sender,"
            "uint256 expirationTimeSeconds,"
            "uint256 salt,"
            "bytes callData,"
            "uint256 value"
        ")"
    );

    function getBlockNumber()
        public
        view
        returns (uint256)
    {
        return block.number;
    }
}