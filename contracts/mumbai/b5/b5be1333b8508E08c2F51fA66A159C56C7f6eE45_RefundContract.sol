/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// File: contracts/RefundContrac.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RefundContract{
    
    uint256 public value;
    uint256 deadline;
    address payable public seller;
    address payable public buyer;

    mapping(address => bool) public isReceived;
    mapping(address => bool) public isRequest;
    mapping(address => bool) public isPurchase;

    event received(address indexed user, uint valueOrder, uint timeStart);
    event requestRefund(address indexed user, uint amount, uint timeStart);

    enum State { created, locked, pending, hold1, hold2, release, inactive}
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value;
    }
    
    error InvalidState();
    error OnlyBuyer();
    error OnlySeller();

    modifier inState(State state_){
        if(state != state_){
            revert InvalidState();
        }
        _;
    }

    modifier onlySeller(){
        if(msg.sender != seller){
            revert OnlySeller();
        }
        _;
    }

    modifier onlyBuyer(){
        if(msg.sender != buyer){
            revert OnlyBuyer();
        }
        _;
    }

    function createValue(uint256 _value) external onlySeller {
        value = _value * (10**18);
    }

    function confirmPurchase() external inState(State.created) payable{
        require (msg.value == value, "Please send exactly purchase amount");
        buyer = payable(msg.sender);
        state = State.locked;
        isPurchase[msg.sender] = true;
    }

    function confirmReceived() external onlyBuyer inState(State.locked){
        require(isPurchase[msg.sender] == true, "You have not purchase anything");
        state = State.pending;
        isReceived[msg.sender] = true;
        emit received(msg.sender, value, block.timestamp);
    }

    function buyerDenyRefund() external onlyBuyer inState(State.pending){
        require(isReceived[msg.sender] == true, "Your order have not arrived so you can not request refund");
        state = State.release;
    }

    function buyerConfirmRefund() external onlyBuyer inState(State.pending){
        require(isReceived[msg.sender] == true, "Your order have not arrived so you can not request refund");
        state = State.hold1;
        //Set deadline for seller
        deadline = block.timestamp + 3 days;
        isRequest[msg.sender] = true;
        emit requestRefund(msg.sender,value, block.timestamp);
    }

    function sellerNotResponse() external onlyBuyer inState(State.hold1){
        require(isRequest[msg.sender] == true, "Please send request refund first");
        require(block.timestamp < deadline, "Please wait for the seller response within 1-3 days");
        buyer.transfer(value);
        state = State.inactive;
    }

    function sellerDenyRefund() external onlySeller inState(State.hold1){
        require(block.timestamp >= deadline, "Expired for handle request");
        state = State.release;
    }

    function sellerConfirmRefund() external onlySeller inState(State.hold1){
        require(block.timestamp >= deadline, "Expired for handle request");
        state = State.hold2;
    }

    function sellerConfirmProductReturn() external onlySeller inState(State.hold2){
        state = State.inactive;
        buyer.transfer(value);
        seller.transfer(value);
    }

    function paySeller() external onlySeller inState(State.release){
        state = State.inactive;
        seller.transfer(address(this).balance);
    }

    function abort() external onlySeller inState(State.created){
        state = State.inactive;
        seller.transfer(address(this).balance);
    }
}