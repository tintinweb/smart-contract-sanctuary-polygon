/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

pragma solidity ^0.8.0;

contract FlashLoan {
    string public constant name = "Flash Loan";
    string public constant symbol = "FSH";
    uint256 public constant totalSupply = 1000000000000;
    uint8 public constant decimal = 6;
    uint256 public constant burnPercentage = 2;
    address payable public charityWallet;
    uint256 public constant charityPercentage = 2;
    address payable public transactionFeeWallet;
    uint256 public constant transactionFeePercentage = 6;

    mapping(address => uint256) public balances;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address payable _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, "Not enough balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        uint256 burnAmount = (_value * burnPercentage) / 100;
        uint256 charityAmount = (_value * charityPercentage) / 100;
        uint256 transactionFeeAmount = (_value * transactionFeePercentage) / 100;

        charityWallet.transfer(charityAmount);
        transactionFeeWallet.transfer(transactionFeeAmount);

        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}