// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Opentwit {
    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct twit {
        address twiter;
        uint256 id;
        string twitTxt;
        string twitimg;
    }

    event twitCreated(
        address twiter,
        uint256 id,
        string twitTxt,
        string twitimg
    );

    mapping(uint256 => twit) Twits;

    function addTwit(string memory twitTxt, string memory twitimg)
        public
        payable
    {
        require(msg.value == (0.0001 ether), "Please submit 0.0001 Matic");
        twit storage newTwit = Twits[counter];
        newTwit.twitTxt = twitTxt;
        newTwit.twitimg = twitimg;
        newTwit.twiter = msg.sender;
        newTwit.id = counter;
        emit twitCreated(msg.sender, counter, twitTxt, twitimg);
        counter++;

        payable(owner).transfer(msg.value);
    }

    function getTwit(uint256 id)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(id < counter, "No such Twit");

        twit storage t = Twits[id];
        return (t.twitTxt, t.twitimg, t.twiter);
    }
}