/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract ContractVisit {

    event visitarEvent(address indexed user,uint256 visitas, uint256 timestamp);

    struct persona {
        uint256 contador;
        string[] mensaje;
    }

    mapping (address => persona) private people;
    uint256 public visit;


    function visitar(string calldata _mensaje) external  returns(uint256) {
        people[msg.sender].contador ++;
        people[msg.sender].mensaje.push(_mensaje);
        visit++;
        emit visitarEvent(msg.sender, visit, block.timestamp);
        return (visit);
    }

    function getPeople(address _addr) external view returns(persona memory) {
        return(people[_addr]);
    }

}