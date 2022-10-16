/**
 *Submitted for verification at polygonscan.com on 2022-10-15
*/

pragma solidity ^0.8.0;

contract ShopPack{
    address payable immutable receiver;
    event BuyShipReceived(address from, uint amount);
    event BuySlotReceived(address from, uint amount);

    constructor(address payable _receiver){
        receiver = _receiver;
    }

    function buyShip(uint amount) payable external{
        receiver.transfer(amount);
        emit BuyShipReceived(msg.sender, amount);
    }

    function buySlot(uint amount) payable external{
        receiver.transfer(amount);
        emit BuySlotReceived(msg.sender, amount);
    }
}