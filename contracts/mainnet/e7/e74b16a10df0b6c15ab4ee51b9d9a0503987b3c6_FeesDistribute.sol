/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract FeesDistribute {
    using SafeMath for uint256; 
    IERC20 private usdt;

    uint256 private baseDivider = 700;
    address[8] private feeReceivers;
    uint256[8] private feeRates = [100, 100, 100, 100, 100, 100, 50, 50];

    constructor(address _usdtAddr) 
    {
        usdt = IERC20(_usdtAddr);
        feeReceivers[0] = 0xbEeb4E9837c7bf8F2927E26402848b67b0153F33;
        feeReceivers[1] = 0x2D793ddC54efDA85257FBd9be952d6DACCF111e4;
        feeReceivers[2] = 0x5eAE0d718E3C082cDDE9fcf9B0Db019CAcf9cE99;
        feeReceivers[3] = 0x5f517d094929927791C01b4806405bbDA0eE4c54;
        feeReceivers[4] = 0xcD392e2C543b012497E1ffda91f77D6427d65C07;
        feeReceivers[5] = 0x859db861B332111cF46202Dd3793Faa037A2a6ad;
        feeReceivers[6] = 0x4cb0a7Bcb90FBF9D36C23FEb6336983553C22736;
        feeReceivers[7] = 0xDDE5D9c04a26B6498A238bC217D37c76b6de4B0A;
    }

    function distribute() external 
    {
        uint256 balNow = usdt.balanceOf(address(this));
        if(balNow > 0)
        {
            for(uint256 i = 0; i < feeReceivers.length; i++)
            {
                uint256 fee = balNow.mul(feeRates[i]).div(baseDivider);
                usdt.transfer(feeReceivers[i], fee);
            }
        }
    }
}