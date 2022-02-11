pragma solidity ^0.7.0;

import "./DevToken.sol";

contract DevTokenSale {
    // address of admin
    address payable public admin;
    // define the instance of DevToken
    DevToken public devtoken;
    // token price variable
    uint256 public tokenprice;
    // count of token sold variable
    uint256 public totalsold;

    event Sell(address _sender, uint256 _amount);

    // constructor
    // with parameters address of token and token price
    constructor (address _tokenaddress, uint256 _tokenvalue) {
        // define admin
        admin = msg.sender;
        // token price
        tokenprice = _tokenvalue;
        // initialize the contract
        devtoken = DevToken(_tokenaddress);
    }

    // buyTokens function
    function buyTokens(uint256 _totalvalue) public payable {
        // check if the contract has the tokens or not
        require(devtoken.balanceOf(address(this)) >= _totalvalue, "The smart contract don't hold enough tokens.");
        // check if the amount filled by the user is accurate or not
        require(msg.value == _totalvalue * tokenprice, "You are not sending enough ether");
        // transfer the token to the user
        devtoken.transfer(msg.sender, _totalvalue);
        // increase the token sold
        totalsold += _totalvalue;
        // emit sell event for ui
        emit Sell(msg.sender, _totalvalue);
    }
    // end sale
    function endsale() public {
        // check if admin has clicked the function
        require(msg.sender == admin, "You are not the admin");
        // transfer all the remaining tokens to admin
        devtoken.transfer(msg.sender, devtoken.balanceOf(address(this)));
        // transfer all the ethereum to admin and self destruct
        selfdestruct(admin);
    }
}