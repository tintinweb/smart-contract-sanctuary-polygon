/**
 *Submitted for verification at polygonscan.com on 2023-01-19
*/

// SPDX-License-Identifier: UNLICENSED
// Smart Contract MNI Corp (MNI)

pragma solidity ^0.8.7;

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IERC20 {
	function balanceOf(address who) external view returns (uint256 balance);
	function allowance(address owner, address spender) external view returns (uint256 remaining);
	function transfer(address to, uint256 value) external returns (bool success);
	function approve(address spender, uint256 value) external returns (bool success);
	function transferFrom(address from, address to, uint256 value) external returns (bool success);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a - b;
		assert(b <= a && c <= a);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a && c>=b);
		return c;
	}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

library SafeERC20 {
	function safeTransfer(IERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract MnICorp is IERC20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	mapping (address => uint256) private balances;
	mapping (address => mapping (address => uint256)) public allowed;
    bool private isLiquidityTransfer;
    bool private isContractTransfer;

	uint256 public totalSupply;
	string public constant name = "MnI";
	uint8 public constant decimals = 18;
	string public constant symbol = "MNI";
	uint256 public constant initialSupply = 10000000000 * 10 ** decimals;

    uint256 public maxBuyAmount = 10000000 * 10 ** decimals;
    uint256 public maxSellAmount = 10000000 * 10 ** decimals;
    uint24 public tax = 25000; // 2.5%

    address private constant receiver = 0x8b2Ef0e3A1362F41cC58fF95644e26b286b59d5B;
    address public taxAddress = payable(0xc41d1a9950e597A993Dd34E61d96aA9fEf7Ee3fA);

    // ref: https://docs.uniswap.org/contracts/v3/reference/deployments
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //Pair with USDT
    address public constant quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant swapRouter02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant nonfungiblePositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // ref: https://docs.uniswap.org/concepts/protocol/fees
    uint24[4] private tradingFeeUniswapV3 = [100, 500, 3000, 10000]; // [0.01%, 0.05%, 0.3%, 1%]

	constructor() {
		totalSupply = initialSupply;
		balances[receiver] = totalSupply;
        isWhiteListed[receiver] = true;
        paused = false;
		emit Transfer(address(0), receiver, initialSupply);
	}

    // Pausable 
    event Pause();
	event Unpause();

	bool public paused = false;
    mapping (address => bool) internal isBlacklisted;
    mapping (address => bool) internal isWhiteListed;

    function setBlackList(address _addr, bool _value) external onlyOwner() {
        require(!whiteListed(_addr), "Unable to blacklist whitelisted address");
        isBlacklisted[_addr] = _value;
    }

    function setWhiteList(address _addr, bool _value) external onlyOwner() {
        require(!blackListed(_addr), "Unable to whitelist blacklisted address");
        isWhiteListed[_addr] = _value;
    }

    function whiteListed(address _addr) public view returns (bool) {
        bool isWhite = isWhiteListed[_addr] || _addr == owner() || _addr == nonfungiblePositionManager || _addr == uniswapV3Factory || _addr == quoter || _addr == swapRouter02 || _addr == taxAddress || _addr == getPool(tradingFeeUniswapV3[0]) || _addr == getPool(tradingFeeUniswapV3[1]) || _addr == getPool(tradingFeeUniswapV3[2]) || _addr == getPool(tradingFeeUniswapV3[3]) ? true : false;
        return isWhite;
    }

    function blackListed(address _addr) public view returns (bool) {
        bool isBlack = !isBlacklisted[_addr] || _addr == owner() || isWhiteListed[_addr] || _addr == nonfungiblePositionManager || _addr == uniswapV3Factory || _addr == quoter || _addr == swapRouter02 || _addr == taxAddress || _addr == getPool(tradingFeeUniswapV3[0]) || _addr == getPool(tradingFeeUniswapV3[1]) || _addr == getPool(tradingFeeUniswapV3[2]) || _addr == getPool(tradingFeeUniswapV3[3]) ? false : true;
        return isBlack;
    } 

	modifier whenNotPaused() {
		if(!whiteListed(msg.sender))
            require(!paused, "Pausable: paused");
        _;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyOwner() whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyOwner() whenPaused {
		paused = false;
		emit Unpause();
	}

    function getPool(uint24 _fee) private view returns (address _pool) {
        address pool_ = IUniswapV3Factory(uniswapV3Factory).getPool(
            address(this),
            USDT,
            _fee
        );
        return pool_;
    }

    function changeTaxAddress(address _addr) external onlyOwner {
        taxAddress = _addr;
        isWhiteListed[_addr] = true;
    }

    function updateMaxBuyAmount(uint256 _value) external onlyOwner {
        maxBuyAmount = _value;
    }

    function updateMaxSellAmount(uint256 _value) external onlyOwner {
        maxSellAmount = _value;
    }

    function updateTax(uint24 _value) external onlyOwner {
        tax = _value;
    }

    function calculateFee(uint256 _amount, uint24 percentage) public pure returns (uint256 fee) {
        uint256 _fee = _amount.mul(percentage).div(10**6);
        require(percentage <= 10**6, "CT1: Too large");
        require(_fee >= 0, "CT2: Too small");
        return _fee;
    }

    function _tokenTransfer(address _from, address _to, uint256 _value) private returns (bool success) {
        uint256 fromBalance = balances[_from];
        require(fromBalance >= _value, "ERC20: transfer amount exceeds balance");

        balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

	function transfer(address _to, uint256 _value) external override whenNotPaused returns (bool success) {
		require(_to != msg.sender,"T1- Recipient can not be the same as sender");
		require(_to != address(0),"T2- Please check the recipient address");
		require(balances[msg.sender] >= _value,"T3- The balance of sender is too low");
		require(!blackListed(msg.sender),"T4- The wallet of sender is frozen");
		require(!blackListed(_to),"T5- The wallet of recipient is frozen");

        isLiquidityTransfer = (msg.sender == getPool(tradingFeeUniswapV3[0]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[1]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[2]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[3]) && _to == nonfungiblePositionManager) || (msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[0]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[1]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[2]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[3])) ? true : false;

        bool _isBuy = msg.sender == getPool(tradingFeeUniswapV3[0]) || msg.sender == getPool(tradingFeeUniswapV3[1]) || msg.sender == getPool(tradingFeeUniswapV3[2]) || msg.sender == getPool(tradingFeeUniswapV3[3]) ? true : false;
        bool _isSell = _to == getPool(tradingFeeUniswapV3[0]) || _to == getPool(tradingFeeUniswapV3[1]) || _to == getPool(tradingFeeUniswapV3[2]) || _to == getPool(tradingFeeUniswapV3[3]) ? true : false;

		bool _isAntiDumpActive = maxSellAmount > 0 && !whiteListed(msg.sender) ? true : false;
        bool _isAntiWhaleActive = maxBuyAmount > 0 && !whiteListed(_to) ? true : false;
        uint24 _taxFee;

        if(!(isLiquidityTransfer)){
            if(_isBuy) { 
                if(!whiteListed(_to)){
                    require(!paused, "Pausable: paused");
                }
                if(_isAntiWhaleActive){
                    require(_value <= maxBuyAmount, "Transfer amount exceeds maxBuyAmount.");
                }
                _taxFee = whiteListed(_to) ? 0 : tax;
            }
            if(_isSell) {
                if(!whiteListed(msg.sender)){
                    require(!paused, "Pausable: paused");
                }
                if(_isAntiDumpActive){
                    require(_value <= maxSellAmount, "Transfer amount exceeds maxSellAmount.");
                }
            }
        }
        
        // calculate token amount
        uint256 tFee = calculateFee(_value, _taxFee);
        uint256 _valueTo = _value.sub(tFee);

        // transfer token to buyer
        _tokenTransfer(msg.sender, _to, _valueTo);

        // transfer token to taxAddress
        if(tFee > 0){
            _tokenTransfer(msg.sender, taxAddress, tFee);
        }

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) external override whenNotPaused returns (bool success) {
		require(_to != address(0),"TF1- Please check the recipient address");
		require(balances[_from] >= _value,"TF2- The balance of sender is too low");
		require(allowed[_from][msg.sender] >= _value,"TF3- The allowance of sender is too low");
		require(!blackListed(_from),"T4- The wallet of sender is frozen");
		require(!blackListed(_to),"T5- The wallet of recipient is frozen");

		isLiquidityTransfer = (msg.sender == getPool(tradingFeeUniswapV3[0]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[1]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[2]) && _to == nonfungiblePositionManager || msg.sender == getPool(tradingFeeUniswapV3[3]) && _to == nonfungiblePositionManager) || (msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[0]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[1]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[2]) || msg.sender == nonfungiblePositionManager && _to == getPool(tradingFeeUniswapV3[3])) ? true : false;

        bool _isBuy = _from == getPool(tradingFeeUniswapV3[0]) || _from == getPool(tradingFeeUniswapV3[1]) || _from == getPool(tradingFeeUniswapV3[2]) || _from == getPool(tradingFeeUniswapV3[3]) ? true : false;
        bool _isSell = _to == getPool(tradingFeeUniswapV3[0]) || _to == getPool(tradingFeeUniswapV3[1]) || _to == getPool(tradingFeeUniswapV3[2]) || _to == getPool(tradingFeeUniswapV3[3]) ? true : false;

		bool _isAntiDumpActive = maxSellAmount > 0 && !whiteListed(_from) ? true : false;
        bool _isAntiWhaleActive = maxBuyAmount > 0 && !whiteListed(_to) ? true : false;
        uint24 _taxFee;

        if(!(isLiquidityTransfer)){
            if(_isBuy) { 
                if(!whiteListed(_to)){
                    require(!paused, "Pausable: paused");
                }
                if(_isAntiWhaleActive){
                    require(_value <= maxBuyAmount, "Transfer amount exceeds maxBuyAmount.");
                }
                _taxFee = whiteListed(_to) ? 0 : tax;
            }
            if(_isSell) {
                if(!whiteListed(_from)){
                    require(!paused, "Pausable: paused");
                }
                if(_isAntiDumpActive){
                    require(_value <= maxSellAmount, "Transfer amount exceeds maxSellAmount.");
                }
            }
        }
        
        // calculate token amount
        uint256 tFee = calculateFee(_value, _taxFee);
        uint256 _valueTo = _value.sub(tFee);

        // transfer token to buyer
        _tokenTransfer(_from, _to, _valueTo);

        // transfer token to taxAddress
        if(tFee > 0){
            _tokenTransfer(_from, taxAddress, tFee);
        }

        // decrease sender allowance
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		return true;
	}

	function balanceOf(address _owner) public override view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) external override whenNotPaused returns (bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0),"A1- Reset allowance to 0 first");

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}