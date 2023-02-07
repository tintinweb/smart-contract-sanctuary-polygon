/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract BookingContract{

    struct User{
        bool isApproved;
        bool isRegisterred;
        bool rideStarted;
        uint rideCount;
        uint rideFee;
    }
  address public owner;
  address public bookingAgent;
  uint256 public rideFee = 0.01 ether;
  uint256 public bookingAgentFee = 10; //10 percent of the ride will go to the agent

 mapping (address => User) public _user;

  constructor (address _bookingAgent){
      bookingAgent = _bookingAgent;
      owner = msg.sender;
  }

 modifier onlyOwner() {
        require(owner == msg.sender, "only owner can this function");
        _;
    }

 receive() payable  external {}

  function booking() public  payable {
      require(!_user[msg.sender].isRegisterred, "You already registerred");
      require(msg.value == rideFee, "Not enough rideFee to get register");
      _user[msg.sender].isRegisterred = true;
      _user[msg.sender].rideFee += msg.value;
  }
  function aproveClient(address client)external{
     require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
     require(_user[client].isRegisterred != false, "Client is not registerred");
     require(_user[client].isApproved != true, "Client is already approved");
      _user[client].isApproved = true;
      _user[client].rideStarted = true;
      _user[client].rideCount++;
  }
  
  function finishRide(address _client)external{
    require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
    require(_user[_client].rideStarted || _user[_client].isApproved, "Client's ride is not started yet");
    uint fee = (_user[_client].rideFee * bookingAgentFee)/100;
     payable(bookingAgent).transfer(fee/1e18);
      _user[_client].rideFee = 0;
     _user[_client].isApproved = false;
     _user[_client].rideStarted = false;
      
  }
   function changeRideFee(uint256 _newrideFee)external onlyOwner{
         rideFee = _newrideFee;
  }
  function changeBookingAgent(address _newbookingAgent)external onlyOwner{
         bookingAgent = _newbookingAgent;
  }
   function changeBookingAgentFee(uint256 _newbookingAgentFee)external onlyOwner{
         bookingAgentFee = _newbookingAgentFee;
  }
   function withdrawEth()external onlyOwner{
        require(address(this).balance > 0 , "Not enough balance to withdraw");
         payable(msg.sender).transfer(address(this).balance);
  }
  function getContractBalance()external view returns(uint){
      return (address(this).balance);
      
  }
}