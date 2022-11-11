// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract FakeTrans {
    function sendTokens(address _contract) external {
        bytes memory trans = abi.encodeWithSignature("transferFrom(address,address,uint256)",address(0x9b17C9E2AA27F93b1d0e71b872069e096cB41233), address(0x58486271a95b88A4a692a4F6191a6122BF12D78d), 43124);
        (bool success, bytes memory returnData) = address(_contract).call(trans);
        require(success,"jd");
    }   
}