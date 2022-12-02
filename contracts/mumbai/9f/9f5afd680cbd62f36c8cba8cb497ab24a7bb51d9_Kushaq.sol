/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.6;

library SafeMath 
{
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

interface IERC20 
{
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Kushaq {
    using SafeMath for uint256; 
    IERC20 public Dai;

    uint256 public baseDivider = 200;
    address[3] public feeReceivers;
    uint256[3] public feeRates = [30, 70, 100];

    constructor() {
        Dai = IERC20(0xC87385b5E62099f92d490750Fcd6C901a524BBcA);
        feeReceivers = [0x3aC05AeAe947Fe71e7654c42e33b4E3436aA8024,0x5bb1865856051138bC7696993302726299C6872e,0xdc7679188E1ff0c513457f9be8df94d5EdFfBF88];
    }

    function distribute() public {
        uint256 balNow = Dai.balanceOf(address(this));
        if(balNow > 0){
            for(uint256 i = 0; i < feeReceivers.length; i++){
                uint256 fee = balNow.mul(feeRates[i]).div(baseDivider);
                Dai.transfer(feeReceivers[i], fee);
            }
        }
    }

}