/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/ICandyBabiesNFTMint.sol

pragma solidity ^0.8.0;

// for CandyBabiesNFTMint
interface ICandyBabiesNFTMint {

    function mint(address account) external;

    function mintBatch(address[] memory accounts) external;

    function mintBatchCountToOne(address to, uint32 count) external;

    function mintBatchCountToAccounts(address[] memory accounts, uint32 countEachAccount) external;
}


// File contracts/ICandyBabiesMint20230114.sol

pragma solidity ^0.8.0;

// for CandyBabiesMint20230114
interface ICandyBabiesMint20230114 {
    struct UserMintInfo {
        bool inSaleTime;
        uint256 fullPrice;
        uint256 payPrice;
        bool inWhitelist;
        bool isInvitee;
        uint64 startSellTime;
        uint64 endSellTime;
    }

    event Minted(
        address indexed _payer,
        uint8 _count,
        bool _isWhitelist,
        uint256 _price,
        address _inviter
    );

    function getUserMintInfo(address account, address inviter) external view returns (UserMintInfo memory);
    function mint(uint8 count, address inviter) external;
}


// File contracts/CandyBabiesMint20230114.sol

pragma solidity ^0.8.0;
contract CandyBabiesMint20230114 is ICandyBabiesMint20230114, ReentrancyGuard, Ownable, Pausable {

    struct PriceInfo {
        uint32 endTimeFromStartSell;
        uint256 price;
    }

    struct Statistics {
        uint32 mintCount;
        uint32 whitelistMintCount;
        uint256 revenue;
    }


    event WhitelistAdded(
        address[] _accounts
    );

    event WhitelistRemoved(
        address[] _accounts
    );

    address public toWallet1;
    address public toWallet2;
    uint8 public wallet2Percent = 10;
    ICandyBabiesNFTMint public nft;
    uint64 public startSellTime;
    uint64 public endSellTime;
    uint256 public whitelistPrice = 9 * 10**18;
    address public priceToken;
    uint8 public inviterRebatePercent = 5;
    uint8 public inviteeDiscountPercent = 5;
    PriceInfo[] public priceInfos;
    Statistics public statistics;
    mapping(address => bool) public whitelistMapping;


    constructor(address _nft, address _toWallet1, address _toWallet2, address _priceToken) {
        nft = ICandyBabiesNFTMint(_nft);
        toWallet1 = _toWallet1;
        toWallet2 = _toWallet2;
        priceToken = _priceToken;

        priceInfos.push(PriceInfo(3600 * 24 *3, 10 * 10**18));
        priceInfos.push(PriceInfo(3600 * 24 *5, 125 * 10**17));
        priceInfos.push(PriceInfo(3600 * 24 *7, 15 * 10**18));
    }

    modifier whenInSaleTime() {
        require(startSellTime > 0 && block.timestamp >= startSellTime, "CandyBabiesMint20230114: Not in sale time.");
        require(block.timestamp <= endSellTime, "CandyBabiesMint20230114: The sale is over.");
        _;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function modifyWallet2Percent(uint8 _wallet2Percent) public onlyOwner {
        require(_wallet2Percent <= 100, "CandyBabiesMint20230114: The wallet2 percent is more than 100.");
        wallet2Percent = uint8(_wallet2Percent);
    }

    function modifyPrice(PriceInfo[] calldata _prices) public onlyOwner {
        require(_prices.length > 0, "CandyBabiesMint20230114: The price array is empty.");
        delete priceInfos;
        for (uint inx = 0; inx < _prices.length; inx++) {
            priceInfos.push(PriceInfo(
                _prices[inx].endTimeFromStartSell,
                _prices[inx].price));
        }
    }

    function modifyWhitelistPrice(uint256 _whitelistPrice) public onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function modifySellTimeParam(
        uint64 _startSellTime,
        uint64 _endSellTime
    ) public onlyOwner {
        startSellTime = _startSellTime;
        endSellTime = _endSellTime;
    }

    function modifyInviterRebatePercent(uint8 _inviterRebatePercent) public onlyOwner {
        require(_inviterRebatePercent <= 100, "CandyBabiesMint20230114: The inviter rebate percent is more than 100.");
        inviterRebatePercent = _inviterRebatePercent;
    }

    function modifyInviteeDiscountPercent(uint8 _inviteeDiscountPercent) public onlyOwner {
        require(_inviteeDiscountPercent <= 100, "CandyBabiesMint20230114: The invitee discount percent is more than 100.");
        inviteeDiscountPercent = _inviteeDiscountPercent;
    }

    function modifyPriceToken(address _priceToken) public onlyOwner {
        priceToken = _priceToken;
    }

    function addWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint inx = 0; inx < _accounts.length; inx++) {
            whitelistMapping[_accounts[inx]] = true;
        }
        emit WhitelistAdded(_accounts);
    }

    function removeWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint inx = 0; inx < _accounts.length; inx++) {
            whitelistMapping[_accounts[inx]] = false;
        }
        emit WhitelistRemoved(_accounts);
    }

    function getPriceInfos() public view returns (PriceInfo[] memory) {
        return priceInfos;
    }

    function inWhitelist(address _account) public view returns (bool) {
        return whitelistMapping[_account];
    }

    function getUserMintInfo(address account, address inviter) override public view returns (UserMintInfo memory) {
        bool inSaleTime = startSellTime > 0 &&
                block.timestamp >= startSellTime &&
                block.timestamp <= endSellTime;
        bool isWhitelist = inWhitelist(account);
        bool isInvitee = inviter != address(0) && inviter != account;
        uint256 fullPrice = 0;
        uint256 payPrice = 0;
        if (inSaleTime) {
            require(priceInfos.length > 0, "CandyBabiesMint20230114: The priceInfos is empty.");
            fullPrice = priceInfos[priceInfos.length - 1].price;
            uint256 secondsFromStartSell = block.timestamp - startSellTime;
            for (uint inx = 0; inx < priceInfos.length; inx++) {
                if (secondsFromStartSell < priceInfos[inx].endTimeFromStartSell) {
                    fullPrice = priceInfos[inx].price;
                    break;
                }
            }
            require(fullPrice > 0, "CandyBabiesMint20230114: The price is 0.");
            if (isWhitelist) {
                fullPrice = whitelistPrice;
                payPrice = fullPrice;
            } else {
                if (isInvitee) {
                    payPrice = fullPrice * (100 - inviteeDiscountPercent) / 100;
                } else {
                    payPrice = fullPrice;
                }
            }
        }
        
        return UserMintInfo(
            inSaleTime,
            fullPrice,
            payPrice,
            inWhitelist(account),
            isInvitee,
            startSellTime,
            endSellTime
        );
    }

    function mint(uint8 count, address inviter) override external
            whenNotPaused
            whenInSaleTime
            nonReentrant {
        require(count > 0, "CandyBabiesMint20230114: The count is 0.");
        require(inviter != msg.sender, "CandyBabiesMint20230114: The inviter is the same as the sender.");
        UserMintInfo memory info = getUserMintInfo(msg.sender, inviter);
        uint256 totalPayPrice = info.payPrice * count;
        uint256 totalInviterRebate = 0;
        if (info.isInvitee) {
            totalInviterRebate = info.fullPrice * count * inviterRebatePercent / 100;
        }
        uint256 revenue = totalPayPrice - totalInviterRebate;
        require(revenue > 0, "CandyBabiesMint20230114: The revenue is 0.");
        uint256 wallet2Revenue = revenue * wallet2Percent / 100;
        if (totalInviterRebate > 0) {
            IERC20(priceToken).transferFrom(msg.sender, inviter, totalInviterRebate);
        }
        IERC20(priceToken).transferFrom(msg.sender, toWallet1, revenue - wallet2Revenue);
        IERC20(priceToken).transferFrom(msg.sender, toWallet2, wallet2Revenue);
        
        nft.mintBatchCountToOne(msg.sender, count);

        statistics.mintCount += count;
        if (info.inWhitelist) {
            statistics.whitelistMintCount += count;
        }
        statistics.revenue += revenue;
        emit Minted(msg.sender, count, info.inWhitelist, info.payPrice, inviter);
    }
}