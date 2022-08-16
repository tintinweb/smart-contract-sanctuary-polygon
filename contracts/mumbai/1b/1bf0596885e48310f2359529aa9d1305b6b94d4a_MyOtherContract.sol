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

    struct MetaTransactionData {
        // Signer of meta-transaction. On whose behalf to execute the MTX.
        address payable signer;
        // Required sender, or NULL for anyone.
        address sender;
        // Minimum gas price.
        uint256 minGasPrice;
        // Maximum gas price.
        uint256 maxGasPrice;
        // MTX is invalid after this time.
        uint256 expirationTimeSeconds;
        // Nonce to make this MTX unique.
        uint256 salt;
        // Encoded call data to a function on the exchange proxy.
        bytes callData;
        // Amount of ETH to attach to the call.
        uint256 value;
        // ERC20 fee `signer` pays `sender`.
        address feeToken;
        // ERC20 fee amount.
        uint256 feeAmount;
    }

    function getMetaTransactionHash(MetaTransactionData memory mtx)
        public
        view
        returns (bytes32 mtxHash)
    {
        return keccak256(abi.encode(
            MTX_EIP712_TYPEHASH,
            mtx.signer,
            mtx.sender,
            mtx.minGasPrice,
            mtx.maxGasPrice,
            mtx.expirationTimeSeconds,
            mtx.salt,
            keccak256(mtx.callData),
            mtx.value,
            mtx.feeToken,
            mtx.feeAmount
        ));
    }

    function getBlockNumber()
        public
        view
        returns (uint256)
    {
        return block.number;
    }
}