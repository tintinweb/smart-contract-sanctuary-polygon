// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract polygonOffRampContract is
    Pausable,
    Ownable,
    AutomationCompatibleInterface
{
    event TokenFundsDeposited(
        address indexed tokenDeposited,
        address indexed addressDeposited,
        uint256 amountDeposited
    );
    event TokenFundsWithdrawn(
        address indexed tokenWithdrawn,
        address indexed withdrawAddress,
        uint256 amountWithdrawn
    );
    event FundsWithdrawn(
        address indexed withdrawAddressNative,
        uint256 amountWithdrawnNative
    );
    event UniqueTokenAdded(address indexed addedToken);
    event contractTokenBalanceAdjusted(address indexed token, uint256 amount);
    uint256 minimumDepositAmount;
    uint256 maximumDepositAmount;
    uint256 triggerWithdrawAmount;
    address[] public allowedTokensAddresses;
    mapping(address => uint256) public contractTokenBalances;
    mapping(address => bool) public tokenIsAllowed;
    mapping(address => bool) public tokenTriggerAmountReached;
    mapping(address => address) public tokenPriceFeed;

    constructor() {
        minimumDepositAmount = 10; // $10
        maximumDepositAmount = 1000; // $1000
        triggerWithdrawAmount = 50; // $50
    }

    function getAddressLength() public view returns (uint256) {
        return allowedTokensAddresses.length;
    }

    function setMinimumDepositAmount(uint256 _amount) public onlyOwner {
        minimumDepositAmount = _amount;
    }

    //so as to adjust the maximum deposit amount in depending on available liqiudity
    function setMaximumDepositAmount(
        uint256 _amount
    ) public whenNotPaused onlyOwner {
        maximumDepositAmount = _amount;
    }

    // at what price should the contract trigger a withdraw in dollars
    function setTriggerWithdrawAmount(
        uint256 _amount
    ) public whenNotPaused onlyOwner {
        triggerWithdrawAmount = _amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addAllowedToken(
        address _token,
        address _priceFeedAddress
    ) public onlyOwner {
        require(!tokenIsAllowed[_token], "token Already Exists");
        allowedTokensAddresses.push(_token);
        tokenIsAllowed[_token] = true;
        tokenTriggerAmountReached[_token] = false;
        tokenPriceFeed[_token] = _priceFeedAddress;
        emit UniqueTokenAdded(_token);
    }

    // get the lastest price of the token
    function getLatestPrice(address _token) public view returns (uint256) {
        address _priceFeed = tokenPriceFeed[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    function minimumTokenDepositAmount(
        address _token
    ) public view returns (uint256) {
        uint256 price = getLatestPrice(_token);
        // the price is scale up by 10**8
        uint256 tokenAmount = (minimumDepositAmount * 1e26) / price;
        return tokenAmount;
    }

    function maximumTokenDepositAmount(
        address _token
    ) public view returns (uint256) {
        uint256 price = getLatestPrice(_token);
        // the price is scale up by 10**8
        uint256 tokenAmount = (maximumDepositAmount * 1e26) / price;
        return tokenAmount;
    }

    // depending on  the triggerWithdrawAmount dollar price, how much token should be withdrawn
    function triggerTokenWithdrawAmount(
        address _token
    ) public view returns (uint256) {
        uint256 price = getLatestPrice(_token);
        uint256 tokenAmount = (triggerWithdrawAmount * 1e26) / price;
        return tokenAmount;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // first number of tokens requiring upkeep
        uint256 counter;
        for (uint256 i = 0; i < allowedTokensAddresses.length; i++) {
            address token = allowedTokensAddresses[i];
            if (
                contractTokenBalances[token] > triggerTokenWithdrawAmount(token)
            ) {
                counter++;
            }
        }
        // initialize an array tokenAddress requiring upkeep
        address[] memory tokens = new address[](counter);
        upkeepNeeded = false;
        uint256 indexCounter;
        for (uint256 i = 0; i < allowedTokensAddresses.length; i++) {
            address token = allowedTokensAddresses[i];
            require(
                tokenTriggerAmountReached[token] == false,
                "token has not been withdrawn yet"
            );
            if (
                contractTokenBalances[token] > triggerTokenWithdrawAmount(token)
            ) {
                upkeepNeeded = true;
                // store the index of the token which needs to be withdrawn
                tokens[indexCounter] = token;
                indexCounter++;
            }
        }
        performData = abi.encode(tokens);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(
        bytes calldata performData
    ) external override whenNotPaused {
        address[] memory tokens = abi.decode(performData, (address[]));
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(
                contractTokenBalances[token] >
                    triggerTokenWithdrawAmount(token),
                "Token hasn't reached trigger amount"
            );
            require(
                tokenTriggerAmountReached[token] == false,
                "token has not been withdrawn yet"
            );
            IERC20(token).transfer(owner(), contractTokenBalances[token]);
        }
    }

    function depositToken(address _token, uint256 _amount) public {
        require(tokenIsAllowed[_token], "the token is not currently allowed");
        require(
            _amount >= minimumTokenDepositAmount(_token),
            "amount less than minimum allowed withdraw"
        );
        require(
            _amount <= maximumTokenDepositAmount(_token),
            "amount more than maximum allowed withdraw"
        );
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] += _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        emit TokenFundsDeposited(_token, _msgSender(), _amount);
    }

    function withdrawToken(
        address _withdrawerAddress,
        address _token
    ) public onlyOwner whenNotPaused {
        require(tokenIsAllowed[_token], "the token is currently not allowed");
        require(
            IERC20(_token).balanceOf(address(this)) >= 0,
            "insufficient tokens available in the contract"
        );
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_withdrawerAddress, _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] = 0;
        tokenTriggerAmountReached[_token] = false;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        emit TokenFundsWithdrawn(_token, _withdrawerAddress, _amount);
    }
}