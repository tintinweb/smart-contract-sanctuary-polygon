/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract Encode {

    function encode(address addr, uint256 amount) public pure returns (bytes memory) {
            return (abi.encode(addr, amount));
        }

    function decode(bytes memory data) public pure returns (address addr, uint256 amount) {
            (addr, amount) = abi.decode(data, (address, uint256));            
        }

    function decode2(bytes memory data) public pure returns (address addr, address addr2, bool boo) {
            (addr, addr2, boo) = abi.decode(data, (address, address, bool));            
        }

    function GetBalance() public view returns (uint256){

        return (address(this).balance);
    }

    function GetSender() public view returns (address){

        return (msg.sender);
    }

    receive() external payable{
        
    }

    fallback() external{
        
        revert();   
    }
}