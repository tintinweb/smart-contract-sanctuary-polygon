// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SmartWallet {
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    struct Request {
        uint64 nonce;
        uint64 expires;
        uint256 refund;
        Call[] calls;
    }

    address public owner;
    uint64 public nonce;

    constructor(address _owner) {
        owner = _owner;
        nonce = 0;
    }

    // Validate request parameters
    function isValidRequest(Request calldata _data, bytes memory _signature)
        external
        view
        returns (bool)
    {
        return _isValidRequest(_data, _signature);
    }

    // Execute arbitrary signed transaction
    function execute(Request calldata _data, bytes memory _signature)
        external
        payable
    {
        require(_isValidRequest(_data, _signature), "Wallet: Invalid request");

        // Update nonce
        nonce = _data.nonce + 1;

        // Execute calls
        bool _success;
        bytes memory _result;
        for (uint i = 0; i < _data.calls.length; i++) {
            Call memory call = _data.calls[i];
            (_success, _result) = call.to.call{value: call.value}(call.data);
            require(_success, "Wallet: Call failed");
        }
    }

    function _isValidRequest(Request calldata _data, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        // Check signature
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _hash = keccak256(
            abi.encodePacked(prefix, keccak256(abi.encode(_data)))
        );
        require(_signature.length == 65, "Wallet: invalid signature length");
        address signer = _recoverSigner(_hash, _signature, 0);
        require(owner == signer, "Wallet: Invalid signer");

        // Check nonce
        require(nonce == _data.nonce, "Wallet: Invalid nonce");

        // Check expiration
        require(block.timestamp < _data.expires, "Wallet: Request expired");

        // Check targets
        for (uint i = 0; i < _data.calls.length; i++) {
            Call memory call = _data.calls[i];
            require(call.to != address(0), "Wallet: Invalid call");
        }

        return true;
    }

    function hashToSign(Request calldata _data)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_data));
    }

    receive() external payable {
        // Just accept received ether
    }

    fallback() external payable {
        // Just accept received ether
    }

    function _recoverSigner(
        bytes32 _signedHash,
        bytes memory _signatures,
        uint _index
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20, mul(0x41, _index))))
            s := mload(add(_signatures, add(0x40, mul(0x41, _index))))
            v := and(
                mload(add(_signatures, add(0x41, mul(0x41, _index)))),
                0xff
            )
        }
        require(v == 27 || v == 28, "Crypto: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Crypto: ecrecover returned 0");
        return recoveredAddress;
    }
}