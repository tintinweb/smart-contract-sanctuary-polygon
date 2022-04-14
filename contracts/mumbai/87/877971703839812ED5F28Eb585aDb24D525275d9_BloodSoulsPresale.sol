// contracts/BloodSoul.sol
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/access/Ownable.sol";
import "../external/openzeppelin/contracts/interfaces/IERC20.sol";
import "../external/openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

interface IBloodSouls is IERC20, IERC20Burnable {
    function updateLockTiers(uint256[] calldata _lockDurations, uint256 _boostDivisor, uint256[] calldata _lockTiers) external;
    function getLockLevelAndBoost(address target) external view returns(uint256, uint256);
    function setDAOAddress(address daoContractAddress) external;
}

contract BloodSoulsPresale is Ownable, ReentrancyGuard {
    IBloodSouls souls;

    struct SaleState {
        /// @notice Cost to mint each token
        uint256 tokenFeePresale;
        uint256 tokenFee;
        bool saleActive;
        bool presaleActive;
    }
    SaleState saleState;

    mapping(address => bool) public presaleList;
    mapping(address => uint) public tokensPurchased;

    uint public immutable MAX_PER_ADDRESS = 1500000 * 10**uint(18);

    constructor(IBloodSouls _token, bool _isTestNet){
        souls = _token;
        saleState.tokenFeePresale = _isTestNet ? 11000 : 110; //Tokens per matic during presale (0.009 Matic per token)
        saleState.tokenFee = _isTestNet ? 10000 : 100; //Tokens per matic (0.01 Matic per Token)
        saleState.saleActive = false;
        saleState.presaleActive = true;
    }

    function getActiveRate() public view returns(uint256){
        return (saleState.presaleActive ? saleState.tokenFeePresale : (saleState.saleActive ? saleState.tokenFee : 0));
    }

    function setPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleList[addresses[i]] = true;
        }
    }

    function addPresaleAddress(address _address) external onlyOwner {
        presaleList[_address] = true;
    }

    function remainingBalance() public view returns(uint256) {
        return souls.balanceOf(address(this));
    }

    function purchase(uint256 tokens) external payable nonReentrant {
        unchecked {
            tokens = tokens * 10**uint(18);

            uint256 ticketsPurchasedCount = tokensPurchased[msg.sender];
            require(tokens <= remainingBalance(), "Exceeded remaining supply!");
            require((ticketsPurchasedCount + tokens) <= MAX_PER_ADDRESS, "Exceeded maximum purchases for wallet address!");
            // Ensure sufficient raffle ticket payment
            require(msg.value >= (tokens * getActiveRate()), string(abi.encodePacked("Incorrect payment: ", UintToString(msg.value), " < ", UintToString(tokens * getActiveRate()))));

            if(saleState.presaleActive){
                require(presaleList[msg.sender] != false, "Address is not part of the presale list.");
            }else{
                require(saleState.saleActive, "Sales are not active, check with the developers for details.");
            }
            
            tokensPurchased[msg.sender] += tokens;
            souls.transfer(msg.sender, tokens);
        }
    }

    function UintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Allows contract owner to withdraw proceeds of the token sales. This will allow us to then move the funds into the dex.
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Burn all remaining tokens
    function burnRemainingTokens() external onlyOwner {
        souls.burn(souls.balanceOf(address(this)));
        saleState.saleActive = false;
        saleState.presaleActive = false;
    }

    /// @notice Withdraw remaining tokens into the owner's wallet. This is to allow us to flexibly deploy these as rewards if needed.
    function withdrawRemainingTokens() external onlyOwner {
        souls.transfer(msg.sender, souls.balanceOf(address(this)));
        saleState.saleActive = false;
        saleState.presaleActive = false;
    }

    /// @notice Allows contract owner to pause sales
    function disableSale() external onlyOwner {
        saleState.saleActive = false;
        saleState.presaleActive = false;
    }

    /// @notice Allows contract owner to enable sales
    function enableSale(bool isPresale) external onlyOwner {
        saleState.saleActive = !isPresale;
        saleState.presaleActive = isPresale;
    }

    function areSalesActive() public view returns(bool) {
        return saleState.saleActive;
    }

    function arePreSalesActive() public view returns(bool) {
        return saleState.presaleActive;
    }

    function areSalesOrPresalesActive() public view returns(bool){
        return saleState.saleActive || saleState.presaleActive;
    }

    function isAddressWhitelisted(address target) public view returns(bool){
        return presaleList[target];
    }

    function isMyAddressWhitelisted() public view returns(bool){
        return isAddressWhitelisted(msg.sender);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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