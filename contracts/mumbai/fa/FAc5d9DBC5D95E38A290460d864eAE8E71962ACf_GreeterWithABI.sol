/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IGreeter {

    function greet() external view returns (string memory);

    function setGreeting(string memory _greeting) external;
}

contract GreeterWithABI  {

    IGreeter greeterContract;

    function setContractAddress(address _address) public {
        greeterContract = IGreeter(_address);
    }

    function greet() public view returns (string memory) {
        return greeterContract.greet();
    }

}