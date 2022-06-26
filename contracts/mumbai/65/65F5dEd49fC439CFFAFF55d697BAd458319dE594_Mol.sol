//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Mol {
    
    uint public sum;

    struct Action {
        uint id;
        string name;
    }

    uint count = 0;

    event enterName(
        address from,
        string name,
        uint id
    );

    

    mapping(uint => Action ) public result;


    function get (string memory _name) public {
        count++;

        Action memory action = Action(count, _name);

        result[count] = action;

        emit enterName(msg.sender, _name, count);

    }


    function add (uint a, uint b) public {

        sum = a + b;
    }
    
}