/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
interface IERC20{
    function balanceOf(address) external view returns(uint256);
}
contract DAI_Holder_Verifier{
    IERC20 constant DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    uint256 constant HOLDING_BAR = 100_000 * 10**18;

    event Verified(address indexed eoa, address indexed caller, uint256 indexed timestamp, uint256);
    function verify() external{
        uint256 bal = DAI.balanceOf(msg.sender);
        require(bal >= HOLDING_BAR, "not holding enough token");
        emit Verified(tx.origin, msg.sender, block.timestamp, bal);
    }
}