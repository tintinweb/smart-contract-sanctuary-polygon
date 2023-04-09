/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract GaslessTransaction {

    mapping(address => uint256) balances;
    
    // Event to notify when a transfer is made
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    // Function to transfer tokens
    function transfer(address to, uint256 amount) public {
        require(amount > 0, "Amount should be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Transfer tokens from sender to receiver
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // Emit Transfer event
        emit Transfer(msg.sender, to, amount);
    }
    
    // Function to allow for gasless transactions
    function gaslessTransfer(address to, uint256 amount, uint256 nonce, bytes memory signature) public {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, to, amount, nonce, address(this)));
        address signer = recoverSigner(message, signature);
        
        // Verify the signature
        require(signer == msg.sender, "Invalid signature");
        
        // Transfer tokens from sender to receiver
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // Emit Transfer event
        emit Transfer(msg.sender, to, amount);
    }
    
    // Function to recover the signer from a signed message
    function recoverSigner(bytes32 message, bytes memory signature) internal pure returns (address) {
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