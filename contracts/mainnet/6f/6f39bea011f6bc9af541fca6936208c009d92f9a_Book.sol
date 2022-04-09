/**
 *Submitted for verification at polygonscan.com on 2022-04-09
*/

// File: contracts/BlockBook.sol

pragma solidity 0.8.0;


contract Book{

    address admin;
    event new_paragraph(string paragraph, uint long);
    string [] chapter;
    uint public long;
    uint public price_per_letters;

    constructor() {
        admin = msg.sender;
    }

    function Change_Price(uint _price) public {
        require(msg.sender == admin);
        price_per_letters = _price;
    }
    function Change_admin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    function add(string memory _paragraph) public payable {
        require(msg.value >= price_per_letters);
        long += bytes(_paragraph).length;
        chapter.push(_paragraph);
        emit new_paragraph(_paragraph, long);
    }

    function withdraw() public payable {
        require(msg.sender == admin);
        require(address(this).balance>0);
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner"); 
    }
}