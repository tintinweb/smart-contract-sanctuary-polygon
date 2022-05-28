/**
 *Submitted for verification at polygonscan.com on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PrismaMovie {
    address public owner;
    address public seller = 0x4001d9D646bB0f6545a5515c942FdE2Da367374D;
    uint256 public transactionIds = 0;
    event BuyMovie(address from, string to, string film);

    constructor() {
        owner = msg.sender;
    }

    struct Movie {
        address from;
        string to;
        string film;
        uint256 time;
        uint256 price;
    }

    mapping(uint256 => Movie) public Histories;

    //buy with credit card
    function buyMovie(
        string memory  _buyer,
        string memory _film
    ) public payable {
        require(compareTwoStrings(_buyer, "") == false, " can't be null");
        require(
            compareTwoStrings(_film, "") == false,
            "From can't be null"
        );
        require(msg.value > 0, "Low amount");
        payable(seller).transfer(msg.value);

        Histories[transactionIds] = Movie(
            seller,
            _buyer,
            _film,
            block.timestamp,
            msg.value
        );

        emit BuyMovie(seller, _buyer, _film);
    }

    //get all histories
    function getHistory() public view returns(Movie[] memory histories) {
       for(uint i = 0; i < transactionIds; i++){
           histories[i] = Histories[i];
       }
    }

    //set seller
    function setSeller(address from) public {
        require (msg.sender == owner , "Not owner");
        require (from == address(0) , "Not correct");
        seller = from;
    }

     function compareTwoStrings(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

}