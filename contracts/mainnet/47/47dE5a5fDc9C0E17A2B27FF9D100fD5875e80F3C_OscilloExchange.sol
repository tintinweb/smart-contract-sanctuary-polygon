// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./library/LibTrade.sol";
import "./library/LibTransfer.sol";


contract OscilloExchange is OwnableUpgradeable {
    using LibTrade for LibTrade.Execution;
    using LibTransfer for IERC20;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0xc8885bf67401dce7cf0f3f7667e33f54abe0420de87d9c0bc583e63ed397cd2d;

    uint private constant GAS_ENTRANCE = 31600;
    uint private constant GAS_CALLDATA = 6000;
    uint private constant GAS_EXPECTATION = 310000;
    uint private constant GAS_MULTIPLIER_MAX = 1100;
    uint private constant GAS_MULTIPLIER_DENOM = 1000;

    uint private constant RESERVE_MAX = 2500;
    uint private constant RESERVE_DENOM = 1000000;
    uint private constant PRICE_DENOM = 1000000;

    bytes32 private _domainSeparator;

    uint private _gasMultiplier;
    mapping(uint => uint) private _fills;

    event Executed(uint indexed matchId, uint[3] askTransfers, uint[3] bidTransfers);
    event Cancelled(uint indexed matchId, LibTrade.AcceptCode code);

    modifier gasLimiter(uint calls, uint gasLimit) {
        uint gasUsed = gasleft();
        _;
        gasUsed = gasUsed - gasleft() + GAS_ENTRANCE + (GAS_CALLDATA * calls);
        require(gasLimit <= gasUsed * _gasMultiplier / GAS_MULTIPLIER_DENOM);
    }

    /** Initialize **/

    function initialize() external initializer {
        __Ownable_init();

        require(_domainSeparator == 0);
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));
        _gasMultiplier = 1080;
    }

    /** Views **/

    function toAmountQuote(address base, address quote, uint amount, uint price) public view returns (uint) {
        return amount * price * (10 ** IERC20Metadata(quote).decimals()) / PRICE_DENOM / (10 ** IERC20Metadata(base).decimals());
    }

    function toAmountsInOut(LibTrade.MatchPacked memory p) public view returns (uint[2] memory askTransfers, uint[2] memory bidTransfers) {
        uint baseUnit = 10 ** IERC20Metadata(p.base).decimals();
        uint quoteUnit = 10 ** IERC20Metadata(p.quote).decimals();

        uint bidReserve = p.amount * p.reserve / RESERVE_DENOM;
        uint askReserve = bidReserve * p.price * quoteUnit / PRICE_DENOM / baseUnit;
        uint amountQ = p.amount * p.price * quoteUnit / PRICE_DENOM / baseUnit;
        askTransfers = [p.amount, amountQ - askReserve];
        bidTransfers = [amountQ, p.amount - bidReserve];
    }

    function reserves(address base, address quote, uint amount, uint price, uint reserve) public view returns (uint askReserve, uint bidReserve) {
        bidReserve = amount * (reserve > RESERVE_MAX ? RESERVE_MAX : reserve) / RESERVE_DENOM;
        askReserve = toAmountQuote(base, quote, bidReserve, price);
    }

    function txCosts(LibTrade.MatchPacked memory p, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Metadata(p.base).decimals();
        uint txCost = gasprice * gasUsed * p.priceN / p.price / (10 ** (18 - baseDecimals));
        askTx = _fills[p.askId] == 0 ? txCost * p.price * (10 ** IERC20Metadata(p.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = _fills[p.bidId] == 0 ? txCost : 0;
    }

    function gasMultiplier() public view returns (uint) {
        return _gasMultiplier;
    }

    function acceptance(LibTrade.Execution[] memory chunk, uint gasprice) public view returns (LibTrade.Acceptance[] memory) {
        LibTrade.Acceptance[] memory accepts = new LibTrade.Acceptance[](chunk.length);
        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.Execution memory e = chunk[i];
            accepts[i].mid = e.mid;

            if (e.recover(_domainSeparator) != owner() || e.p.reserve > RESERVE_MAX) {
                accepts[i].code = LibTrade.AcceptCode.Invalid;
                continue;
            }
            if (e.p.price < e.p.askLprice || e.p.price > e.p.bidLprice) {
                accepts[i].code = LibTrade.AcceptCode.Price;
                continue;
            }

            (uint askFilled, uint bidFilled) = (_fills[e.p.askId], _fills[e.p.bidId]);
            if (e.p.askAmount < askFilled + e.p.amount) {
                accepts[i].code = LibTrade.AcceptCode.AskFilled;
                continue;
            }
            if (e.p.bidAmount < bidFilled + e.p.amount) {
                accepts[i].code = LibTrade.AcceptCode.BidFilled;
                continue;
            }

            uint amountQ = toAmountQuote(e.p.base, e.p.quote, e.p.amount, e.p.price);
            (uint askReserve, uint bidReserve) = reserves(e.p.base, e.p.quote, e.p.amount, e.p.price, e.p.reserve);
            (uint askTx, uint bidTx) = _txCosts(e.p, askFilled, bidFilled, gasprice, GAS_EXPECTATION);
            if (askReserve + askTx > amountQ || bidReserve + bidTx > e.p.amount) {
                accepts[i].code = LibTrade.AcceptCode.Cost;
                continue;
            }

            (uint[2] memory askTransfers, uint[2] memory bidTransfers) = toAmountsInOut(e.p);
            if (IERC20(e.p.base).available(e.p.askAccount, address(this)) < askTransfers[0]) {
                accepts[i].code = LibTrade.AcceptCode.AskBalance;
                continue;
            }
            if (IERC20(e.p.quote).available(e.p.bidAccount, address(this)) < bidTransfers[0]) {
                accepts[i].code = LibTrade.AcceptCode.BidBalance;
                continue;
            }

            accepts[i].askTransfers = [askTransfers[0], askTransfers[1], askTx];
            accepts[i].bidTransfers = [bidTransfers[0], bidTransfers[1], bidTx];
        }
        return accepts;
    }

    /** Interactions **/

    function execute(LibTrade.Execution[] calldata chunk, uint gasLimit) external gasLimiter(chunk.length, gasLimit) {
        uint estimation = (gasLimit == 0 ? GAS_EXPECTATION : gasLimit) / chunk.length;
        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.Execution memory e = chunk[i];

            if (IERC20(e.p.base).available(e.p.askAccount, address(this)) < e.p.amount) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.AskBalance);
                continue;
            }

            uint amountQ = e.p.amount * e.p.price * (10 ** IERC20Metadata(e.p.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Metadata(e.p.base).decimals());
            if (IERC20(e.p.quote).available(e.p.bidAccount, address(this)) < amountQ) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.BidBalance);
                continue;
            }

            if (e.recover(_domainSeparator) != owner() || e.p.reserve > RESERVE_MAX) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.Invalid);
                continue;
            }
            if (e.p.price < e.p.askLprice || e.p.price > e.p.bidLprice) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.Price);
                continue;
            }

            (uint askFilled, uint bidFilled) = (_fills[e.p.askId], _fills[e.p.bidId]);
            if (e.p.askAmount < askFilled + e.p.amount) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.AskFilled);
                continue;
            }
            if (e.p.bidAmount < bidFilled + e.p.amount) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.BidFilled);
                continue;
            }
            _fills[e.p.askId] = askFilled + e.p.amount;
            _fills[e.p.bidId] = bidFilled + e.p.amount;

            IERC20(e.p.base).safeTransferFrom(e.p.askAccount, address(this), e.p.amount);
            IERC20(e.p.quote).safeTransferFrom(e.p.bidAccount, address(this), amountQ);

            uint bidReserve = e.p.amount * e.p.reserve / RESERVE_DENOM;
            uint askReserve = bidReserve * e.p.price * (10 ** IERC20Metadata(e.p.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Metadata(e.p.base).decimals());
            (uint askTx, uint bidTx) = _txCosts(e.p, askFilled, bidFilled, tx.gasprice, estimation);
            if (askReserve + askTx > amountQ || bidReserve + bidTx > e.p.amount) {
                emit Cancelled(e.mid, LibTrade.AcceptCode.Cost);
                continue;
            }

            IERC20(e.p.quote).safeTransfer(e.p.askAccount, amountQ - askReserve - askTx);
            IERC20(e.p.base).safeTransfer(e.p.bidAccount, e.p.amount - bidReserve - bidTx);
            if (askTx > 0) IERC20(e.p.quote).safeTransfer(msg.sender, askTx);
            if (bidTx > 0) IERC20(e.p.base).safeTransfer(msg.sender, bidTx);
            emit Executed(e.mid, [e.p.amount, amountQ - askReserve, askTx], [amountQ, e.p.amount - bidReserve, bidTx]);
        }
    }

    /** Restricted **/

    function setGasMultiplier(uint multiplier) external onlyOwner {
        require(multiplier <= GAS_MULTIPLIER_MAX, "invalid multiplier");
        _gasMultiplier = multiplier;
    }

    /** Privates **/

    function _txCosts(LibTrade.MatchPacked memory p, uint askFilled, uint bidFilled, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Metadata(p.base).decimals();
        uint txCost = gasprice * gasUsed * p.priceN / p.price / (10 ** (18 - baseDecimals));
        askTx = askFilled == 0 ? txCost * p.price * (10 ** IERC20Metadata(p.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = bidFilled == 0 ? txCost : 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library LibTrade {
    bytes32 constant _MATCH_PACKED_TYPEHASH = 0x04df627645c398e9674c475563ceaae175608f0ac0d90100d0a01c2cb0dad702;

    enum AcceptCode {
        Ok,
        Invalid, Price, Cost,
        AskFilled, AskBalance, BidFilled, BidBalance
    }

    struct Acceptance {
        AcceptCode code;
        uint mid;
        uint[3] askTransfers;
        uint[3] bidTransfers;
    }

    struct Order {
        address account;
        address tokenIn;
        address tokenOut;
        uint amount;
        uint lprice;
    }

    struct MatchPacked {
        address base;
        address quote;
        uint askId;
        address askAccount;
        uint askAmount;
        uint askLprice;
        uint bidId;
        address bidAccount;
        uint bidAmount;
        uint bidLprice;
        uint amount;
        uint price;
        uint priceN;
        uint reserve;
    }

    struct Execution {
        uint mid;
        MatchPacked p;
        bytes sig;
    }

    function recover(Execution memory exec, bytes32 domainSeparator) internal pure returns (address) {
        MatchPacked memory packed = exec.p;
        bytes memory signature = exec.sig;
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 digest;

        // MatchPacked struct (14 fields) and type hash (14 + 1) * 32 = 512
        assembly {
            let dataStart := sub(packed, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _MATCH_PACKED_TYPEHASH)
            structHash := keccak256(dataStart, 480)
            mstore(dataStart, temp)
        }

        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            digest := keccak256(freeMemoryPointer, 66)
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "invalid signature 's' value");

        address signer;

        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "invalid signature 'v' value");
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "invalid signature 'v' value");
            signer = ecrecover(digest, v, r, s);
        }
        return signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibTransfer {
    function available(IERC20 token, address owner, address spender) internal view returns (uint) {
        uint _allowance = token.allowance(owner, spender);
        uint _balance = token.balanceOf(owner);
        return _allowance < _balance ? _allowance : _balance;
    }

    function safeTransfer(IERC20 token, address to, uint value) internal {
        bytes4 selector_ = token.transfer.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransfer");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        bytes4 selector_ = token.transferFrom.selector;
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        require(_getLastTransferResult(token), "!safeTransferFrom");
    }

    function _getLastTransferResult(IERC20 token) private view returns (bool success) {
        assembly {
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            case 0 {
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "!contract")
                }
                success := 1
            }
            case 32 {
                returndatacopy(0, 0, returndatasize())
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "!transferResult")
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}