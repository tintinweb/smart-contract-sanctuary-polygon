/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IRaffle is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract RaffleDistributor is Context, Pausable {
    mapping(address => bool) private _owner;

    uint256 public MINT_PUBLIC_PRICE = 0.0001 ether;
    uint8 public constant MAX_RAFFLE_PER_ADDRESS = 20;

    address public RAFFLE_TICKET_ADDRESS;
    address public VAULT;

    bool public distributionstatus;

    event RaffleDistributionStarted();
    event RaffleDistributionEnded();
    event RaffleTokenAddressUpdated();
    event VaultAddressUpdated();

    event Bought(address, uint256 amount);

    constructor(address raffleaddr, address vaultaddr) {
        _owner[address(0x3BC14f7b6c5871994CAAfDcc5Fd42d436b6f4286)] = true;
        _owner[address(0x616A9B8bfAf2189f7B896EDC75C9AF67af89Df93)] = true;
        RAFFLE_TICKET_ADDRESS = raffleaddr;
        VAULT = vaultaddr;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), " caller is not the owner");
        _;
    }

    modifier whenRaffleAllowed() {
        require(
            distributionstatus,
            "RaffleDistributor#whenRaffleAllowed: Raffle sale not open"
        );
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function startRaffleDistribution() public onlyOwner {
        distributionstatus = true;
        emit RaffleDistributionStarted();
    }

    function stopRaffleDistribution() public onlyOwner {
        distributionstatus = false;
        emit RaffleDistributionEnded();
    }

    function setRaffleTokenAddress(address raffleaddr) public onlyOwner {
        RAFFLE_TICKET_ADDRESS = raffleaddr;
        emit RaffleTokenAddressUpdated();
    }

    function setVaultAddress(address vaultaddr) public onlyOwner {
        VAULT = vaultaddr;
        emit VaultAddressUpdated();
    }

    function buy(uint256 quantity)
        external
        payable
        whenNotPaused
        whenRaffleAllowed
        returns (bool)
    {
        require(
            msg.value == MINT_PUBLIC_PRICE * quantity,
            "RaffleDistributor#buy: Price does not match"
        );
        uint256 balance = IRaffle(RAFFLE_TICKET_ADDRESS).balanceOf(_msgSender());
        require(
            balance + quantity <= MAX_RAFFLE_PER_ADDRESS,
            "RaffleDistributor#buy: Max Raffle Buy Limit Exceeded"
        );
        (bool sent, ) = VAULT.call{value: msg.value}("");
        require(sent, "RaffleDistributor#buy: Payment Failed ");
        require(IRaffle(RAFFLE_TICKET_ADDRESS).mint(_msgSender(), quantity));
        emit Bought(_msgSender(), quantity);
        return true;
    }
}