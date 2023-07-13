/**
 *Submitted for verification at polygonscan.com on 2023-07-12
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
    address[6] private feeReceivers;
    uint256[6] private feeRates = [200, 200, 100, 100, 50, 50];

    constructor(address _usdtAddr) {
        usdt = IERC20(_usdtAddr);
        feeReceivers[0] = 0xc49120F9e8b7592A9ee6bE451C464D4f60339a2c;
        feeReceivers[1] = 0x255f3409B2d91C943bF909fB1d9a666B0cEB23eA;
        feeReceivers[2] = 0xBf4c63a6207b9308333542057E104166f6ec89fB;
        feeReceivers[3] = 0xBf4c63a6207b9308333542057E104166f6ec89fB;
        feeReceivers[4] = 0xD0a48f8Bb5181199fa5d02f0dF17A5f3ECd8EE3a;
        feeReceivers[5] = 0x2CDd27B02F7E435483e4490539e17B3109EAcb50;
    }

    function distribute() external {
        uint256 balNow = usdt.balanceOf(address(this));
        if(balNow > 0){
            for(uint256 i = 0; i < feeReceivers.length; i++){
                uint256 fee = balNow.mul(feeRates[i]).div(baseDivider);
                usdt.transfer(feeReceivers[i], fee);
            }
        }
    }
}