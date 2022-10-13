/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// https://docs.soliditylang.org/en/v0.8.15/internals/layout_in_storage.html#bytes-and-string
contract StorageTest{

    uint256 public var0 = 255;
    string public var1 = "angle";
    string public var2 = "The quick fox jumped over lazy dog";
    address public var3 = msg.sender;
    uint256[2] public var4 = [0x1122334455,0x66778899aa];
    uint256[] public var5;


    function get(uint i) public view returns (uint) {
        return var5[i];
    }

    // Solidity can return the entire var5ay.
    // But this function should be avoided for
    // var5ays that can grow indefinitely in length.
    function getvar5() public view returns (uint[] memory) {
        return var5;
    }

    function push(uint i) public {
        // Append to var5ay
        // This will increase the var5ay length by 1.
        var5.push(i);
    }

    function pop() public {
        // Remove last element from var5ay
        // This will decrease the var5ay length by 1
        var5.pop();
    }

    function getLength() public view returns (uint) {
        return var5.length;
    }

    function remove(uint index) public {
        // Delete does not change the var5ay length.
        // It resets the value at index to it's default value,
        // in this case 0
        delete var5[index];
    }

    function store(uint256 slot,uint256 value) public {
        assembly{
            sstore(slot,value)
        }
    }

    function retrieve(uint256 slot) public view returns (bytes32){
        assembly{
            mstore(0,sload(slot))
            return(0,0x20)
        }
    }


}