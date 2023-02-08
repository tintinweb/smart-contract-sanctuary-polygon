/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract BookingContract{

    struct User{
        bool isApproved;
        bool isBooked;
        bool rideStarted;
        uint rideCount;
        uint rideFee;
    }
  address public owner;
  address public bookingAgent;
  uint256 public rideFee = 0.01 ether;
  uint256 public bookingAgentFee = 10; //10 percent of the ride will go to the agent

 mapping (address => User) public _user;
 event _booking(address indexed user, bool indexed _value);
 event _approved(address indexed user, uint256 indexed rideCount, bool indexed _value);
 event _rideFinished(address indexed user,uint256 indexed rideCount, bool indexed _value);
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
      require(!_user[msg.sender].isBooked, "You already registerred");
      require(msg.value == rideFee, "Not enough rideFee to get register");
      _user[msg.sender].isBooked = true;
      _user[msg.sender].rideFee += msg.value;
      emit _booking(msg.sender, true);
  }
  function aproveClient(address client)external{
     require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
     require(_user[client].isBooked != false, "Client is not registerred");
     require(_user[client].isApproved != true, "Client is already approved");
      _user[client].isApproved = true;
      _user[client].rideStarted = true;
      _user[client].rideCount++;
      emit _approved(client, _user[client].rideCount, true);
  }
  
  function finishRide(address _client)external{
    require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
    require(_user[_client].rideStarted || _user[_client].isApproved, "Client's ride is not started yet");
    uint fee = (_user[_client].rideFee * bookingAgentFee)/100;
     payable(bookingAgent).transfer(fee/1e18);
      _user[_client].rideFee = 0;
     _user[_client].isApproved = false;
     _user[_client].rideStarted = false;
     _user[_client].isBooked = false;
    emit _rideFinished(_client, _user[_client].rideCount, true);
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