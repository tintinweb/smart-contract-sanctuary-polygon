/**
 * SPDX-License-Identifier: MIT
 *
 * Simplified implementation of FiatTokenUtil.sol
 * Authors: Samuel Sutch, Amhed Herrera
 */
pragma solidity 0.8.19;

contract SimpleFiatTokenUtil {
    // keccak256("transferWithAuthorization(address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32)")[0:4]
    bytes4 private constant _TRANSFER_WITH_AUTHORIZATION_SELECTOR = 0xe3ee160e;

    address private _fiatToken;
    uint8 public _version;

    event TransferFailed(address indexed authorizer, bytes32 indexed nonce);

    constructor(address fiatToken, uint8 version) {
        _fiatToken = fiatToken;
        _version = version;
    }

    function batchTransferWithAuthorization(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata value,
        uint256[] calldata validAfter,
        uint256[] calldata validBefore,
        bytes32[] calldata nonce,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256 _gasLimit
    ) public {
        require(
            from.length == to.length &&
                to.length == value.length &&
                value.length == validAfter.length &&
                validAfter.length == validBefore.length &&
                validBefore.length == nonce.length &&
                nonce.length == v.length &&
                v.length == r.length &&
                r.length == s.length,
            "FiatTokenUtil: parameter length mismatch"
        );

        for (uint256 i = 0; i < from.length; i++) {
            bytes memory data = abi.encodeWithSelector(
                _TRANSFER_WITH_AUTHORIZATION_SELECTOR,
                from[i],
                to[i],
                value[i],
                validAfter[i],
                validBefore[i],
                nonce[i],
                v[i],
                r[i],
                s[i]
            );

            (bool success, ) = _fiatToken.call{gas: _gasLimit}(data);
            
            if (!success) {
                emit TransferFailed(from[i], nonce[i]);
            }
        }
    }
}