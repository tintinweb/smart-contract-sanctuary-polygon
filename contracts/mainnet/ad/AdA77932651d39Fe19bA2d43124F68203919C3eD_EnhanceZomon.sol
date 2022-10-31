// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

import "../../oracles/EnhanceZomonOracle/EnhanceZomonOracleCaller.sol";

contract EnhanceZomon is
    ZomonContractCallerOwnable,
    EnhanceZomonOracleCaller,
    ChainlinkPriceFeedCallerOwnable
{
    /// @dev - target level => current level => 18 decimals USD amount
    mapping(uint256 => mapping(uint256 => uint256))
        private _enhancePremiumDollarsPrices;

    struct EnhancePremiumDollarsPrice {
        uint256 targetLevel;
        uint256 currentLevel;
        uint256 dollarsPrice; // 18 decimals USD amount
    }

    constructor(
        EnhancePremiumDollarsPrice[] memory _initialEnhancePremiumDollarsPrice,
        address _zomonContractAddress,
        address _enhanceZomonOracleContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress
    )
        ZomonContractCallerOwnable(_zomonContractAddress)
        EnhanceZomonOracleCaller(_enhanceZomonOracleContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setEnhancePremiumDollarsPrice(_initialEnhancePremiumDollarsPrice);
    }

    function setEnhancePremiumDollarsPrice(
        EnhancePremiumDollarsPrice[] memory _newEnhancePremiumDollarsPrice
    ) public onlyOwner {
        EnhancePremiumDollarsPrice memory enhancePremiumDollarsPrice;
        for (uint256 i = 0; i < _newEnhancePremiumDollarsPrice.length; i++) {
            enhancePremiumDollarsPrice = _newEnhancePremiumDollarsPrice[i];

            require(
                enhancePremiumDollarsPrice.dollarsPrice > 0,
                "ENHANCE_PREMIUM_DOLLARS_PRICE_IS_ZERO"
            );

            _enhancePremiumDollarsPrices[
                enhancePremiumDollarsPrice.targetLevel
            ][
                enhancePremiumDollarsPrice.currentLevel
            ] = enhancePremiumDollarsPrice.dollarsPrice;
        }
    }

    function _getZomonCurrentMaxLevel(Zomon memory _zomon)
        private
        pure
        returns (uint16)
    {
        if (_zomon.level == _zomon.maxLevel) {
            return _zomon.maxLevel;
        }

        if (_zomon.level < 20) {
            return 20;
        }

        uint16 currentMaxLevel = (_zomon.evolution + 1) * 10;

        if (currentMaxLevel >= _zomon.maxLevel) {
            return _zomon.maxLevel;
        }

        return currentMaxLevel;
    }

    function getEnhancePremiumPrice(uint256 _zomonTokenId)
        public
        view
        returns (uint256)
    {
        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        uint16 currentMaxLevel = _getZomonCurrentMaxLevel(zomon);

        uint256 dollarsPrice = _enhancePremiumDollarsPrices[currentMaxLevel][
            zomon.level
        ];

        require(dollarsPrice > 0, "ENHANCE_PREMIUM_DOLLARS_PRICE_NOT_SET");

        return (dollarsPrice * 10**18) / _getLatestPrice(18);
    }

    function enhancePremium(uint256 _zomonTokenId) external payable {
        uint256 price = getEnhancePremiumPrice(_zomonTokenId);

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        // Check Zomon can level up
        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);
        require(zomon.canLevelUp, "ZOMON_CANNOT_LEVEL_UP");

        _callEnhancePremiumOracle(
            _msgSender(),
            _zomonTokenId,
            _getZomonCurrentMaxLevel(zomon)
        );
    }

    function enhanceCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(enhanceZomonOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingEnhanceZomonRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingEnhanceZomonRequests[_requestId];

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Zomon {
    /* 32 bytes pack */
    uint16 serverId;
    uint16 setId;
    uint8 edition;
    uint8 rarityId;
    uint8 genderId;
    uint8 zodiacSignId;
    uint16 skillId;
    uint16 leaderSkillId;
    bool canLevelUp;
    bool canEvolve;
    uint16 level;
    uint8 evolution;
    uint24 hp;
    uint24 attack;
    uint24 defense;
    uint24 critical;
    uint24 evasion;
    /*****************/
    bool isShiny;
    uint8 shinyBoostedStat; // 0 = none, 1 = hp, 2 = attack, 3 = defense, 4 = critical, 5 = evasion
    uint16 maxLevel;
    uint8 maxRunesCount;
    uint16 generation;
    uint8 innerTokenDecimals;
    uint8[] typesIds;
    uint16[] diceFacesIds;
    uint16[] runesIds;
    string name;
    address innerTokenAddress;
    uint256 minLevelInnerTokenBalance;
    uint256 maxLevelInnerTokenBalance;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/ZOMON/IZomon.sol";

contract ZomonContractCallerOwnable is Ownable {
    IZomon public zomonContract;

    constructor(address _zomonContractAddress) {
        setZomonContract(_zomonContractAddress);
    }

    function setZomonContract(address _address) public onlyOwner {
        IZomon candidateContract = IZomon(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_ZOMON_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_ZOMON_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        zomonContract = candidateContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkPriceFeedCallerOwnable is Ownable {
    AggregatorV3Interface internal _priceFeed;

    constructor(address _priceFeedAddress) {
        setPriceFeed(_priceFeedAddress);
    }

    function setPriceFeed(address _priceFeedAddress) public onlyOwner {
        _priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function _getLatestPrice(uint8 _decimals) internal view returns (uint256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();

        if (price <= 0) {
            return 0;
        }

        return _scalePrice(uint256(price), _priceFeed.decimals(), _decimals);
    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) private pure returns (uint256) {
        if (_priceDecimals < _decimals) {
            return _price * (10**(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / (10**(_priceDecimals - _decimals));
        }
        return _price;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEnhanceZomonOracle.sol";

abstract contract EnhanceZomonOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_ENHANCE_ZOMON_ORACLE_CALLER = true;

    IEnhanceZomonOracle public enhanceZomonOracleContract;

    mapping(uint256 => bool) internal _pendingEnhanceZomonRequests;

    constructor(address _enhanceZomonOracleContractAddress) {
        setEnhanceZomonOracleContractAddress(
            _enhanceZomonOracleContractAddress
        );
    }

    function setEnhanceZomonOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IEnhanceZomonOracle candidateContract = IEnhanceZomonOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_ENHANCE_ZOMON_ORACLE());

        // Set the new contract address
        enhanceZomonOracleContract = candidateContract;
    }

    // Entry point for level sync
    function _callEnhancePremiumOracle(
        address _to,
        uint256 _zomonTokenId,
        uint256 _targetLevel
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = enhanceZomonOracleContract
            .requestZomonPremiumEnhance(_to, _zomonTokenId, _targetLevel);
        _pendingEnhanceZomonRequests[requestId] = true;
        return requestId;
    }

    // Exit point
    function enhanceCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IZomonStruct.sol";

interface IZomon is IERC721 {
    function IS_ZOMON_CONTRACT() external pure returns (bool);

    function getZomon(uint256 _tokenId) external view returns (Zomon memory);

    function getCurrentInnerTokenBalance(uint256 _tokenId)
        external
        returns (uint256);

    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI,
        Zomon memory _zomonData
    ) external;

    function burn(uint256 _tokenId) external;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundsManagementOwnable is Ownable {
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function withdraw(address _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "WITHDRAW_FAILED");
    }

    function recoverERC20(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            IERC20(_tokenAddress).transfer(_to, _tokenAmount),
            "RECOVERY_FAILED"
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEnhanceZomonOracle {
    function IS_ENHANCE_ZOMON_ORACLE() external returns (bool);

    function requestZomonPremiumEnhance(
        address _to,
        uint256 _zomonTokenId,
        uint256 _targetLevel
    ) external returns (uint256);

    function reportZomonEnhance(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
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