/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

pragma solidity ^0.8;

interface ITargetContract {
    function getLatestPrice() external returns (int);
}

contract SourceContract {
    function baz() external {
        ITargetContract targetContract = ITargetContract(address(0xAA991b63a8b905409846A295F0D2f887423De096));
        int returnedValue = targetContract.getLatestPrice();
    }
}