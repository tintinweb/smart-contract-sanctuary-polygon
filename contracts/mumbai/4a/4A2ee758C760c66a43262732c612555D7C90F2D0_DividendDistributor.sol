/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
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
interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function setSportToken(address _address) external;
    function process(uint256 gas) external;
}



contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _sportTokenAddr;
    IERC20 public _sportToken;

    address[] public shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public shareholderEsgBalance;
    mapping (address => uint256) holdingTime;
    mapping (address => bool) public isshareholder;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => uint256) public claimAmounts;

    uint256 public minPeriod = 1 days;
    mapping(address => uint256) public distributedAmounts;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == address(_token)); _;
    }

    constructor () {
        _token = msg.sender;
    }
    function setSportToken(address _address) external override onlyToken {
        _sportTokenAddr = _address;
        _sportToken = IERC20(_sportTokenAddr);
    }
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        shareholderEsgBalance[shareholder] = amount;
        if(amount==0){removeShareholder(shareholder); return;} 
        if(isshareholder[shareholder] == false) addShareholder(shareholder); 
    }

    function getDiffDays(address holder) internal view returns(uint256) {
        uint256 retVal = (block.timestamp - holdingTime[holder]).div(60).div(60).div(24);
        return retVal + 1;
    }

    function getDenominator() internal view returns(uint256) {
        uint256 retVal = 0;
        for(uint256 i=0;i<shareholders.length;i++) {
            retVal = retVal.add(shareholderEsgBalance[shareholders[i]].mul(getDiffDays(shareholders[i])));
        }
        return retVal;
    }

    function process(uint256 gas) external override onlyToken {
        if(_sportToken.balanceOf(address(this))<=0) return;
        uint256 sportBalance = _sportToken.balanceOf(address(this));
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 denominator = getDenominator();
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex], sportBalance.mul(shareholderEsgBalance[shareholders[currentIndex]].mul(getDiffDays(shareholders[currentIndex]))).div(denominator));
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp;
    }

    function distributeDividend(address shareholder, uint256 amount) internal {
        if(shareholderEsgBalance[shareholder] == 0){ return; }

        if(amount > 0){
            _sportToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            claimAmounts[shareholder] = amount;
            distributedAmounts[shareholder] = distributedAmounts[shareholder] + amount;
        }
    }

    function getYesterdayYield(address _address) external view returns (uint256) {
        if(claimAmounts[_address]==0) return 0;
        else if((block.timestamp - shareholderClaims[_address]) / 1 days == 1) return claimAmounts[_address];
        else return 0;
    }

    function addShareholder(address shareholder) internal {
        holdingTime[shareholder] = block.timestamp;
        isshareholder[shareholder] = true;
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        isshareholder[shareholder] = false;
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}