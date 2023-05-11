/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Escrow {
    IERC20 public constant GHST = IERC20(0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7);
    address public constant BACK = 0x939b67F6F6BE63E09B0258621c5A24eecB92631c;
    address public constant FWD = 0x7b2b0cBaDC25953A64D77B4785848b48B45E1017;
    address public agent = msg.sender;
    
    modifier onlyAgent() {
        require(msg.sender == agent, "NA");
        _;
    }

    function back() external onlyAgent {
        GHST.transfer(BACK, GHST.balanceOf(address(this)));
    }

    function forward() external onlyAgent {
        GHST.transfer(FWD, GHST.balanceOf(address(this)));
    }

    // ~~ //

    function assignAgent(address _agent) external onlyAgent {
        agent = _agent;
    }
}