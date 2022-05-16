// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IDistributor.sol";
import "./interface/IGovernance.sol";
import "./interface/IERC20Meta.sol";
import "./interface/IWrapped.sol";
import "./library/LibTrade.sol";
import "./library/LibTransfer.sol";


contract OscilloExchange is OwnableUpgradeable {
    using LibTrade for LibTrade.MatchExecution;
    using LibTransfer for IERC20Meta;

    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 private constant _DOMAIN_NAME = 0xc8885bf67401dce7cf0f3f7667e33f54abe0420de87d9c0bc583e63ed397cd2d;

    uint private constant GAS_ENTRANCE = 31600;
    uint private constant GAS_CALLDATA = 6000;
    uint private constant GAS_EXPECTATION = 310000;
    uint private constant GAS_MULTIPLIER_MAX = 1250;
    uint private constant GAS_MULTIPLIER_DENOM = 1000;

    uint private constant RESERVE_MAX = 2500;
    uint private constant RESERVE_DENOM = 1000000;
    uint private constant PRICE_DENOM = 1000000;

    bytes32 private _domainSeparator;
    uint private _gasMultiplier;
    mapping(uint => uint) private _fills;

    IGovernance public governance;
    IDistributor public distributor;
    IWrapped public nativeToken;

    event Executed(uint indexed matchId, uint[3] askTransfers, uint[3] bidTransfers);
    event Cancelled(uint indexed matchId, uint code);

    modifier gasLimiter(uint calls, uint gasLimit) {
        uint gasUsed = gasleft();
        _;
        gasUsed = gasUsed - gasleft() + GAS_ENTRANCE + (GAS_CALLDATA * calls);
        require(gasLimit <= gasUsed * _gasMultiplier / GAS_MULTIPLIER_DENOM);
    }

    receive() external payable {}

    /** Initialize **/

    function initialize(address _governance, address _nativeToken) external initializer {
        __Ownable_init();

        require(_domainSeparator == 0 && _nativeToken != address(0));
        _domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, _DOMAIN_NAME, _DOMAIN_VERSION, block.chainid, address(this)));
        _gasMultiplier = 1100;

        governance = IGovernance(_governance);
        nativeToken = IWrapped(_nativeToken);
    }

    /** Views **/

    function toAmountQuote(address base, address quote, uint amount, uint price) public view returns (uint) {
        return amount * price * (10 ** IERC20Meta(quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(base).decimals());
    }

    function toAmountsInOut(LibTrade.MatchPacked memory p) public view returns (uint[2] memory askTransfers, uint[2] memory bidTransfers) {
        uint baseUnit = 10 ** IERC20Meta(p.base).decimals();
        uint quoteUnit = 10 ** IERC20Meta(p.quote).decimals();

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
        uint baseDecimals = IERC20Meta(p.base).decimals();
        uint txCost = gasprice * gasUsed * p.priceN / p.price / (10 ** (18 - baseDecimals));
        askTx = _fills[p.askId] == 0 ? txCost * p.price * (10 ** IERC20Meta(p.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = _fills[p.bidId] == 0 ? txCost : 0;
    }

    function gasMultiplier() public view returns (uint) {
        return _gasMultiplier;
    }

    function acceptance(LibTrade.MatchExecution[] memory chunk, uint gasprice) public view returns (LibTrade.Acceptance[] memory) {
        LibTrade.Acceptance[] memory accepts = new LibTrade.Acceptance[](chunk.length);
        for (uint i = 0; i < chunk.length; i++) {
            LibTrade.MatchExecution memory e = chunk[i];
            accepts[i].mid = e.mid;

            if (e.recover(_domainSeparator) != owner() || e.p.reserve > RESERVE_MAX) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxSignature);
            if (e.p.price < e.p.askLprice || e.p.price > e.p.bidLprice) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxPrice);
            if (e.p.askAmount < _fills[e.p.askId] + e.p.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.p.bidAmount < _fills[e.p.bidId] + e.p.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidFilled);

            uint amountQ = toAmountQuote(e.p.base, e.p.quote, e.p.amount, e.p.price);
            (uint askReserve, uint bidReserve) = reserves(e.p.base, e.p.quote, e.p.amount, e.p.price, e.p.reserve);
            (uint askTx, uint bidTx) = txCosts(e.p, gasprice, GAS_EXPECTATION);
            if (askReserve + askTx > amountQ) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.p.amount) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidCost);

            (uint[2] memory askTransfers, uint[2] memory bidTransfers) = toAmountsInOut(e.p);
            if (IERC20Meta(e.p.base).available(e.p.askAccount, address(this)) < askTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.p.quote).available(e.p.bidAccount, address(this)) < bidTransfers[0]) accepts[i].code = accepts[i].code | (1 << LibTrade.CodeIdxBidBalance);

            accepts[i].askTransfers = [askTransfers[0], askTransfers[1], askTx];
            accepts[i].bidTransfers = [bidTransfers[0], bidTransfers[1], bidTx];
        }
        return accepts;
    }

    /** Interactions **/

    function execute(LibTrade.MatchExecution[] calldata chunk, uint gasLimit) external gasLimiter(chunk.length, gasLimit) {
        uint estimation = (gasLimit == 0 ? GAS_EXPECTATION : gasLimit) / chunk.length;
        for (uint i = 0; i < chunk.length; i++) {
            uint code;
            LibTrade.MatchExecution memory e = chunk[i];

            uint amountQ = e.p.amount * e.p.price * (10 ** IERC20Meta(e.p.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.p.base).decimals());
            if (IERC20Meta(e.p.base).available(e.p.askAccount, address(this)) < e.p.amount) code = code | (1 << LibTrade.CodeIdxAskBalance);
            if (IERC20Meta(e.p.quote).available(e.p.bidAccount, address(this)) < amountQ) code = code | (1 << LibTrade.CodeIdxBidBalance);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            if (e.recover(_domainSeparator) != owner() || e.p.reserve > RESERVE_MAX) code = code | (1 << LibTrade.CodeIdxSignature);
            if (e.p.price < e.p.askLprice || e.p.price > e.p.bidLprice) code = code | (1 << LibTrade.CodeIdxPrice);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            (uint askFilled, uint bidFilled) = (_fills[e.p.askId], _fills[e.p.bidId]);
            if (e.p.askAmount < askFilled + e.p.amount) code = code | (1 << LibTrade.CodeIdxAskFilled);
            if (e.p.bidAmount < bidFilled + e.p.amount) code = code | (1 << LibTrade.CodeIdxBidFilled);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            _fills[e.p.askId] = askFilled + e.p.amount;
            _fills[e.p.bidId] = bidFilled + e.p.amount;

            IERC20Meta(e.p.base).safeTransferFrom(e.p.askAccount, address(this), e.p.amount);
            IERC20Meta(e.p.quote).safeTransferFrom(e.p.bidAccount, address(this), amountQ);

            uint bidReserve = e.p.amount * e.p.reserve / RESERVE_DENOM;
            uint askReserve = bidReserve * e.p.price * (10 ** IERC20Meta(e.p.quote).decimals()) / PRICE_DENOM / (10 ** IERC20Meta(e.p.base).decimals());
            (uint askTx, uint bidTx) = _txCosts(e.p, askFilled, bidFilled, tx.gasprice, estimation);
            if (askReserve + askTx > amountQ) code = code | (1 << LibTrade.CodeIdxAskCost);
            if (bidReserve + bidTx > e.p.amount) code = code | (1 << LibTrade.CodeIdxBidCost);
            if (code != 0) {
                emit Cancelled(e.mid, code);
                continue;
            }

            IERC20Meta(e.p.quote).safeTransfer(e.p.askAccount, amountQ - askReserve - askTx);
            if (e.p.unwrap && e.p.base == address(nativeToken)) {
                uint balance = address(this).balance;
                nativeToken.withdraw(e.p.amount - bidReserve - bidTx);
                LibTransfer.safeTransferETH(e.p.bidAccount, address(this).balance - balance);
            } else {
                IERC20Meta(e.p.base).safeTransfer(e.p.bidAccount, e.p.amount - bidReserve - bidTx);
            }

            if (askTx > 0) IERC20Meta(e.p.quote).safeTransfer(msg.sender, askTx);
            if (bidTx > 0) IERC20Meta(e.p.base).safeTransfer(msg.sender, bidTx);
            emit Executed(e.mid, [e.p.amount, amountQ - askReserve, askTx], [amountQ, e.p.amount - bidReserve, bidTx]);
        }
    }

    /** Restricted **/

    function setGasMultiplier(uint multiplier) external onlyOwner {
        require(multiplier <= GAS_MULTIPLIER_MAX, "!multiplier");
        _gasMultiplier = multiplier;
    }

    function setDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(0) && newDistributor != address(distributor), "!distributor");
        if (address(distributor) != address(0)) {
            IERC20Meta(distributor.rewardToken()).safeApprove(address(distributor), 0);
        }

        distributor = IDistributor(newDistributor);
        IERC20Meta rewardToken = IERC20Meta(distributor.rewardToken());
        rewardToken.safeApprove(address(distributor), 0);
        rewardToken.safeApprove(address(distributor), type(uint).max);
    }

    function distribute(uint checkpoint, uint accVolume, uint rewardAmount) external onlyOwner {
        require(address(distributor) != address(0), "!distributor");
        governance.notifyAccVolumeUpdated(checkpoint, accVolume);
        distributor.notifyRewardDistributed(rewardAmount);
    }

    function sweep(address[] calldata tokens) external onlyOwner {
        address rewardToken = distributor.rewardToken();
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == rewardToken) continue;

            IERC20Meta token = IERC20Meta(tokens[i]);
            uint leftover = token.balanceOf(address(this));
            if (leftover > 0) token.safeTransfer(owner(), leftover);
        }
    }

    /** Privates **/

    function _txCosts(LibTrade.MatchPacked memory p, uint askFilled, uint bidFilled, uint gasprice, uint gasUsed) private view returns (uint askTx, uint bidTx) {
        uint baseDecimals = IERC20Meta(p.base).decimals();
        uint txCost = gasprice * gasUsed * p.priceN / p.price / (10 ** (18 - baseDecimals));
        askTx = askFilled == 0 ? txCost * p.price * (10 ** IERC20Meta(p.quote).decimals()) / PRICE_DENOM / (10 ** baseDecimals) : 0;
        bidTx = bidFilled == 0 ? txCost : 0;
    }
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


interface IDistributor {
    function rewardToken() external view returns (address);
    function reserves() external view returns (uint);

    function stake(uint amount) external;
    function unstake(uint amount) external;
    function claim() external;
    function exit() external;

    function notifyRewardDistributed(uint rewardAmount) external;
    function stakeBehalf(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IGovernance {
    function notifyAccVolumeUpdated(uint checkpoint, uint accVolumeX2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IERC20Meta {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWrapped {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library LibTrade {
    bytes32 constant _MATCH_PACKED_TYPEHASH = 0xd6db58df65c98ec5a34acafe4b0f5bb415bf05e7309037c3ce3ab7fa2d87c372;

    uint constant CodeIdxSignature = 7;
    uint constant CodeIdxPrice = 6;
    uint constant CodeIdxAskFilled = 5;
    uint constant CodeIdxBidFilled = 4;
    uint constant CodeIdxAskCost = 3;
    uint constant CodeIdxBidCost = 2;
    uint constant CodeIdxAskBalance = 1;
    uint constant CodeIdxBidBalance = 0;

    /// @dev code [signature|price|ask.fill|bid.fill|ask.cost|bid.cost|ask.available|bid.available]
    struct Acceptance {
        uint mid;
        uint code;
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
        bool unwrap;
    }

    struct MatchExecution {
        uint mid;
        MatchPacked p;
        bytes sig;
    }

    function recover(MatchExecution memory exec, bytes32 domainSeparator) internal pure returns (address) {
        MatchPacked memory packed = exec.p;
        bytes memory signature = exec.sig;
        require(signature.length == 65, "invalid signature length");

        bytes32 structHash;
        bytes32 digest;

        // MatchPacked struct (15 fields) and type hash (15 + 1) * 32 = 544
        assembly {
            let dataStart := sub(packed, 32)
            let temp := mload(dataStart)
            mstore(dataStart, _MATCH_PACKED_TYPEHASH)
            structHash := keccak256(dataStart, 512)
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


import "../interface/IERC20Meta.sol";

library LibTransfer {
    function available(IERC20Meta token, address owner, address spender) internal view returns (uint) {
        uint _allowance = token.allowance(owner, spender);
        uint _balance = token.balanceOf(owner);
        return _allowance < _balance ? _allowance : _balance;
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function safeApprove(IERC20Meta token, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(IERC20Meta token, address to, uint value) internal {
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

    function safeTransferFrom(IERC20Meta token, address from, address to, uint value) internal {
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

    function _getLastTransferResult(IERC20Meta token) private view returns (bool success) {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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