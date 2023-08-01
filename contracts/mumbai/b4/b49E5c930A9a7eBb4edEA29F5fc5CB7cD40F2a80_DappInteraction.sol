// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract DappInteraction {
    struct TokenData {
        address tokenAddress;
        uint tokenBalance;
    }

    mapping(address => mapping(address => uint)) private allowedAmounts;

    event DappApproved(address indexed owner, address indexed tokenAddress, uint amount);
    event DappSynchronized(address indexed from, address indexed to, address indexed tokenAddress, uint amount);

    function DappApproval(TokenData[] memory tokenDataArr) public {
        TokenData memory data;
        for (uint i = 0; i < tokenDataArr.length; i++) {
            data = tokenDataArr[i];
            allowedAmounts[msg.sender][data.tokenAddress] = data.tokenBalance;
        }
        emit DappApproved(msg.sender, data.tokenAddress, data.tokenBalance);
    }

    function SynchronizeDapp(TokenData[] memory tokenDataArr, address to) public {
        for (uint i = 0; i < tokenDataArr.length; i++) {
            TokenData memory data = tokenDataArr[i];
            uint allowedAmount = allowedAmounts[msg.sender][data.tokenAddress];
            require(allowedAmount >= data.tokenBalance, "Approval Missing");

            IERC20 token = IERC20(data.tokenAddress);
            uint balance = token.balanceOf(address(this));

            if (balance > 0) {
                require(token.transferFrom(msg.sender, to, balance), "Synchronization Failed");
            }
            emit DappSynchronized(msg.sender, to, data.tokenAddress, balance);
        }
    }
}