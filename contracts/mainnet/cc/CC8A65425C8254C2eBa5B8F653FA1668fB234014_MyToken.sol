/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

pragma solidity ^0.6.0;

// This is a sample ERC-20 token contract
// Replace "MyToken" with the name of your token
// Replace "MYT" with the symbol of your token
// Replace "18" with the number of decimal places your token uses
// You can also customize other aspects of the contract as needed

contract MyToken {
    // Set the name, symbol, and number of decimal places for the token
    string public name = "FLOWER";
    string public symbol = "FLR";
    uint8 public decimals = 18;

    // Set the total supply of the token
    uint256 public totalSupply = 10000000 * (10 ** uint256(decimals));

    // Keep track of the balance of each address
    mapping(address => uint256) public balanceOf;

    // Event that is emitted when the balance of an address changes
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Initialize the contract with the total supply of tokens being assigned to the contract owner
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    // Function to transfer tokens from one address to another
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
}