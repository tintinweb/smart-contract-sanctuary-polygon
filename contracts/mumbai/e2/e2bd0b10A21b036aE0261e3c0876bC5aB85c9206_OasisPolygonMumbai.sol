/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owner {
  address public owner;
  uint public immutable timestamp;

  constructor() {
    owner = msg.sender;
    timestamp = block.timestamp;
  }

  modifier isOwner() {
    require(owner == msg.sender, "you are not the Owner");
    _;
  }
}

contract OasisPolygonMumbai is Owner {
  uint OPM;
  uint TotalBalance;
  uint[] numbers;
  string status;

  event numbersAdded(address _by, uint _numbers, uint _timestamp);

  enum state {order, shipped, delivered}

  struct ProductDelivered {
    uint SKU;
    uint timestamp;
    OasisPolygonMumbai.state state;
  }

  struct Account {
    uint Balance;
    uint timestamp;
  }

  struct Voter {
    uint weight;
    bool voted;
    address delegate;
    uint vote;
    uint timestamp;
  }

  mapping(address => Account) Accounts;
  mapping(address => ProductDelivered) _ProductDelivered;
  mapping(address => Voter) Vote;
  mapping(address => mapping(uint => bool)) public nested;

  receive() external payable {
    TotalBalance += msg.value;
    Accounts[msg.sender].Balance += msg.value;
    Accounts[msg.sender].timestamp = block.timestamp;
  }

  function setNested(address _client, uint _i, bool _value) public {
    nested[_client][_i] = _value;
  }

  function setNumbers(uint _numbers) public {
    numbers.push(_numbers);
    emit numbersAdded(msg.sender, _numbers, block.timestamp);
  }

  function setProductDelivered(uint _SKU, address _client) public isOwner {
    _ProductDelivered[_client].SKU = _SKU;
    _ProductDelivered[_client].state = state.order;
    _ProductDelivered[_client].timestamp = block.timestamp;
  }

  function setOrderStateProductDelivered(address _client) public isOwner {
    _ProductDelivered[_client].state = state.order;
    _ProductDelivered[_client].timestamp = block.timestamp;
  }

  function setShippedStateProductDelivered(address _client) public isOwner {
    _ProductDelivered[_client].state = state.shipped;
    _ProductDelivered[_client].timestamp = block.timestamp;
  }

  function setDeliveredStateProductDelivered(address _client) public isOwner {
    _ProductDelivered[_client].state = state.delivered;
  }

  function setVote(uint _weight, bool _voted, address _delegate,  uint _vote) public isOwner {
    Vote[msg.sender].weight = _weight;
    Vote[msg.sender].voted = _voted;
    Vote[msg.sender].delegate = _delegate;
    Vote[msg.sender].vote = _vote;
    Vote[msg.sender].timestamp = block.timestamp;
  }

  function setStatus(string memory _status) public isOwner {
    status = _status;
  }

  function setOPM(uint _OPM) public isOwner {
    OPM = _OPM;
  }

  function getNested(address _client, uint _i) public view returns(bool){
    return nested[_client][_i];
  }

  function  getNumbers() public view returns(uint[] memory) {
    return numbers;
  }

  function getProductDelivered(address _client) public view returns(ProductDelivered memory) {
    return _ProductDelivered[_client];
  }

  function getVote() public view returns(Voter memory) {
    return Vote[msg.sender];
  }

  function getStatus() public view returns(string memory){
    return status;
  }

  function getOPM() public view returns(uint) {
    return OPM;
  }
}