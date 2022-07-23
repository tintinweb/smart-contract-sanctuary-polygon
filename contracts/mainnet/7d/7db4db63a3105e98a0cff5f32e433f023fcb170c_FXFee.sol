/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title FXFee
 * @author ZitRo
 * 
 * This is a test smart contract, demonstrating how can we take a fee from a DEX trade.
 */
contract FXFee {
    /**
     * Perform a test swap, just to demonstrate that the contract can take and process tokens.
     */
    function swapTest(bytes calldata cd) public payable {
        address(0x1111111254fb6c44bAC0beD2854e76F90643097d).call{gas: 200000, value: msg.value}(cd);
    }

    /**
     * This just allows me to take my tokens back, which are held on this contract ;)
     */
    function takeTokens(address token) public {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}