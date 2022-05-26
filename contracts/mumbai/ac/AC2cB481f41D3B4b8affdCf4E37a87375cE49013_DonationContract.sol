/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

pragma solidity^0.8.7;

contract DonationContract{
    address public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    event Donate(
        address from,
        uint256 amount
    );

    function newDonation() public payable{
        (bool success,) = owner.call{value:msg.value}("");
        require(success,"Donation failed");
        emit Donate(
            msg.sender,
            msg.value/1000000000000000000
        );
    }
}