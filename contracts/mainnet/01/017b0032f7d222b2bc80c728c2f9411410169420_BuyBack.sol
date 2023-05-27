/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

pragma solidity ^0.8.0;

// interfaces

interface ICurveFiPool { 
    function get_dy (uint, uint, uint) external view returns (uint);
    function exchange (uint, uint, uint, uint, bool) external payable returns (uint);
    function exchange_underlying (uint, uint, uint, uint, address) external payable returns (uint);
}

// libs

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction underflow");
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0, "SafeMath: modulo by zero");
        c = a % b;
    }
}

contract BuyBack {

    using SafeMath for uint;

    address public CURVE_POOL_ADDRESS = 0x2B433CE7Ff7eEEc2981351a9De6E46a0510eDd28;
    ICurveFiPool public curvePool;

    constructor () public {
        curvePool = ICurveFiPool(CURVE_POOL_ADDRESS);
    }
    
    receive () external payable {}
    
    function slippage (uint _dy, uint _slippage) internal returns (uint) { return _dy.sub((_slippage.mul(_dy)).div(10000)); }

    function dy (uint _qtd) internal returns (uint) { return curvePool.get_dy(1, 0, _qtd); }

    function buyBack (uint _qtd, uint _slippage) public payable returns (uint) {
        require(_slippage >= 10 && _slippage <= 1000 && _qtd <= address(this).balance);
        uint _min_dy = slippage(dy(_qtd), _slippage);
        return curvePool.exchange_underlying{ value : _qtd }(1, 0, _qtd, _min_dy, address(this));
    }
}