// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

contract Account {
    string public name;

    string public symbol;

    mapping(address => bool) public isOwner;

    uint256 public numOfConfirmations;

    uint256 public ownerCount;

    uint256 public nonce;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _owners,
        uint256 _numOfConfirmations
    ) {
        name = _name;
        symbol = _symbol;

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }

        numOfConfirmations = _numOfConfirmations;

        ownerCount += _owners.length;
    }

    function sign(address _to, uint256 _nonce, bytes memory _data) external pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_nonce, _to, _data));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(hash);

        return ethSignedMessageHash;
    }

    function approve(address _to, uint256 _nonce, bytes memory _data, bytes[] memory _signatures) private returns (bool success, bytes memory data) {
            uint256 approvals = 0;
        
            bytes32 hash = keccak256(abi.encodePacked(_nonce, _to, _data));
            bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(hash);

            require(nonce == _nonce, "Wallet: nonce is incorrect");

            for (uint256 i = 0; i < _signatures.length; i++) {
                address signer = ECDSA.recover(ethSignedMessageHash, _signatures[i]);
                require(isOwner[signer], "Wallet: signer is not owner");

                approvals += 1;
            }

            nonce += 1;

            require(approvals >= numOfConfirmations);

            return _to.call{gas: 3000000}(_data);
    }
}