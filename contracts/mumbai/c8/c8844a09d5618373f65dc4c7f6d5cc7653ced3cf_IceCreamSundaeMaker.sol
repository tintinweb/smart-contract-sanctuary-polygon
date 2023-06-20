/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract IceCreamSundaeMaker {

    struct Sundae {
        string flavor;
        string topping;
        string sauce;
    }

    address public owner;
    mapping(address => Sundae) public sundaes;

    constructor() {
        owner = msg.sender;
    }

    function createSundae(string calldata _flavor, string calldata _topping, string calldata _sauce) external {
        Sundae memory newSundae = Sundae({
            flavor: _flavor,
            topping: _topping,
            sauce: _sauce
        });
        sundaes[msg.sender] = newSundae;
    }

    function getSundae(address _sundaeOwner) external view returns (string memory flavor, string memory topping, string memory sauce) {
        Sundae memory sundae = sundaes[_sundaeOwner];
        return (sundae.flavor, sundae.topping, sundae.sauce);
    }
}