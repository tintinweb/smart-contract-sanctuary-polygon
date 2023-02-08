// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDIVIDENDS.sol";
import "../interfaces/ISELLER.sol";
import "../interfaces/ITOKENHOLDINGS.sol";

interface ERC20CUSTOM {
    function totalSupply() external view returns (uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns(uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}

contract Dividends is IDIVIDENDS, Pausable, Ownable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    mapping(address => mapping(uint256 => uint256)) private s_amountSnapshots; 
    mapping(address => uint256) private s_totalAmount;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    constructor(address p_addressManager) {
        _transferOwnership(p_addressManager);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // => View functions

    function amountSnapshots(address p_contractHoldings, uint256 p_idSnapshot) public view override returns(uint256) { 
        return s_amountSnapshots[p_contractHoldings][p_idSnapshot];
    }

    function totalAmountSnapshots(address p_contractHoldings) public view override returns(uint256) { 
        return s_totalAmount[p_contractHoldings];
    }

    function amountSnapshotsAccount(address p_contractHoldings, address p_account, uint256 p_snapshotId) public view override returns(uint256, bool) { 
        uint256 balanceAccount = ERC20CUSTOM(p_contractHoldings).balanceOfAt(p_account, p_snapshotId);
        uint256 totalSupply = ERC20CUSTOM(p_contractHoldings).totalSupplyAt(p_snapshotId); 
        
        if (balanceAccount == 0) { return (0, true); }

        // (walletBalance / totalSupply) * totalEarnings
        uint256 amountDividendsAccount = (balanceAccount / totalSupply) * s_amountSnapshots[p_contractHoldings][p_snapshotId];

        return (amountDividendsAccount, ITOKENHOLDINGS(p_contractHoldings).snapshotUsed(p_account, p_snapshotId));
    }

    // => Set functions

    function setPause(bool p_pause) public onlyOwner override { 
        if (p_pause) {
            _pause();
        } else {
            _unpause();
        }
    } 

    function addDividends(address p_origin, address p_contractHoldings, uint256 p_amount, uint256 p_year, bool p_withholding) public onlyOwner override {
        uint256 idSnapshot = ITOKENHOLDINGS(p_contractHoldings).snapshot(p_year, p_withholding);
        s_amountSnapshots[p_contractHoldings][idSnapshot] = p_amount;
        s_totalAmount[p_contractHoldings] += p_amount;
        

        (address addressStableCoin, , ) = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).stableCoin(); 
        require(
            IERC20(addressStableCoin).transferFrom(p_origin, address(this), p_amount),
            "Error transfer from origin"
        );

        emit AddDividends(p_contractHoldings, p_amount, s_totalAmount[p_contractHoldings]);
    }

    function claimDividends( 
        address p_contractHoldings, 
        address p_contractSeller, 
        uint256 p_amountReinvest,
        uint256 p_idSnapshot
    ) public whenNotPaused override {
        require(!ITOKENHOLDINGS(p_contractHoldings).snapshotUsed(msg.sender, p_idSnapshot), "Error snapshot id already used");
        require(ITOKENHOLDINGS(p_contractHoldings).snapshotUse(msg.sender, p_idSnapshot), "Error set snapshot id");

        uint256 balanceAccount = ERC20CUSTOM(p_contractHoldings).balanceOfAt(msg.sender, p_idSnapshot);
        uint256 totalSupply = ERC20CUSTOM(p_contractHoldings).totalSupplyAt(p_idSnapshot); 

        require(balanceAccount > 0, "Error balance account");
        // (walletBalance / totalSupply) * totalEarnings
        uint256 amountDividendsAccount = (balanceAccount / totalSupply) * s_amountSnapshots[p_contractHoldings][p_idSnapshot];

        require(p_amountReinvest <= amountDividendsAccount, "Error (max) balances");

        (address addressStableCoin, , ) = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).stableCoin();

        if (p_amountReinvest < amountDividendsAccount) {
            uint256 diff = amountDividendsAccount - p_amountReinvest;
            require(IERC20(addressStableCoin).transfer(msg.sender, diff), "Error transfer dividends");
            emit ClaimDividends(msg.sender, diff); 
        }

        if (p_amountReinvest > 0) {
            (address addressStableCoinReinvest, , ) = ISELLER(p_contractSeller).stableCoin();
            require(addressStableCoin == addressStableCoinReinvest, "Different stable coins");

            require(
                ISELLER(p_contractSeller).reinvest(p_amountReinvest, msg.sender), 
                "Error reinvest"
            );

            emit Reinvest(msg.sender, p_contractSeller, p_amountReinvest); 
        }
    }

    function widhdrawFunds(address p_contractHoldings, address p_to) public onlyOwner override {
        uint256 amount = s_totalAmount[p_contractHoldings];
        delete s_totalAmount[p_contractHoldings];

        (address addressStableCoin, , ) = ISELLER(ITOKENHOLDINGS(p_contractHoldings).seller()).stableCoin(); 
        require(
            IERC20(addressStableCoin).transfer(p_to, amount),
            "Error transfer from dividends contract"
        );

        emit widhdrawFundsByCompany(p_contractHoldings, p_to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITOKENHOLDINGS {
    // STRUCTS
    
    struct SnapshotInfo {
        uint256 id;
        bool withholding;
    }

    // EVENTS

    event ForcedTransferStocks(address e_from, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function seller() external view returns(address);
        function getCurrentSnapshotId() external view returns(uint256);
        function snapshotsYear(uint256 p_year) external view returns(SnapshotInfo[] memory);
        function yearsWithSnapshots() external view returns(uint256[] memory);
        function amountBuyWithFiat() external view returns(uint256);
        function amountBuyWithFiatUser(address p_buyer) external view returns(uint256);
        function snapshotUsed(address p_account, uint256 p_snapshotId) external view returns(bool);

        // Set functions

        function setPause(bool p_pause) external;
        function snapshotUse(address p_account, uint256 p_snapshotId) external returns(bool);
        function snapshot(uint256 p_year, bool p_withholding) external returns(uint256);
        function incrementAmountBuyWithFiat(uint256 p_amount, address p_buyer) external returns(bool);
        function forcedTransferStocks(address p_from, address p_to) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISELLER {
    // EVENTS

    event newSale(address indexed e_client, uint256 e_amount);
    event newSaleFiat(address indexed e_client, uint256 e_amount);
    event newReinvestment(address indexed e_buyer, uint256 e_amountToken);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions

        function getMaxTime() external view returns(uint256);
        function priceAmountToken(uint256 p_amountToken) external view returns(uint256, uint256);
        function minAmountToBuy() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function balanceSeller() external view returns(uint256);
        function stableCoin() external view returns(address, string memory, string memory);
        function holdingsAddress() external view returns(address);
        function beneficiary() external view returns(address);
        function canTransferHoldings() external view returns(bool);
        function canRevertPayment() external view returns(bool);
        function amountToActiveRevertPayments() external view returns(uint256);

        // Set functions

        function setHoldingsAddress(address p_erc20) external;
        function buy(uint256 p_amountToken, address p_buyer) external;
        function buyWithoutPay(uint256 p_amountToken, address p_buyer) external;
        function buyWithFiat(uint256 p_amountToken, address p_buyer) external;
        function reinvest(uint256 p_amountToken, address p_buyer) external returns(bool);
        function sell(uint256 p_price, uint256 p_maxTime, uint256 p_minTokensBuy) external;
        function setPrice(uint256 p_price) external;
        function setMaxTime(uint256 p_maxTime) external;
        function setMinTokensBuy(uint256 p_minTokensBuy) external;
        function activeRevertPayments(address p_origin) external ;
        function revertPayment() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDIVIDENDS {
    // EVENTS 

    event AddDividends(
        address indexed e_contractHoldings, 
        uint256 e_amount,
        uint256 e_totalAmount
    ); 
    event ClaimDividends(address indexed e_holder, uint256 e_amount);
    event Reinvest(address indexed e_holder, address indexed e_seller, uint256 e_amount);
    event widhdrawFundsByCompany(address indexed e_contractHoldings, address e_to); 

    // PUBLIC FUNCTIONS

        // View functions

        function amountSnapshots(address p_contractHoldings, uint256 p_idSnapshot) external view returns(uint256);
        function totalAmountSnapshots(address p_contractHoldings) external view returns(uint256);
        function amountSnapshotsAccount(address p_contractHoldings, address p_account, uint256 p_snapshotId) external view returns(uint256, bool);

        // Set functions

        function setPause(bool p_pause) external; 
        function addDividends(address p_origin, address p_contractHoldings, uint256 p_amount, uint256 p_year, bool p_retention) external;
        function claimDividends(
            address p_contractHoldings, 
            address p_contractSeller, 
            uint256 p_amountReinvest,
            uint256 p_idSnapshot
        ) external;
        function widhdrawFunds(address p_contractHoldings, address p_to) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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