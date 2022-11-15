pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./Proposal.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IProtocolSettings.sol";
import "../utils/OpenZeppelinOwnable.sol";


contract ProtocolSettingsProposal is Proposal, OpenZeppelinOwnable {

    bytes[] executionBytes;

    function setExecutionBytes(bytes[] memory _executionBytes) onlyOwner public {
        executionBytes = _executionBytes;
    }

    function getExecutionBytes() public view returns (bytes[] memory) {
        return executionBytes;
    }

    function getExecutionBytesSize() public view returns (uint) {
        return executionBytes.length;
    }

    function getName() public override view returns (string memory) {

        return "Protocol Settings Mangement Operation";
    }

    function execute(IProtocolSettings _settings) public override {
        require(executionBytes.length > 0, "no functions to call");
        for (uint i=0; i< executionBytes.length; i++) {
            (bool success, ) = address(_settings).call(executionBytes[i]);
            require(success == true, "failed to sucessfully execute");
        }
    }

    function executePool(IERC20 pool) public override {
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.6.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract OpenZeppelinOwnableContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.6.0;

import "./OpenZeppelinOwnableContext.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OpenZeppelinOwnable is OpenZeppelinOwnableContext {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IProtocolSettings {
	function getCreditWithdrawlTimeLock() external view returns (uint);
    function updateCreditWithdrawlTimeLock(uint duration) external;
	function checkPoolBuyCreditTradable(address poolAddress) external view returns (bool);
	function checkUdlIncentiveBlacklist(address udlAddr) external view returns (bool);
	function checkDexAggIncentiveBlacklist(address dexAggAddress) external view returns (bool);
    function checkPoolSellCreditTradable(address poolAddress) external view returns (bool);
	function applyCreditInterestRate(uint value, uint date) external view returns (uint);
	function getSwapRouterInfo() external view returns (address router, address token);
	function getSwapRouterTolerance() external view returns (uint r, uint b);
	function getSwapPath(address from, address to) external view returns (address[] memory path);
    function getTokenRate(address token) external view returns (uint v, uint b);
    function getCirculatingSupply() external view returns (uint);
    function getUdlFeed(address addr) external view returns (int);
    function setUdlCollateralManager(address udlFeed, address ctlMngr) external;
    function getUdlCollateralManager(address udlFeed) external view returns (address);
    function getVolatilityPeriod() external view returns(uint);
    function getAllowedTokens() external view returns (address[] memory);
    function setDexOracleTwapPeriod(address dexOracleAddress, uint256 _twapPeriod) external;
    function getDexOracleTwapPeriod(address dexOracleAddress) external view returns (uint256);
    function setBaseIncentivisation(uint amount) external;
    function getBaseIncentivisation() external view returns (uint);
    function getProcessingFee() external view returns (uint v, uint b);
    function getMinShareForProposal() external view returns (uint v, uint b);
    function isAllowedHedgingManager(address hedgeMngr) external view returns (bool);
    function isAllowedCustomPoolLeverage(address poolAddr) external view returns (bool);
    function exchangeTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IProtocolSettings.sol";
import "../interfaces/IERC20.sol";


abstract contract Proposal {

    function getName() public virtual view returns (string memory);

    function execute(IProtocolSettings _settings) public virtual;

    function executePool(IERC20 _llp) public virtual;
}