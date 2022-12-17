// Developer : Soheil Vafaei (web3.0heil)👽
// About The Collection: This NFT Collection project was created for a training service ticket //

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract MyToken is ERC721 {

    uint256 MAX_TICKETS = 5;
    uint256 TicketPrice = 100000000000000000 wei;

    bool _saleOpen;

    modifier saleOpen ()
    {
        require(_saleOpen == true);
        _;
    }

    function setMaxTicket (uint256 _maxTicket) public onlyOwner
    {
        uint256 maxTicket_;
        MAX_TICKETS = maxTicket_;
        require(MAX_TICKETS >= 0 , "dev : The total number of tickets can not be less than 0");
        require(_maxTicket < maxTicket_, "dev : The total number of tickets should not be less");

        MAX_TICKETS = _maxTicket;
    }

    function mintTicket () public payable saleOpen
    {
        require(MAX_TICKETS >= mintCount, "dev : You can not mint because the number of tickets is over");
        require(msg.value == TicketPrice, "dev : Value is over or under price.");

        _mint(msg.sender,mintCount);
    }

    function setSaleStatus (bool status) public onlyOwner
    {
        _saleOpen = status;
    }
}