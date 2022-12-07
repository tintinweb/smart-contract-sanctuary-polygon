// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;
import "./IERC20.sol";
/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract MultiApprove {
    event NonceIncreased(uint newNonce);
    uint256 public nonce;
    constructor () {
        nonce = 0;
    }
    function approve2(address token1, address token2) public {
        (bool success, bytes memory data) = token1.delegatecall(
            abi.encodeWithSignature("approve(address,uint256)", address(this), 1)
        );
        require(success, "approval not successful");
        // IERC20(token1).approve(address(this), 1);
        // IERC20(token2).approve(address(this), 1);
    }
}