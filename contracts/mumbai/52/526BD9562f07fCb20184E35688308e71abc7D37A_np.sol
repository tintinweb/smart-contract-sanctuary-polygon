//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "./ERC20.sol";
contract np {
    //var state ...
    mapping (address=> bool) public authority;
    uint timeStart=block.number;
    uint public payment;
    mapping (address=>uint) owning;
    address test = 0x8964d3216B0309e54B8c3D69fc5229A6bA2cD8d8; 
    //function ...
    address token ;

function getBalanceOfToken() public view returns (uint) {
  return IERC20(test).balanceOf(address(this));}

  function getResult() public view returns (uint256) {
    // address test = msg.sender; // use this if you want to get the sender
    // hardcode the sender
    return IERC20(test).balanceOf(msg.sender)/10;}

function getBalanceOfToke(address _token) public {
  token = _token;

}

  function transfer(address recipient,uint amount)public {
    IERC20(test).transfer(recipient,amount);
  }
function setPlayer() public payable{
  require(payment == 1 ether);
  require(owning[msg.sender]< 1);
  payment =msg.value;
  bool allowed=true;
  authority[msg.sender]=allowed;
  owning[msg.sender]++;
}
function getToken()public payable{
    require(authority[msg.sender]==true);
    require(owning[msg.sender]>1);
    address recipient=msg.sender;
    uint amount = 20;
  IERC20(token).transfer(recipient,amount);
}
receive() external payable{setPlayer();}

}