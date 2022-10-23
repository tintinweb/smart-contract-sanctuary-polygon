/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */

contract Token {

    uint8 public decimals;

    function transfer(address _to, uint256 _value) public returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
}

contract MultiTransfer {

    address public owner;
    uint public tokenSendFee; // in wei
    uint public ethSendFee; // in wei


    constructor() payable{
        owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function multiSendEth(address payable[] calldata addresses, uint256[] calldata amounts) public payable returns(bool success){
        uint total = 0;

        for(uint8 i = 0; i < amounts.length; i++){
            total = total + amounts[i];
        }

        //ensure that the ethreum is enough to complete the transaction
        uint requiredAmount = total + ethSendFee * 1 wei; //.add(total.div(100));
        require(msg.value >= (requiredAmount * 1 wei));

        //transfer to each address
        for (uint8 j = 0; j < addresses.length; j++) {
            addresses[j].transfer(amounts[j] * 1 wei);
        }

        //return change to the sender
        if(msg.value * 1 wei > requiredAmount * 1 wei){
            uint change = msg.value - requiredAmount;
            payable(msg.sender).transfer(change * 1 wei);
        }
        return true;
    }

    function getbalance(address addr) public view returns (uint value){
        return addr.balance;
    }

    function deposit() payable public returns (bool){
        return true;
    }

    function withdrawEther(address payable addr, uint amount) public onlyOwner returns(bool success){
        addr.transfer(amount * 1 wei);
        return true;
    }

    function withdrawToken(Token tokenAddr, address _to, uint _amount) public onlyOwner returns(bool success){
        tokenAddr.transfer(_to, _amount );
        return true;
    }

    function multiSendToken(Token tokenAddr, address payable[] calldata addresses, uint256[] calldata amounts) public payable returns(bool success){
        uint total = 0;
        address multisendContractAddress = address(this);
        for(uint8 i = 0; i < amounts.length; i++){
            total = total + amounts[i];
        }

        require(msg.value * 1 wei >= tokenSendFee * 1 wei);

        // check if user has enough balance
        require(total <= tokenAddr.allowance(msg.sender, multisendContractAddress));

        // transfer token to addresses
        for (uint8 j = 0; j < addresses.length; j++) {
            tokenAddr.transferFrom(msg.sender, addresses[j], amounts[j]);
        }
        // transfer change back to the sender
        if(msg.value * 1 wei > (tokenSendFee * 1 wei)){
            uint change = msg.value - tokenSendFee;
            payable(msg.sender).transfer(change * 1 wei);
        }
        return true;

    }

    function setTokenFee(uint _tokenSendFee) public onlyOwner returns(bool success){
        tokenSendFee = _tokenSendFee;
        return true;
    }

    function setEthFee(uint _ethSendFee) public onlyOwner returns(bool success){
        ethSendFee = _ethSendFee;
        return true;
    }

    function destroy (address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
}