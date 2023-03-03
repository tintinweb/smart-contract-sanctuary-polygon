/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Test {
    string public name = "Pooria";

    event Log(uint p1, uint p2, uint p3, uint p4);

    function setName(string calldata _name) external {
        name = _name;

        emit Log(
            tx.gasprice,
            block.number,
            block.gaslimit,
            (msg.sender).balance
        );
    }

    function get() external view returns(uint) {
        return block.chainid;
    }
}