// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract Admin {
    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function isAdmin(
        address _address,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 messageHash = prefixed(keccak256(abi.encodePacked(_address)));
        address signer = recoverSigner(messageHash, _signature);
        return signer == admin;
    }

    function recoverSigner(
        bytes32 _messageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        return ecrecover(_messageHash, v, r, s);
    }

    function splitSignature(
        bytes memory _signature
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return (v, r, s);
    }

    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function claim(uint256 _amount, bytes memory _signature) public {
        require(isAdmin(msg.sender, _signature), "Invalid signature");

        address tokenAddress = 0xe2C5fCF777A2B860921116B275951A50e8135EEb;
        uint256 amountInWei = _amount * (10 ** 9); // convert amount to wei

        ERC20 erc20 = ERC20(tokenAddress);
        require(erc20.transfer(msg.sender, amountInWei), "Transfer failed");
    }
}