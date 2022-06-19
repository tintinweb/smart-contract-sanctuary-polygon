/**
 *Submitted for verification at polygonscan.com on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract movie{
    address owner;
    uint256 tno;

    struct booking{
        uint256 sno;
        address booker;
        int256 persons;
        string date;
        string time;
        int256 screen;
    }

    booking[] tickets;

    constructor(){
        owner = msg.sender;
        tno = 0;
    }

    function book_ticket(int256 _persons, string memory _date, string memory _time, int256 _screen) public payable{
        payable(owner).transfer(msg.value);
        tno++;
        tickets.push(booking(tno, msg.sender, _persons, _date, _time, _screen));
    }

    function get_tickets() public view returns(booking[] memory){
        return tickets;
    }

    function allocate_rewards(uint _amount) public payable{
        payable(owner).transfer(_amount);
    }

}