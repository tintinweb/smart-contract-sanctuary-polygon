/**
 *Submitted for verification at polygonscan.com on 2022-05-11
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract bloops {

    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct bloop {
        address blooper;
        uint256 id;
        string bloopTxt;
        string bloopImg;
    }
    
    event bloopCreated (
        address blooper,
        uint256 id,
        string bloopTxt,
        string bloopImg
    );
    
    mapping(uint256 => bloop) Bloops;

    function addBloop(
        string memory bloopTxt,
        string memory bloopImg
    ) public payable {
        require(msg.value == (0.01 ether), "Please Submit 0.01 matic");
        bloop storage newBloop = Bloops[counter];
        newBloop.bloopTxt = bloopTxt;
        newBloop.bloopImg = bloopImg;
        newBloop.blooper = msg.sender;
        newBloop.id = counter;

        emit bloopCreated(
                msg.sender,
                counter,
                bloopTxt,
                bloopImg
        );

        counter++;

        payable(owner).transfer(msg.value);

    }

    function getBloop(uint256 id) public view returns (
        string memory,
        string memory,
        address
    ){
            require(id < counter, "No such Bloop");
            bloop storage t = Bloops[id];
            return(t.bloopTxt,t.bloopImg,t.blooper);
    }

}