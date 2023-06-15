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

/**
 *
 *      ε≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤,                           ╓≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤╖
 *    ╔░░░░░░░░░░░░░░░░░░░░░█                   ,     ]░░░░░░░░░░░░░░░░░░░░░░║ε
 *    ╠░░░░░░░░░░░░░░░░░░░░░▓░░            ,≤φ░''░░░µ,]░░░░░░░░░░░░░░░░░░░░░░╟▌░
 *    ╠░░░░░░░░░░░░░░░░░░░░▄▓▐▌       ,≤φ░░,▄▄#╝╙╙`_  ]░░░░░░░░▐▓▀▀▀▀▀▒░░░░░░╟▌░_
 *    ╠░░░░░░░░░▓╙╙╙╙╙╙╙╙╙╙╚░░▒╓ ,≤φ▒▄▄#▀╠╩╙"▒≥      ╓░▒▒"φ░░░░▐▌     ▒░░░░░░╟▒░
 *    ╠░░░░░░░░░▓_Γ       ╓φ░░░░,╙╠╚│░░]█.▒░░░░╚▄   Θ░░░░)░░░░░▐░░░░░░░░░░░░░╠░░░░▄▒░░░░░░░░░░░░╗
 *    ╠░░░░░░░░░▓_ε        ░░░░█▄-╩░░░░╚╝α▒░░░░░╟▒╓▒░░░░#░░░░░░▐░░░░░░░░░░░░░╠░░░░╣▒░░░░░░░░░░░░░▓⌐
 *    ╠░░░░░░░░░▓_ε       ╠░▒]█╚░░░░░░░░░░░▓░░░░░╚░░░░░╩░░░░░░░▐▄▄▄▄▄░φφφφ▄▄▄░░░░░╣▒░░░░░▄▄▒░░░░░╣░░
 *    ╠Γ░░░░░░░░╙░▒≥≥≥≥≥≥φ╡░░▐▒░║▓▒░░░░]▓▓╝╙╠░░░░░░░░╔▓░░░░░░░░▐▌└--∩░░░░║▌│░▒░░░░╣▒░░░░░╫▒╠░░░░░╣░░
 *    ╠Γ░░░░░░░░░░░░░░░░░╚╡░░░░░║▒╬░░░░░╩φ▒""╠░░░░░░φ▓╚▒░░░░░░░▐▌¡  Γ⌠░░░╙Θφ≥⌐░░░░╣▒φ░░░░╬░╙]░░░░╣░░
 *    ╠░░░░░░░░░░░░░░░░░░░░░░░░░║▒╬░░░░░░░░╟╕φ░░░░░▓▓.▐░░░░░░░░▐▌¡  Γ⌠░░░░░░░░░░░░╣▒░░░░░▒░░░░░░░╣░░
 *     ╙░░░░░░░░░░░░░░░░░░░░░░░╓╣▒╚░░░░░░░░╣▒░░░░╔▓╩;▒_φ░░░░░░░╟█¡  ╚░░░░░░░░░░░░▄▓▒░░░░░Γ░░░░░╔▓╩'Γ
 *       ╙╙╙╙╙╙╙╙╙╙╙╙╙║▓▀▀▀▀▀▀▀▀╝#▓#▀▀▀▀▀▀▀▀▀▓▀▀▀▓█▄▓###╣▓▀▀╫▓╙╙▄####▓▀▀▀▀▀▀▀▀▀▀▓▓░▒░░░░░╫▒╙╙╙╙╙░░╛
 *                   ╓▓'_________╫╩_________╔▌__╔▓█╙__▄▓▓▓░_▐▓▄╩└_╓▓▓▒_________φ▓╩_"φ▄▄▄φ▓⌐░
 *                   ▓╗╗╗ε░░φ╗╗╗▓▒░░╔▓▓▓∩░░╔▌.░╔╩│░░▄▓▓▀_║▒░░╩│░╓▓▓▓▒░░φ▓▓▓∩░░╔▓▌    _╚││¡≥"
 *                    _]▓σσ╣▓╜_╟▒σσ╣▓▌╔╬σσφ▓σσσσσσφ▓▓▀_  ▐▒σσσ▄▓▓▀╔▒σσφ▓▌╔╬σσφ▓▌_
 *                    ]▓░░╟▓▀ ╔▒░░░░░░░░░╠▓░░╠▓╬░░░╙█Q  ,▓░░░║▓▀_╔▒░░░░░░░░░║▓▌_
 *                   ,▓╚╚╫▓▌ ╔▒╚╝╚╚╚╚╚╚╚╢▓╚╚╢▓█_╙╣╢╝╚╚█µ▓╚╚╚╫▓╩ ╓▓╚╚╚╚╚╚╚╚╚╢▓▌_
 *                   ╚╝╝╝╝▀_ ╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝╝_   ╙╝╝╝╝╝╝╝╝╝╝╝  ╝╝╝╝╝╝╝╝╝╝╝╝╩_
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/INFT.sol";
import "./interface/IToken.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

contract CityPopTokyoExpBridge is Ownable, ReentrancyGuard {
    uint256 public immutable expDecimal = 2;

    uint256 public maxExpLimit;
    uint256 public equalTokenPerExp;
    address public nft;
    address public token;

    mapping(uint256 => uint256) public currentNftExp;

    event BridgedTokenToExp(
        address indexed spender,
        uint256 nftId,
        uint256 exp
    );

    constructor(uint256 _equalTokenPerExp, address _token, address _nft) {
        require(
            _equalTokenPerExp >= 100,
            "CityPopTokyoExpBridge : Minimal value wei is 100 in decimal 2"
        );

        equalTokenPerExp = _equalTokenPerExp;
        token = _token;
        nft = _nft;
    }

    function equalTokenPerExpInDecimalTwo() public view returns (uint256) {
        return equalTokenPerExp / (10 ** expDecimal);
    }

    function currentNftExpBatch(
        uint256[] memory nftIds
    ) public view returns (uint256[] memory) {
        uint256[] memory batchExp = new uint256[](nftIds.length);

        for (uint256 i = 0; i < nftIds.length; ++i) {
            batchExp[i] = currentNftExp[nftIds[i]];
        }

        return batchExp;
    }

    function changeEqualTokenPerExp(
        uint256 _equalTokenPerExp
    ) external onlyOwner nonReentrant {
        require(
            _equalTokenPerExp >= 100,
            "CityPopTokyoExpBridge : Minimal value wei is 100 in decimal 2"
        );

        equalTokenPerExp = _equalTokenPerExp;
    }

    function changeExpLimit(uint256 _limitExp) external onlyOwner nonReentrant {
        maxExpLimit = _limitExp;
    }

    function changeNft(address _nft) external onlyOwner nonReentrant {
        nft = _nft;
    }

    function changeToken(address _token) external onlyOwner nonReentrant {
        token = _token;
    }

    function convertTokenToExp(
        uint256 nftId,
        uint256 amountExp
    ) external nonReentrant {
        require(
            INFT(nft).ownerOf(nftId) != address(0) &&
                INFT(nft).balanceOf(_msgSender()) > 0 &&
                (
                    (maxExpLimit > 0)
                        ? (currentNftExp[nftId] + amountExp <= maxExpLimit)
                        : true
                ),
            "CityPopTokyoExpBridge : Invalid convert action"
        );

        IToken(token).burnFrom(
            _msgSender(),
            (amountExp * equalTokenPerExpInDecimalTwo())
        );
        currentNftExp[nftId] += amountExp;

        emit BridgedTokenToExp(_msgSender(), nftId, amountExp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface INFT {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function exists(uint256 nftId) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function isMinter(address user) external view returns (bool);

    function lazyMint(address to, uint256 nftId) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function royaltyFeeDenominator() external pure returns (uint96);

    function royaltyFeeNominator() external view returns (uint96);

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory baseURI_) external;

    function setMinter(address user, bool status) external;

    function setRoyalty(uint96 feeNominator) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transferOwnership(address newOwner) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IToken {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function authorizationState(
        address,
        address,
        bytes32
    ) external view returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function initialize(
        uint256 supply_,
        address owner_,
        string memory tokenName_,
        string memory tokenSymbol_
    ) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWithAuthorization(
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external;
}