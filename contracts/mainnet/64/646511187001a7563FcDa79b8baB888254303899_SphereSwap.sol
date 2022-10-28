// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ISphereSwap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IVesting.sol";

/**
 * @title SphereSwap
 * @author Kamanchi
 * @notice This SC using for exchange ERC20 stablecoins
 * on 'SWORK' token
 */
contract SphereSwap is ISphereSwap, ReentrancyGuard, Ownable {
    using Strings for uint256;

    IVesting public sphereVesting;

    uint256 public indexOfLastAddress;

    mapping(uint256 => address) public stableCoinAddresses;

    constructor(
        address owner_,
        address stablecoinAddress_,
        address stablecoinAddress2_,
        address sphereVesting_
    ) {
        _transferOwnership(owner_);
        stableCoinAddresses[0] = stablecoinAddress_;
        stableCoinAddresses[0] = stablecoinAddress2_;
        sphereVesting = IVesting(sphereVesting_);
    }

    /**
     * @dev 'swapTokens' allows swap 'sellToken_' on 'buyToken_'
     * by check amounts of tokens which 'this' contract can managed
     *
     * @param sellToken_ - The address of the token that the user gives
     * @param amountTokensToSwap_ - how many 'sellToken_' user want to exchange
     *
     * NOTE: transfer will be success only if user approved tokens for managed by 'this' contract
     */
    function swapTokens(
        address sellToken_,
        uint256 amountTokensToSwap_,
        uint256 allocation_
    ) external nonReentrant returns (bool swapStatus_) {
        require(
            sellToken_ != address(0),
            "SphereSwap: contract address can't be 0"
        );
        require(
            amountTokensToSwap_ != 0,
            "SphereSwap: you can't exchange 0 tokens"
        );
        require(
            checkSellTokenAddress(sellToken_),
            "SphereSwap: 'sellToken_' , not matched !"
        );
        IERC20 sellToken = IERC20(sellToken_);
        uint256 amountTokensToBuy;
        uint256 activeAllocation = uint256(sphereVesting.currentAllocation());
        require(
            activeAllocation == allocation_,
            "SphereSwap: allocation type is not correct !"
        );
        uint256 price;
        if (activeAllocation == 0) {
            price = 0.02 ether;
        }
        if (activeAllocation == 1) {
            price = 0.05 ether;
        }
        if (IERC20Metadata(sellToken_).decimals() == 6) {
            require(
                bytes(amountTokensToSwap_.toString()).length >= 6,
                "SphereSwap: min value of this 'sellToken_' is 10 cents"
            );
            amountTokensToBuy = (amountTokensToSwap_ * 1e30) / price;
        } else {
            amountTokensToBuy = (amountTokensToSwap_ * 1e18) / price;
        }
        uint256 amountOfApprovedSellToken = sellToken.allowance(
            msg.sender,
            address(this)
        );
        require(
            amountOfApprovedSellToken >= amountTokensToSwap_ &&
                amountOfApprovedSellToken != 0,
            "SphereSwap : approve more tokens to success swap"
        );
        require(
            amountTokensToBuy >= 10e18,
            "SphereSwap : you can't by less then 10 tokens"
        );
        sellToken.transferFrom(msg.sender, owner(), amountTokensToSwap_);
        sphereVesting.addInvestor(
            msg.sender,
            amountTokensToBuy,
            IVesting.AllocationType(allocation_)
        );
        return true;
    }


    /**
     * @dev functions delete contract address from mappings
     * with confirmation stablecoin adresses
     *
     * @param indexOfStableAddress_ - input index of stablecoin address
     *
     * NOTE: by default index 0 - 'USDT'
     */
    function deletePair(uint256 indexOfStableAddress_) external onlyOwner {
        delete stableCoinAddresses[indexOfStableAddress_];
    }

    /**
     * @dev functions allows owner add new address of ERC20
     * stablecoins for using them in exchange transactions
     *
     * @param sellToken_ - take address of new stablecoin contract
     * @param indexForStablecoin_ - under what number will the address be stored
     *
     * NOTE: by default index 0 - 'USDT'
     */
    function createPair(address sellToken_, uint256 indexForStablecoin_)
        public
        override
        onlyOwner
    {
        require(
            sellToken_ != address(0),
            "SphereSwap : 'sellToken_' , can't be 0"
        );
        stableCoinAddresses[indexForStablecoin_] = sellToken_;
        indexOfLastAddress = indexForStablecoin_;
    }

    /**
     * @dev internal function to check is 'sellToken_' address
     * match with list of confirmed addresses of stablecoins
     *
     * NOTE: be carefull function using loops !
     */
    function checkSellTokenAddress(address sellToken_)
        internal
        view
        returns (bool)
    {
        bool isMatched;
        for (uint256 i = 0; i <= indexOfLastAddress; i++) {
            if (stableCoinAddresses[i] == sellToken_) {
                isMatched = true;
                break;
            } else {
                isMatched = false;
            }
        }
        return isMatched;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title ISphereSwap
 * @author Kamanchi
 * @notice This SC using for exchange ERC20 stablecoins
 * on 'SWORK' token
 */
interface ISphereSwap {

    /**
     * @dev 'swapTokens' allows swap 'sellToken_' on 'buyToken_'
     * by check amounts of tokens which 'this' contract can managed
     *
     * @param sellToken_ - The address of the token that the user gives
     * @param amountTokensToSwap_ - how many 'sellToken_' user want to exchange
     *
     * NOTE: transfer will be success only if user approved tokens for managed by 'this' contract
     */
    function swapTokens(
        address sellToken_,
        uint256 amountTokensToSwap_,
        uint256 allocation_
    ) external returns (bool swapStatus_);

    /**
     * @dev functions delete contract address from mappings
     * with confirmation stablecoin adresses
     *
     * @param indexOfStableAddress_ - input index of stablecoin address
     *
     * NOTE: by default index 0 - 'USDT'
     */
    function deletePair(uint256 indexOfStableAddress_) external;

    /**
     * @dev functions allows owner add new address of ERC20
     * stablecoins for using them in exchange transactions
     *
     * @param sellToken_ - take address of new stablecoin contract
     * @param indexForStablecoin_ - under what number will the address be stored
     *
     * NOTE: by default index 0 - 'USDT'
     */
    function createPair(address sellToken_, uint256 indexForStablecoin_)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IVesting {
    /**
     * @dev Store info about beneficiaries
     * @param rewardPaid - update every time when call 'withdraw'
     * @param amountToReward - total amount of tokens which will be available
     * for investor
     * @param allocationType - contain in which round beneficiary invested
     * @param vestingStartDate - contain time of start vesting period
     * @param vestingEndDate - contain time of end vesting period
     */
    struct Investor {
        uint256 amountToReward;
        uint256 vestingStartDate;
        uint256 vestingEndDate;
        uint256 rewardPaid;
        AllocationType allocation;
    }

    struct Allocation {
        uint256 maxTokenSupply;
        uint256 vestingTerm;
        uint256 currentTotalRewards;
        uint256 cliffTerm;
    }

    /**
     * @dev enum contain allocation type
     *
     * NOTE : use for calculate 'initialReward'
     */
    enum AllocationType {
        SEED,
        PRIVATE,
        TEAM,
        CREATOR,
        ECOSYSTEM,
        ADVISORS
    }

    /**
     * @dev event logs info about date when vesting is start
     *
     * @param startDate - time when vesting period is started
     */
    event SetInitialTime(uint256 startDate);

    /**
     * @dev event logs info about date when vesting is start
     *
     * @param investors - list of investors
     * @param balances - list of balances for investors
     * @param allocations - list of allocations types
     */
    event AddInvestors(
        address[] investors,
        uint256[] balances,
        AllocationType[] allocations
    );

    /**
     * @dev event logs info about withdraw transaction
     *
     * @param to - whos withdraw tokens
     * @param amountTokens - how many tokens will be withdraw
     */
    event Withdraw(address to, uint256 amountTokens);

    /**
     * @dev function allow withdraw tokens for beneficiaries
     *
     * NOTE : function has no params take address from global
     * 'msg.sender'
     */
    function addInvestor(
        address investorAddress_,
        uint256 amountOfTokens_,
        AllocationType allocationType_
    ) external;

    /**
     * @dev function set investors param
     *
     * @param investorAddress_ - contain list of investors address
     * @param amountOfTokens_ - contain how many tokens investor must claim
     * @param allocationType_ - contain in which round investor buy tokens
     *
     * NOTE : function can call only owner of SC , transfer sum of 'amounts_'
     * to this contract address
     */
    function addInvestorsByOwner(
        address[] calldata investorAddress_,
        uint256[] calldata amountOfTokens_,
        AllocationType[] calldata allocationType_
    ) external;

    function allocationTerms(AllocationType allocationType_)
        external
        view
        returns (Allocation memory);

    //provereno
    function investorsInfo(address investor_)
        external
        view
        returns (Investor memory);

    function vestingStatusManage(bool newStatus_) external;

    function changeSwapContract(address newAddress_) external;

    /**
     * @dev function allow withdraw tokens for beneficiaries
     *
     * NOTE : function has no params take address from global
     * 'msg.sender'
     */
    function withdraw() external;

    function revoke() external;

    function currentAllocation() external view returns (AllocationType);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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