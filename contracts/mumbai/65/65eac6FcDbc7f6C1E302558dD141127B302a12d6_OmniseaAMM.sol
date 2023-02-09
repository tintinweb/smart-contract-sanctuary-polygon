// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolCreateParams} from "../structs/amm/PoolStructs.sol";
import {LZConfig} from "../structs/amm/CommonStructs.sol";
import "./Pool.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IAMM.sol";

contract OmniseaAMM is IAMM, ReentrancyGuard {
    event PoolCreated(uint16 _id, address _creator);

    // LayerZero / GMP Properties for Pools:
    uint16 public override chainId;
    uint16 public override aptosChainId;
    address public override lzEndpoint;
    LZConfig public lzConfig;
    bool public override globalPaused;
    mapping(uint16 => bool) public pausedChains;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    uint16[] public lzChainIds;

    // Contract-level Properties:
    mapping(address => mapping(address => address)) public pools; // nft -> token -> pool
    uint256 public poolsCount;
    address public owner;
    uint256 public override fee;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _lzEndpoint) {
        require(_lzEndpoint != address(0));
        lzEndpoint = _lzEndpoint;
        owner = msg.sender;
        chainId = 10109;
        aptosChainId = 10108;
        fee = 50; // TODO (BP)
    }

    function createPool(PoolCreateParams memory _position) public nonReentrant {
        require(_position.ft != address(0) && _position.ftAmount > 0);
        require(_position.nft != address(0) && _position.nftAmount > 0);
        require(pools[_position.nft][_position.ft] == address(0), "AMM:1");
        // TODO (Must): Validate against ERC721 and ERC20 standards
        IERC20 erc20 = IERC20(_position.ft);
        address sender = msg.sender;

        _position.owner = sender;

        poolsCount++;
        address pool = address(new Pool(_position));
        pools[_position.nft][_position.ft] = pool;
        erc20.transferFrom(sender, pool, _position.ftAmount);
    }

    function setGlobalPause(bool _isPaused) external onlyOwner {
        globalPaused = _isPaused;
    }

    function setChainPause(uint16 _dstChainId, bool _isPaused) external onlyOwner {
        pausedChains[_dstChainId] = _isPaused;
    }

    function pausedChain(uint16 _chainId) external view override returns (bool) {
        return pausedChains[_chainId];
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 5000); // TODO (Must): Apply LZ BP denomination
        fee = _fee;
    }

    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
    }

    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory) {
        return trustedRemoteLookup[_chainId];
    }

    function setLzChainIds(uint16[] memory _chainIds) external onlyOwner {
        lzChainIds = _chainIds;
    }

    function setLzEndpoint(address _lzEndpoint) external onlyOwner {
        lzEndpoint = _lzEndpoint;
    }

    function getLzConfig() external override view returns (bool payInZRO, address zroPaymentAddress) {
        return (lzConfig.payInZRO, lzConfig.zroPaymentAddress);
    }

    function getLzChainIds() external view returns (uint16[] memory) {
        return lzChainIds;
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
pragma solidity ^0.8.7;

struct PoolCreateParams {
    address owner;
    address nft;
    uint256 nftAmount;
    address ft;
    uint256 ftAmount;
}

struct Order {
    address sender;
    address bAsset;
    address tAsset;
    uint256 amount;
    uint16 chainId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct LZConfig {
    bool payInZRO;
    address zroPaymentAddress;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/interfaces/IERC721Ownable.sol";
import "../token/fraction/Fraction.sol";
import {Order, PoolCreateParams} from "../structs/amm/PoolStructs.sol";
import "../interfaces/IAMM.sol";

contract Pool is ReentrancyGuard {
    event LiquidityAdded(address _lp, address _ft, address _nft, uint256 _ftAmount, uint256[] _nftIds);
    event LiquidityRemoved(address _lp, address _ft, address _nft, uint256 _ftAmount, uint256[] _nftIds);
    event OrderFilled(address _sender, address[] _sellers, address _ft, address _nft, uint256 _amount);
    event OrderNotFilled(address _sender, uint16 _srcChainId, uint256 _refundableAmount);

    error InvalidFungible();
    error InvalidNFT();

    uint256 immutable private f = 10**18;
    uint256 public invariant;

    // Contract-level Properties:
    IAMM public amm;
    uint256 public initialNftAmount;
    bool public isDeposited;
    uint96 public royaltyFraction;
    // NFT
    IERC721Ownable public erc721;
    uint256 public bAsset;
    uint256[] public bAssetLockedIds;
    // ERC20
    IERC20 public erc20;
    uint256 public tAsset;
    // Fractions
    Fraction public fractions;
    uint256 public fAsset;

    modifier onlyAMM() {
        require(msg.sender == address(amm));
        _;
    }

    constructor(PoolCreateParams memory _position) {
        // TODO (Must): Validate against ERC721 and ERC20 standards - does PoolCreateParams.owner has enough fts and nfts, etc.
        amm = IAMM(msg.sender);
        initialNftAmount = _position.nftAmount;
        tAsset = _position.ftAmount;
        invariant = tAsset * initialNftAmount * f;
        erc721 = IERC721Ownable(_position.nft);
        erc20 = IERC20(_position.ft);
        fractions = new Fraction(string(abi.encodePacked(erc721.name(), ":", " Fraction")), erc721.symbol(), _position.nft);
    }

    // TODO: (Must) Execute by OmniseaRouter only. address _orderer/sender as a param not msg.sender (Router)
    function createOrder(
        Order memory _order,
        bytes memory _adapterParams
    ) public payable nonReentrant {
        require(isDeposited);
        _order.sender = msg.sender;
        _validateAbstractOrder(_order);
        bool isBuy = address(erc721) == _order.bAsset;

        if (_order.chainId == amm.chainId()) {
            _matchOrder(_order, isBuy);

            return;
        }
        _adapterParams;
        // TODO: (Must) Stargate send()
    }

    // TODO: (Must) ERC20 balance of sender as param - balanceOf() if local, _amount if Stargate
    function _matchOrder(Order memory _order, bool _isBuy) internal {
        _validateOrder(_order, _isBuy);
        address sender = _order.sender; // TODO: (Must) Stargate?
        uint256 orderAmount = _order.amount; // if `_isBuy` - tAsset given, if not - fAsset given

        if (_isBuy) {
            tAsset += orderAmount;
            uint256 fAfter = invariant / tAsset;
            uint256 received = fAsset - fAfter;
            fAsset = fAfter;
            fractions.transfer(sender, received);
            erc20.transferFrom(sender, address(this), orderAmount);
            // erc721.transferFrom(address(this), sender, bAssetLockedIds[nftLockedCount-1]);
            // bAssetLockedIds.pop();
            // TODO: Optionally automatically swap fAsset to bAsset
        } else {
            fAsset += orderAmount;
            uint256 tAfter = invariant / fAsset;
            uint256 received = tAsset - tAfter;
            tAsset = tAfter;
            fractions.transferFrom(sender, address(this), orderAmount);
            erc20.transfer(sender, received);
        }

//        require(tAsset * fAsset == invariant);
    }

    function depositBaseAsset(uint256[] memory ids) external nonReentrant {
        require(!isDeposited);

        for (uint i = 0; i < ids.length; i++) {
            erc721.transferFrom(msg.sender, address(this), ids[i]);
            bAssetLockedIds.push(ids[i]);

            if (bAssetLockedIds.length == initialNftAmount) {
                bAsset = initialNftAmount;
                fAsset = bAsset * f;
                isDeposited = true;
                _mintFractions(address(this), fAsset);
                // TODO (Must) Send LP tokens
                return;
            }
        }
    }

    function setRoyalty(uint96 _royaltyFraction) external {
        address creator = erc721.owner();
        require(creator == msg.sender);
        royaltyFraction = _royaltyFraction;
    }

    function royaltyInfo(uint256 _salePrice) public virtual returns (address, uint256) {
        address receiver = erc721.owner();
        uint256 royaltyAmount = (_salePrice * royaltyFraction) / _feeDenominator();

        return (receiver, royaltyAmount);
    }

    function merge(uint256 _toBase) external {
        uint256 fractionsAmount = _toBase * f;
        require(fractions.balanceOf(msg.sender) >= fractionsAmount);
        require(erc721.balanceOf(address(this)) >= _toBase);

        _burnFractions(msg.sender, fractionsAmount);
        for (uint i = 0; i < _toBase; i++) {
            erc721.transferFrom(address(this), msg.sender, bAssetLockedIds[bAssetLockedIds.length - 1]);
            bAssetLockedIds.pop();
        }
    }

    function fractionalize(uint256[] memory _ids) external {
        uint256 baseAmount = _ids.length;
        require(baseAmount > 0);
        require(erc721.balanceOf(msg.sender) >= baseAmount);
        uint256 fractionsAmount = baseAmount * f;

        _mintFractions(msg.sender, fractionsAmount);
        for (uint i = 0; i < baseAmount; i++) {
            uint256 tokenId = _ids[i];
            erc721.transferFrom(msg.sender, address(this), tokenId);
            bAssetLockedIds[bAssetLockedIds.length] = tokenId;
            bAsset++;
        }
    }

//    function _decodeNonEVMPayload(bytes memory _payload) internal pure returns (Order memory) {
//         require(_payload.length == 93, "Pool:1");
//
//        address sender = _payload.toAddress(0);
//        address baseAsset = _payload.toAddress(20);
//        address asset = _payload.toAddress(40);
//        uint256 amount = _payload.toUint256(60);
//        uint16 chainId = _payload.toUint16(92);
//
//        return Order(sender, baseAsset, asset, amount, chainId);
//    }

//    function _decodeEVMPayload(bytes memory _payload) internal pure returns (Order memory) {
//        (Order memory order) = abi.decode(_payload, (Order));
//
//        return order;
//    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _validateAbstractOrder(Order memory _order) internal pure {
        require(_order.amount > 0);
        require(_order.tAsset != address(0));
        require(_order.bAsset != address(0));
        require(_order.chainId > 0);
    }

    function _validateOrder(Order memory _order, bool _isBuy) internal view {
        require(_order.bAsset == address(erc721) && _order.tAsset == address(erc20));

        if (_isBuy) {
            require(_order.amount <= fAsset);
        } else {
            require(_order.amount <= tAsset);
        }
    }

    function _mintFractions(address _to, uint256 _amount) private {
        fractions.mint(_to, _amount);
    }

    function _burnFractions(address _from, uint256 _amount) private {
        fractions.burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {PoolCreateParams} from "../structs/amm/PoolStructs.sol";

interface IPool {
    function addLiquidity(PoolCreateParams calldata _position) external;
    function removeLiquidity(uint256 _tokenAmount, uint16 _nftsQuantity) external;
    function totalTokenAmount() external returns(uint256);
    function totalNFTsQuantity() external returns(uint16);
    function minFillable() external returns(uint256);
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LZConfig} from "../structs/amm/CommonStructs.sol";

interface IAMM {
    function chainId() external returns (uint16);
    function aptosChainId() external returns (uint16);
    function lzEndpoint() external returns (address);
    function getLzConfig() external view returns (bool payInZRO, address zroPaymentAddress);
    function pausedChain(uint16 _chainId) external view returns (bool);
    function globalPaused() external returns (bool);
    function fee() external view returns (uint256);
    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory);
    function getLzChainIds() external view returns (uint16[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Ownable is IERC721 {
    function owner() external returns (address);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fraction is ERC20 {
    address public pool;
    address public base;

    constructor(string memory _name, string memory _symbol, address _base) ERC20(_name, _symbol) {
        pool = msg.sender;
        base = _base;
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == pool);
        _mint(_to, _amount * 10**18);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == pool);
        _burn(_from, _amount * 10**18);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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