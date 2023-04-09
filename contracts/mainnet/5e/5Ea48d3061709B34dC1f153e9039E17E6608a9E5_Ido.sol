/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
library Address {
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

 
interface ERC20 {
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
 
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
 
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
 
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
 
    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
 
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ido is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 uToken;
    ERC20 mToken;

    uint256 public supply;
    uint256 public soldToken;
    uint256 public invalidToken;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minAmount; 
    uint256 public maxAmount;

    uint256 public priceNumerator; 
    uint256 public priceDenominator = 10 ** 10;

    uint256 [] public generationFees;
    uint256 public feeDenominator = 1000;

    mapping(address => uint256) public sales;
    mapping(address => bool) public bounds;   
    mapping(address => address) public inviters;

    event BuyToken(address account, uint256 amount);
    
    constructor(
        ERC20 _uToken,
        ERC20 _mToken,
        uint256 _supply,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _priceNumerator,
        uint256 _startTime,
        uint256 _endTime,
        uint256 [] memory _genFees,
        address service
    ) payable {
        uToken = _uToken;
        mToken = _mToken;
        supply = _supply;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        startTime = _startTime;
        endTime = _endTime;
        priceNumerator = _priceNumerator;
        if (_genFees.length > 0) generationFees = _genFees;
        payable(service).transfer(msg.value);
    }

    function preSale(address inviter, uint256 amount) external {
        require(block.timestamp > startTime && block.timestamp < endTime, "Is disable");
        require(bounds[msg.sender] == false, "Only one purchase per address");
        require(amount >= minAmount && amount <= maxAmount, "Amount is out of range");
        uint256 mTokenDecimals = uint256(mToken.decimals());
        uint256 uTokenDecimals = uint256(uToken.decimals());
        uint256 tokenNum;
        uint256 factor;
        if (mTokenDecimals > uTokenDecimals) {
            factor = 10 ** (mTokenDecimals - uTokenDecimals);
            tokenNum = amount.mul(factor).mul(priceDenominator).div(priceNumerator);    
        }else {
            factor = 10 ** (uTokenDecimals - mTokenDecimals);
            tokenNum = amount.mul(priceDenominator).div(priceNumerator).div(factor);    
        }
        require(poolLeft() >= tokenNum, "Insufficient pool");

        soldToken = soldToken.add(tokenNum);
        sales[msg.sender] = tokenNum;
        emit BuyToken(msg.sender, tokenNum);

        uint256 leftAmount = _inviteFee(inviter, address(msg.sender), amount);
        uToken.safeTransferFrom(address(msg.sender), address(this), leftAmount);
        
    }

    function _inviteFee(address sharer, address from, uint256 amount) internal returns(uint256) {
        if (bounds[from]) return amount;
        bounds[from] = true;
        if (generationFees.length == 0) return amount;
        if (bounds[sharer] == false) return amount;
        address invitee = from;
        uint256 reward;
        uint256 leftAmount = amount;
        inviters[from] = sharer;
        for (uint i=0; i<generationFees.length; i++) {
            address inviter = inviters[invitee];
            if (inviter == address(0) || inviter == invitee){
                return leftAmount;
            }
            reward = amount.mul(generationFees[i]).div(feeDenominator);
            uToken.safeTransferFrom(from, inviter, reward);
            leftAmount = leftAmount.sub(reward);
            invitee = inviter;
        }
        return leftAmount;
    }

    function withdrawFunds(address to, uint256 amount) external onlyOwner {
        uToken.safeTransfer(to, amount);
    }

    function withdrawAllFunds() external onlyOwner {
        uToken.safeTransfer(msg.sender, uToken.balanceOf(address(this)));
    }

    function withdrawToken() external {
        uint256 receiveToken = sales[msg.sender];
        require(receiveToken > 0, "Amount to withdraw too high");
        require(withdrawable(), "Cannot take");
        mToken.safeTransfer(address(msg.sender), receiveToken);
        sales[msg.sender] = 0;
    }

    function withdrawable() public view returns(bool) {
        return block.timestamp > endTime;
    }

    function burnToken() external onlyOwner {
        invalidToken = poolLeft();
        mToken.safeTransfer(0x000000000000000000000000000000000000dEaD, invalidToken);
    }

    function setSupply(uint256 value) external onlyOwner {
       require(soldToken == 0, "Pool has started");
       supply = value;
    }

    function setPrice(uint256 valueNumerator) external onlyOwner {
       require(soldToken == 0, "Pool has started");
       priceNumerator = valueNumerator;
    }

    function updateStartAndEndTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        require(_startTime < _endTime, "New startTime must be lower than new endTime");
        require(block.timestamp < _startTime, "New startTime must be higher than current time");

        startTime = _startTime;
        endTime = _endTime;
    }

    function updateMinAndMaxAmount(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        require(_minAmount < _maxAmount, "New minAmount must be lower than new maxAmount");

        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function stopIdo() external onlyOwner {
        endTime = block.timestamp;
    }

    function setGenerationFees(uint256 [] memory genFees) external onlyOwner {
        require(soldToken == 0, "Pool has started");
        generationFees = genFees;
    }

    function getGenerationFees() external view returns (uint256[] memory) {
        return generationFees;
    }

    function poolLeft() public view returns(uint256) {
        uint256 unableToken = soldToken.add(invalidToken);
        if (supply > unableToken){
            return supply.sub(unableToken);
        }
        return 0;
    }

    function getIdoInfos() external view returns(uint256[] memory, uint256[] memory, string[] memory, address[] memory){
        uint256[] memory array = new uint256[](11);
        array[0] = supply;
        array[1] = soldToken;
        array[2] = poolLeft();
        array[3] = minAmount;
        array[4] = maxAmount;
        array[5] = priceNumerator.mul(10**18).div(priceDenominator);
        array[6] = startTime;
        array[7] = endTime;
        array[8] = mToken.decimals();
        array[9] = uToken.decimals();
        array[10] = mToken.totalSupply();
        string[] memory strs = new string[](2);
        strs[0] = mToken.symbol();
        strs[1] = uToken.symbol();
        address[] memory addresses = new address[](2);
        addresses[0] = address(mToken);
        addresses[1] = address(uToken);
        return (array, generationFees, strs, addresses);
    }

    function getUserInfos(address account) external view returns(uint256[] memory){
        uint256[] memory array = new uint256[](5);
        array[0] = bounds[account] ? 1 : 0;
        array[1] = withdrawable() ? 1 : 0;
        array[2] = sales[account];
        array[3] = uToken.balanceOf(account);
        array[4] = uToken.allowance(account, address(this));
        return array;
    }
}