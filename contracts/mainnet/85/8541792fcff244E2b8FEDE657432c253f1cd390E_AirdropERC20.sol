/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/Airdrop.sol


pragma solidity 0.8.17;



interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

contract AirdropERC20 is Context, ReentrancyGuard {

    event PriceChanged(uint256 current, uint256 updated);
    event AirDropped(address wallet, uint256 amountCbys);

    address public owner;
    uint256 public perTreeCby = 10 * 10**18;

    modifier onlyOwner() {
        require(_msgSender() == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        owner = _msgSender();
    }

    /**
    @notice Updates the price of CBY per tree set by the contract owner
    @param amount The new price of CBY per tree
    @dev Only the contract owner can call this function
    @dev The amount of CBY per tree cannot be set to 0
    @dev Emits a PriceChanged event with the old and new price
    */
    function setPerTreeCby(uint256 amount) external onlyOwner {
        require(amount > 0, "Cby amount cannot be 0");

        uint256 curPrice = perTreeCby;
        perTreeCby = amount;

        emit PriceChanged(curPrice, amount);
    }

    /**
    @notice Airdrops CBY tokens to multiple users based on the number of trees owned by them
    @param users An array of addresses representing the users who will receive the CBY tokens
    @param amountTrees An array of integers representing the number of trees owned by each user
    @param totalTrees The total number of trees to be considered for the airdrop
    @param wallet The address of the wallet from where the CBY tokens will be transferred
    @param erc20 The address of the CBY token contract
    @dev Only the contract owner can call this function
    @dev The total number of trees to be considered for the airdrop cannot be 0
    @dev The length of the users and amountTrees arrays must be same
    @dev The wallet and CBY token addresses cannot be 0
    */
    function dropCby(address[] calldata users, uint256[] calldata amountTrees, uint256 totalTrees, address wallet, address erc20) external onlyOwner {
        require(totalTrees > 0, "Total number of Trees cannot be 0");
        require(users.length == amountTrees.length, "Discrepancy in Arrays");
        require(wallet != address(0) && erc20 != address(0), "Parameter addresses cannot be 0");

        // Initializing CBY contract
        IERC20 cby = IERC20(erc20);
        uint256 totalCbyToDrop = perTreeCby * totalTrees;

        // Checking if CBYs can be transfered before going to loop
        require(cby.balanceOf(wallet) >= totalCbyToDrop, "Wallet doesn't have enough CBYs to drop");
        require(cby.allowance(wallet, address(this)) >= totalCbyToDrop, "Not enough CBYs allowed to airdrop address");

        uint256 treesSum;

        // Transfering cbys to batch of the holders
        for (uint256 i = 0; i < users.length; i++) {
            require (users[i] != address(0) && amountTrees[i] != 0, "Parameter addresses cannot be 0 for Amount & Address");
            cby.transferFrom(wallet, users[i], amountTrees[i] * perTreeCby);
            treesSum += amountTrees[i];
        }
        require(treesSum == totalTrees, "Total trees amount is not equal to sum of amounts in array");

        emit AirDropped(wallet, totalTrees * perTreeCby);
    }
}