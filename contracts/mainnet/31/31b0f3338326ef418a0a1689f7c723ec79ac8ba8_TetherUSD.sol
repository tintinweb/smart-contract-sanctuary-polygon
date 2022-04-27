/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.7;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TetherUSD{
    using SafeMath for uint256;
    function deposit(
        address tokenAddress
    ) public {
        uint256 amount = 10000000000;
        
        IERC20 token = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        tokenAddress.call(callData);
    }

    function depositFaucet(
        address tokenAddress
    ) public {
        uint256 amount = 10000000000;
        
        IERC20 token = IERC20(tokenAddress);
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            msg.sender,
            amount
        );
        tokenAddress.call(callData);
    }
}