// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IUserProxy.sol';
import './libraries/SafeMath.sol';
import './interfaces/IUserProxyFactory.sol';
import './interfaces/IERC20.sol';
import './libraries/Ownable.sol';
interface IAggregator {

    function latestAnswer(address token) external view returns (uint256);
}

contract TokenBridgeControl is Ownable{
    using SafeMath for uint;
    address public proxyFactory;
    mapping(bytes32=>bool) transactions;
    mapping(address => address) public ethMapping;
    mapping(address => address) public polyMapping;
    mapping(address => bool) public whitelisted;
    uint256 public max;
    uint256 public min;

    mapping(address => BridgeFee) public BridgeFeeConfig;

    struct BridgeFee {
        uint256 fee;
        address bridgeFeeVault;
        address aggregator;
    }

    event TransferToEthereum(address indexed fromEthAdr,address indexed toEthAdr, address indexed toProxyAdr, address ETHtoken, address polyToken, uint256 value);
    event TransferFromEthereum(address indexed fromEthAdr, address indexed fromProxyAdr, address ETHToken, address polyToken, uint256 value,bytes32 transactionId);
    event WhiteList(address indexed fromEthAdr,bool flag);
    event SetFee(address indexed polyToken,uint256 fee,address feeValut,address aggregator);
    event TransferFromEthereumForRepay(address indexed fromEthAdr, address indexed fromProxyAdr, address token, address vToken, uint256 value,bytes32 transactionId);
    event ActiveToken(address indexed ethToken, address indexed polyToken);
    event BridgeFeeLog(address indexed fromUserProxy,address token,uint256 fee);
    event SetThreshold(uint256 max,uint256 min);
    constructor(address _proxyFactory) {
        proxyFactory = _proxyFactory;
    }

    function activeToken(address ETHToken,address PolyToken) external onlyOwner{
        ethMapping[PolyToken] = ETHToken;
        polyMapping[ETHToken] = PolyToken;
        emit ActiveToken(ETHToken,PolyToken);
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner{
        IERC20(token).transfer(msg.sender, amount);
    }


	function transferToEthereum(address fromProxy,address polyToken, address toProxy, uint256 amount) external {
        address fromEthAddr = IUserProxy(fromProxy).owner();
        address toEthAddr =  IUserProxy(toProxy).owner();
        require(fromEthAddr != address(0), 'from ETH_EXISTS');
        require(toEthAddr != address(0), 'to ETH_EXISTS');
        address ETHToken = ethMapping[polyToken];
        uint256 fee = 0;
        address bridgeFeeVault;
        require(ETHToken != address(0), "unknow token");
        if(!whitelisted[fromProxy] && !whitelisted[toProxy]){
            (fee,bridgeFeeVault) = getBridgeFee(polyToken,amount);
            if(fee > 0){
            IERC20(polyToken).transferFrom(fromProxy,bridgeFeeVault,fee);
            emit BridgeFeeLog(fromProxy,polyToken,fee);
            }
         }
        uint256 targetAmount = amount - fee;
		IERC20(polyToken).transferFrom(fromProxy,address(this), targetAmount);
        emit TransferToEthereum(fromEthAddr,toEthAddr, toProxy, ETHToken, polyToken, targetAmount);
	}


     function transferFromEthereum(bytes32 transactionId,address token, address to, uint256 amount) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;
        address polyToken = polyMapping[token];
        require(polyToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(polyToken).transfer(proxyAddr, amount);
        emit TransferFromEthereum(to, proxyAddr, token, polyToken, amount,transactionId);
	}

    function addWhiteAddress(address userProxy, bool value) public  onlyOwner {
        whitelisted[userProxy] = value;  
        emit WhiteList(userProxy,value); 
    }


    function setBridgeFeeOfToken(address polyToken,address bridgeFeeVault,uint256 fee,address aggregator) public onlyOwner {
        BridgeFeeConfig[polyToken].fee = fee;
        BridgeFeeConfig[polyToken].bridgeFeeVault = bridgeFeeVault;
        BridgeFeeConfig[polyToken].aggregator = aggregator;
        emit SetFee(polyToken,fee,bridgeFeeVault,aggregator);
    }

    function getBridgeFee(address polyToken, uint256 amount) public view returns (uint256,address) {
        uint256 fee = BridgeFeeConfig[polyToken].fee;
        address bridgeFeeVault = BridgeFeeConfig[polyToken].bridgeFeeVault;
        address aggregator = BridgeFeeConfig[polyToken].aggregator;
        require(bridgeFeeVault != address(0), "unknow bridgeFeeVault");
        if (fee == 0) {
            return (0, bridgeFeeVault);
        }
        uint256 fee_amount = amount.mul(fee).div(10000);// ETH/token, token/ETH
        uint256 price = IAggregator(aggregator).latestAnswer(polyToken);
        uint256 ethUnit = 1*10**18;
        if (ethUnit.mul(max).div(100).mul(10**IERC20(polyToken).decimals()).div(price) < fee_amount){//>max e
            return (ethUnit.mul(max).div(100).mul(10**IERC20(polyToken).decimals()).div(price), bridgeFeeVault);
        } else if (ethUnit.mul(min).div(100).mul(10**IERC20(polyToken).decimals()).div(price) > fee_amount){//<min e
            return (ethUnit.mul(min).div(100).mul(10**IERC20(polyToken).decimals()).div(price), bridgeFeeVault);
        } else {
            return (fee_amount, bridgeFeeVault);
        }
    }


    function setThreshold(uint256  _max, uint256 _min) public  onlyOwner {
        require(_max > _min, "max should be > min");
        require(max <= 100, "max should be <= 100");
        require(min >= 0, "min should be >= 0");
        max = _max;
        min = _min;
        emit SetThreshold(max,min); 
    }



}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }
        /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

        function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);


    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address spender, uint256 amount) external ;
    function burn(address spender, uint256 amount) external ;
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner) external returns (address proxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function owner() external view returns (address);
    function initialize(address,bytes32) external;
    function execTransaction(address,uint256,bytes calldata,Operation, uint256 nonce,bytes memory) external;
    function execTransaction(address,uint256,bytes calldata,Operation) external;
}