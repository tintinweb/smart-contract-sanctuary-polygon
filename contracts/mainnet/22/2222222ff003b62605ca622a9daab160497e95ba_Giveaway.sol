/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

pragma solidity 0.5.6;

// https://tools.ozys.io


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

interface IKIP7 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract Giveaway {
    
    using SafeMath for uint256;

    string public constant version = "Giveaway20220818";
    
    constructor() public {}
    
    function _balanceOf(address token, address user) private view returns (uint256) {
        if (token == address(0)) {
            return address(user).balance;
        }
        
        return IKIP7(token).balanceOf(user);
    }
    
    function _transfer(address token, address to, uint amount) private returns (bool) {
        if (token == address(0)) {
            (bool success, ) = address(to).call.value(amount)("");
            return success;
        }
        
        return IKIP7(token).transfer(to, amount);
    }
    
    function _transferFrom(address token, address from, uint amount) private returns (bool) {
        if (token == address(0)) {
            // amount >= msg.value ?
            return amount == msg.value;
        }
        
        return IKIP7(token).transferFrom(from, address(this), amount);
    }
    
    function distribute(address token, uint tokenTotal, address[] memory addrs, uint[] memory amounts) public payable {
        require(addrs.length == amounts.length, "length does not match.");
        
        uint beforeAmount = _balanceOf(token, address(this));
        
        if (token == address(0)) {
            beforeAmount =beforeAmount.sub(msg.value);
        }
        
        _transferFrom(token, msg.sender, tokenTotal);
        
        for(uint i = 0; i < addrs.length; i++) {
            require(_transfer(token, addrs[i], amounts[i]), "transfer failed.");
        }
        
        require(_balanceOf(token, address(this)) == beforeAmount, "amount not equal");
    }

    function distribute(address tokenA, address tokenB, uint totalAmountA, uint totalAmountB, address[] memory addrs, uint[] memory amountsA, uint[] memory amountsB) public payable {
        require(addrs.length == amountsA.length, "length does not match.");
        require(addrs.length == amountsB.length, "length does not match.");
        
        uint beforeTokenA = _balanceOf(tokenA, address(this));
        uint beforeTokenB = _balanceOf(tokenB, address(this));
        
        if (tokenA == address(0)) {
            beforeTokenA = beforeTokenA.sub(msg.value);
        }
        
        if (tokenB == address(0)) {
            beforeTokenB = beforeTokenB.sub(msg.value);
        }

        _transferFrom(tokenA, msg.sender, totalAmountA);
        _transferFrom(tokenB, msg.sender, totalAmountB);
        
        for(uint i = 0; i < addrs.length; i++) {
            require(_transfer(tokenA, addrs[i], amountsA[i]), "tokenA transfer failed.");
            require(_transfer(tokenB, addrs[i], amountsB[i]), "tokenB transfer failed.");
        }

        require(_balanceOf(tokenA, address(this)) == beforeTokenA, "tokenA amount not equal");
        require(_balanceOf(tokenB, address(this)) == beforeTokenB, "tokenB amount not equal");
    }
}