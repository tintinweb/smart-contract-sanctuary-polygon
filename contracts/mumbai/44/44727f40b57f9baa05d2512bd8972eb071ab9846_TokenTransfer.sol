/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenTransfer {
    mapping(address => bool) public whitelisted;

    constructor() {
        // initialize contract
    }

    function transferBEP20(address token, address recipient, uint256 amount, uint256 nonce, bytes calldata signature) public {
        bytes32 message = keccak256(abi.encodePacked(token, recipient, amount, nonce));
        address signer = recoverSigner(message, signature);
        require(signer == recipient, "Invalid signature");
        require(whitelisted[recipient], "Recipient not whitelisted");

        IBEP20(token).transferFrom(msg.sender, recipient, amount);
    }

    function transferERC20(address token, address recipient, uint256 amount, uint256 nonce, bytes calldata signature) public {
        bytes32 message = keccak256(abi.encodePacked(token, recipient, amount, nonce));
        address signer = recoverSigner(message, signature);
        require(signer == recipient, "Invalid signature");
        require(whitelisted[recipient], "Recipient not whitelisted");

        IERC20(token).transferFrom(msg.sender, recipient, amount);
    }

    function whitelist(address recipient) public {
        whitelisted[recipient] = true;
    }

    function revokeWhitelist(address recipient) public {
        whitelisted[recipient] = false;
    }

    function recoverSigner(bytes32 message, bytes memory signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(message, v, r, s);
    }
}