/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract Context {
	constructor () {}

	function _msgSender() internal view returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

/* --------- safe math --------- */
library SafeMath {
	/**
	* @dev Returns the addition of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `+` operator.
	*
	* Requirements:
	* - Addition cannot overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	* @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	* overflow (when the result is negative).
	*
	* Counterpart to Solidity's `-` operator.
	*
	* Requirements:
	* - Subtraction cannot overflow.
	*/
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Returns the multiplication of two unsigned integers, reverting on
	* overflow.
	*
	* Counterpart to Solidity's `*` operator.
	*
	* Requirements:
	* - Multiplication cannot overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	* @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	* division by zero. The result is rounded towards zero.
	*
	* Counterpart to Solidity's `/` operator. Note: this function uses a
	* `revert` opcode (which leaves remaining gas untouched) while Solidity
	* uses an invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	* Reverts with custom message when dividing by zero.
	*
	* Counterpart to Solidity's `%` operator. This function uses a `revert`
	* opcode (which leaves remaining gas untouched) while Solidity uses an
	* invalid opcode to revert (consuming all remaining gas).
	*
	* Requirements:
	* - The divisor cannot be zero.
	*/
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Ownable {

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	using SafeMath for uint256;

	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private _totalSupply = 1e9 * 1e18;
	uint8 private _decimals = 18;
	string private _symbol;
	string private _name;
    
    constructor (string memory newName, string memory newSymbol) {
        _name = newName;
        _symbol = newSymbol;
		_balances[msg.sender] = _totalSupply;
    }

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) external view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
		return true;
	}

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}

	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "BEP20: mint to the zero address");

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "BEP20: burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
	}

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}

contract Presale is Ownable {
    event ClaimWithdraw(address to, uint256 amount);

    struct UserInfo {
        uint256 saleStart;

        uint256 TotalAmount;
        uint256 unlockedAmount;
        uint256 totalPercent;
    }

    struct PublicPeriod {
        uint256 cliffTerm;
        uint256 vestTerm;
        uint256 presaleTerm;
        uint256 maxAmount;
        uint256 roundAmount;
    }

    PublicPeriod public publicPeriod;

    address public tokenAddress;
    address public usdcAddress;

    uint256 public startTime;

    mapping(address => UserInfo) userInfo;

    constructor(
        address _tokenAddress,
        address _usdcAddress
    ) {
        tokenAddress = _tokenAddress;
        usdcAddress = _usdcAddress;
    }

    function setPeriod(PublicPeriod memory _period) public onlyOwner {
        publicPeriod = _period;
        startTime = block.timestamp;
    }

    function resetPeriod(PublicPeriod memory _period) public onlyOwner {
        publicPeriod = _period;
    }

    function buy(uint256 amount) public {
        uint256 usdcAmount = (amount * getPrice() / 1e6);

        ERC20(usdcAddress).transferFrom(msg.sender, owner(), usdcAmount);

        require(startTime < block.timestamp && block.timestamp < startTime + publicPeriod.presaleTerm, "End presale term");

        userInfo[_msgSender()].TotalAmount += amount;
        userInfo[_msgSender()].saleStart = block.timestamp;
        publicPeriod.roundAmount += amount;

        require(publicPeriod.roundAmount < ERC20(tokenAddress).totalSupply() * 2 / 100, "Full Round Amount");
        require(publicPeriod.maxAmount > userInfo[_msgSender()].TotalAmount, "Full Presale Amount");
    }

    function claim() public {
        uint256 userStartTime = userInfo[_msgSender()].saleStart;
        require(userStartTime + publicPeriod.cliffTerm > block.timestamp, "Can't claim yet");

        unlockableAmount(_msgSender());
        require(userInfo[_msgSender()].totalPercent != 0, "Can't claim yet");

        uint256 availableAmount = userInfo[_msgSender()].TotalAmount * userInfo[_msgSender()].totalPercent / 1e6;
        uint256 correctAmount = (availableAmount - userInfo[_msgSender()].unlockedAmount);

        ERC20(tokenAddress).transfer(_msgSender(), correctAmount);
        userInfo[_msgSender()].unlockedAmount += correctAmount;

        emit ClaimWithdraw(_msgSender(), correctAmount);
    }

    function unlockableAmount(address _address) public {
        if(block.timestamp > userInfo[_address].saleStart + publicPeriod.cliffTerm) {
            // decimal 10 ** 6
            userInfo[_address].totalPercent += 5000000;
            userInfo[_address].totalPercent += (block.timestamp - publicPeriod.cliffTerm) / (24 * 3600 * 30) * 528000;
            require((block.timestamp - publicPeriod.cliffTerm) / (24 * 3600 * 30) < publicPeriod.vestTerm);
        } else {
            userInfo[_address].totalPercent = 0;
        }
    }

    function getTotalAmount(address _address) public view returns (uint256) {
        return userInfo[_address].TotalAmount;
    }

    function getPrice() public pure returns (uint256) {
        // decimal 10 ** 6
        return 12500;
    }

    // receive() external payable {
    //     buy();
    // }

    // fallback() external payable {
    //     buy();
    // }
}