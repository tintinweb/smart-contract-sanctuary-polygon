/**
 *Submitted for verification at polygonscan.com on 2022-05-11
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File interfaces/IEMERC721A.sol

pragma solidity >=0.7.0 <0.9.0;

interface IEMERC721A {
    function totalMinted() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
    function safeMint(address to, uint256 quantity) external;
    function currentIndex() external view returns(uint256);
    function setApprovalForAllByOperator(address operator, address owner, bool approved) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeMint(
            address to,
            uint256 quantity,
            bytes memory _data
        ) external;

    function mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) external;

    function burn(uint256 tokenId) external;
    function numberMinted(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
        function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}


// File enums/PackageType.sol


pragma solidity >=0.7.0 <0.9.0;

enum PackageType { FOUNDER, HEADSTART, EXPLORER, ENTRY }


// File structs/Package.sol


pragma solidity >=0.7.0 <0.9.0;

    struct Package {
        uint256 id;
        PackageType packageType;
        uint256 astronautId;
        uint256 pfpId;
        uint256 daoId;
        bool refundable;
        bool hasRefunded;
        uint256 creationTime;
        uint256 refundStartTimestamp;
        uint256 refundedTimestamp;
        uint256 price;
    }


// File enums/BodyPartCategory.sol


pragma solidity >=0.7.0 <0.9.0;

enum BodyPartCategory { HEAD, CHEAST, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG }


// File interfaces/IEMERC1155.sol

pragma solidity >=0.7.0 <0.9.0;



interface IEMERC1155 {
    function mintPackageByGuildMember(
        address to,
        uint256 id,
        uint256 _astronautIdex,
        uint256 _pfpIndex,
        uint256 _daoIndex
    ) external;

    function mintPackage(
        address to,
        uint256 id,
        uint256 _astronautIdex,
        uint256 _pfpIndex,
        uint256 _daoIndex,
        uint256 _quantity,
        bool _refundable,
    uint256 _price
    ) external;

    function mintBodyPart(
            address _to,
            BodyPartCategory _bodyPartCategory,
            uint256 _quantity,
            uint256 _tokenStartId,
            bool _refundable,
            uint256 _price
    ) external;

    function packagesPerTypeCount(PackageType _packageType) external returns(uint256);

    function ckeckIfPackageRefundale(uint256 _packageId) external view returns(bool);

    function ownerOf(PackageType _packageType, uint256 _packageId) external view returns(address);

    function getPackageByOwner(address _owner, PackageType _packageType, uint256 _packageId) external view returns(Package memory);

    function setPackageRefund(address _owner, uint256 _packageType, uint256 _packageId) external;

    function canBeRefuned(PackageType _packageType, uint256 _index, uint256 _refundPeriod) external view returns(bool);

    function getTotalPackagesCount() external view returns(uint256);

    function getUserPackagesCount(address _owner) external view returns(uint256);

    function burnToken(
        address owner,
        uint256 id,
        uint256 value
    ) external;

}


// File enums/SaleStep.sol


pragma solidity >=0.7.0 <0.9.0;


enum SaleStep { PrivateComingSoon, PrivateSale, PublicSale, PrivateSoldOut, SoldOut, Reveal }


// File contracts/EMPackageSaleManager.sol



pragma solidity >=0.7.0 <0.9.0;










//import "hardhat/console.sol";

contract EMPackageSaleManager is Pausable, Ownable {

    IERC20 EMCouponOne;
    IERC20 EMCouponTwo;
    IEMERC721A EMAstronaut;
    IEMERC721A EMPFP;
    IEMERC721A EMDAO;
    IEMERC1155 EMPackage;

    uint256 public constant MAX_FOUNDER_PRICE = 0.5 ether;
    uint256 public constant MAX_HEADSTART_PRICE = 0.3 ether;
    uint256 public constant MAX_EXPLOER_PRICE = 0.15 ether;
    uint256 public constant MAX_ENTRY_PRICE = 0.06 ether;
    uint256 public constant MAX_PUBLIC = 13000;
    uint8 public constant MAX_MINT_PER_TRANSACTION = 10;
    uint8 public constant MAX_MINT_PER_WALLET = 20;
    uint256 public constant MAX_SUPPLY = 26333;
    uint256 public constant MAX_PRIVATE = 13333;
    uint256 public constant MAX_PRIVATE_SALE_PRICE = 1e18;
    uint256 public publicSaleFounderPrice = 0.5 ether;
    uint256 public publicSaleHeadStartPrice = 0.3 ether;
    uint256 public explorerPrice = 0.15 ether;
    uint256 public entryPrice = 0.06 ether;
    uint8 public mintPerTransaction = 10;
    uint8 public mintPerWallet = 20;
    uint256 privateSaleCount;
    uint256 totalPackagesCount;
    bytes32 public merkleRoot;
    uint256 public guildSalePrice = 1e18;
    uint256 public guildSaleStartTime = 1651701600;
    uint256 public guildSaleEndTime = 1652219999;
    uint256 public whiteListeSaleStartTime = 1651701600;
    uint256 public whiteListeSaleEndTime = 1652219999;
    uint256 public publicSaleStartTime = 1652220000;
    uint256 public publicSaleEndTime = 1652911198;
    SaleStep private saleStep;
    address EMRefundManager;

    modifier updateSaleStape() {
        if(currentTime() < guildSaleStartTime)
            saleStep = SaleStep.PrivateComingSoon;
        if(guildSaleStartTime <= currentTime() && currentTime() < whiteListeSaleEndTime)
            saleStep = SaleStep.PrivateSale;
        if(publicSaleStartTime < currentTime() && currentTime() < publicSaleEndTime)
            saleStep = SaleStep.PublicSale;
        if(privateSaleCount == MAX_PRIVATE)
            saleStep = SaleStep.PrivateSoldOut;
        if(EMPackage.getTotalPackagesCount() == MAX_SUPPLY)
            saleStep = SaleStep.SoldOut;
        _;
    }

    constructor(
        IERC20 couponOne_,
        IERC20 couponTwo_,
        IEMERC721A astronaut_,
        IEMERC721A pfp_,
        IEMERC721A dao_,
        IEMERC1155 package_,
        bytes32 merkleRoot_){
        EMCouponOne = IERC20(couponOne_);
        EMCouponTwo = IERC20(couponTwo_);
        EMAstronaut = astronaut_;
        EMPFP = pfp_;
        EMDAO = dao_;
        merkleRoot = merkleRoot_;
        EMPackage = IEMERC1155(package_);
    }

    function guildSale()
    external
    whenNotPaused
    updateSaleStape
    {
        require(guildSalePrice != 0, "Price is 0");
        require(currentTime() >= guildSaleStartTime,"EMPackageSaleManager(guildSale): Sorry, guild sale has not started yet");
        require(currentTime() <= guildSaleEndTime, "EMPackageSaleManager(guildSale): Sorry, guild sale is ended");
        require(EMCouponOne.balanceOf(msg.sender) >= guildSalePrice
            || EMCouponTwo.balanceOf(msg.sender) >= guildSalePrice , "EMPackageSaleManager(guildSale): You dont have enough coupon");
        require(privateSaleCount + 1 <= MAX_PRIVATE, "EMPackageSaleManager(publicSale): Max supply exceeded");


        PackageType packageType;
        if(EMCouponOne.balanceOf(msg.sender) >= guildSalePrice) {
            EMCouponOne.transferFrom(msg.sender, address(this), guildSalePrice);
            packageType = PackageType.FOUNDER;
        }
        else if (EMCouponTwo.balanceOf(msg.sender) >= guildSalePrice ){
            EMCouponTwo.transferFrom(msg.sender, address(this), guildSalePrice);
            packageType = PackageType.HEADSTART;
        }

        uint256 daoStartId;
        uint256 astronautStartId = EMAstronaut.currentIndex();
        uint256 pfpStartId = EMPFP.currentIndex();
        EMAstronaut.safeMint(msg.sender, 1);
        EMPFP.safeMint(msg.sender, 1);

        if(packageType == PackageType.FOUNDER){
            daoStartId = EMDAO.currentIndex();
            EMDAO.safeMint(msg.sender, 1);
        }
        EMPackage.mintPackageByGuildMember(msg.sender, uint256(packageType), astronautStartId, pfpStartId, daoStartId);
        privateSaleCount++;
    }

    function publicSale(
    PackageType _packageType,
    uint8 _quantity,
    bool _refundable,
    bytes32[] calldata _proof)
    external
    payable
    whenNotPaused
    updateSaleStape
    {
        uint256 price = entryPrice;
        if(_packageType == PackageType.FOUNDER){
            price = publicSaleFounderPrice;
            require(msg.value >= publicSaleFounderPrice * _quantity, "EMPackageSaleManager(FOUNDER sale): Not enough funds");
        }else
        if(_packageType == PackageType.HEADSTART){
            price = publicSaleHeadStartPrice;
            require(msg.value >= publicSaleHeadStartPrice * _quantity, "EMPackageSaleManager(HEADSTART sale): Not enough funds");
        }else
        if(_packageType == PackageType.EXPLORER){
            price = explorerPrice;
            require(msg.value >= explorerPrice * _quantity, "EMPackageSaleManager(EXPLORER sale): Not enough funds");
        }
        else
            require(msg.value >= price * _quantity, "EMPackageSaleManager(ENTRY sale): Not enough funds");

        require(currentTime() >= whiteListeSaleStartTime,"EMPackageSaleManager(publicSale): Sorry, whiteList sale has not started yet");
        require(currentTime() <= whiteListeSaleEndTime, "EMPackageSaleManager(publicSale): Sorry, whiteList sale is ended");
        bool isPrivateSale = false;
        if(currentTime() >= publicSaleStartTime && currentTime() < publicSaleEndTime){
             require(totalPackagesCount + _quantity <= MAX_SUPPLY, "EMPackageSaleManager(publicSale): Max supply exceeded");
        } else{
            require(isWhiteListed(msg.sender, _proof), "EMPackageSaleManager(publicSale): Not whiteListed");
            require(privateSaleCount + _quantity <= MAX_PRIVATE, "EMPackageSaleManager(publicSale): Max supply exceeded");
            isPrivateSale = true;
        }
        
        require(_quantity <= mintPerTransaction,
        "EMPackageSaleManager(publicSale): You can't mint more than 10 tokens in one time");
        require(_quantity + EMPackage.getUserPackagesCount(msg.sender) <= mintPerWallet,
        "EMPackageSaleManager(publicSale): You can't mint more than 20 tokens");

        bool refundable = _refundable;
        uint256 daoStartId;
        uint256 pfpStartId;
        uint256 characterStartId = EMAstronaut.currentIndex();
        EMAstronaut.safeMint(msg.sender, _quantity);
        if(_packageType == PackageType.FOUNDER){
            PackageType packageType = _packageType;
            daoStartId = EMDAO.currentIndex();
            pfpStartId = EMPFP.currentIndex();
            EMDAO.safeMint(msg.sender, _quantity);
            EMPFP.safeMint(msg.sender, _quantity);
            uint256 quantity = _quantity;
            EMPackage.mintPackage(msg.sender, uint256(packageType), characterStartId, pfpStartId, daoStartId, quantity, refundable, msg.value);
         }

        if(_packageType == PackageType.HEADSTART){
            PackageType packageType = _packageType;
            pfpStartId = EMPFP.currentIndex();
            EMPFP.safeMint(msg.sender, _quantity);
            uint256 quantity = _quantity;
            EMPackage.mintPackage(msg.sender, uint256(packageType), characterStartId, pfpStartId, daoStartId, quantity, refundable, msg.value);
         }

        if(_packageType == PackageType.EXPLORER){
            PackageType packageType = _packageType;
            pfpStartId = EMPFP.currentIndex();
            EMPFP.safeMint(msg.sender, _quantity);
            uint256 quantity = _quantity;
            EMPackage.mintPackage(msg.sender, uint256(packageType), characterStartId, pfpStartId, daoStartId, quantity, refundable, msg.value);
        }
        totalPackagesCount += _quantity;
        if(isPrivateSale)
            privateSaleCount += _quantity;
    }

    function payBack(address _user, uint256 _amount) external {
        require(msg.sender == EMRefundManager, "EMPackageSaleManager(payBack): Not EMRefundManager");
        payable(_user).transfer(_amount);
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns (bool){
        return verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function getSaleStep() public view returns(SaleStep){
        return saleStep;
    }

    function setPublicSaleFounderPrice(uint256 price) external onlyOwner {
        publicSaleFounderPrice = price * 1e18;
    }

    function setPublicSaleHeadStartPrice(uint256 price) external onlyOwner {
        publicSaleHeadStartPrice = price * 1e18;
    }

    function setExplorerPrice(uint256 price) external onlyOwner {
        explorerPrice = price * 1e18;
    }

    function setEntryPrice(uint256 price) external onlyOwner {
        entryPrice = price * 1e18;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setGuildSaleStartTime(uint256 _time) external onlyOwner {
        guildSaleStartTime = _time;
    }

    function setGuildSaleEndTime(uint256 _time) external onlyOwner {
        guildSaleEndTime = _time;
    }

    function setWhiteListeSaleStartTime(uint256 _time) external onlyOwner {
        whiteListeSaleStartTime = _time;
    }

    function setWhiteListeSaleEndTime(uint256 _time) external onlyOwner {
        whiteListeSaleEndTime = _time;
    }

    function setPublicSaleStartTime(uint256 _time) external onlyOwner {
        publicSaleStartTime = _time;
    }
    function setPublicSaleEndTime(uint256 _time) external onlyOwner {
        publicSaleEndTime = _time;
    }

    function setguildSalePrice(uint256 _price) external onlyOwner {
        guildSalePrice = _price;
    }

    function setMintPerTransaction(uint8 _nb) external onlyOwner {
        mintPerTransaction = _nb;
    }

    function setMintPerWallet(uint8 _nb) external onlyOwner {
        mintPerWallet = _nb;
    }

     function setEMAstronaut(address _astronaut) external onlyOwner {
        EMAstronaut = IEMERC721A(_astronaut);
    }

    function setEMPFP(address _pfp) external onlyOwner {
        EMPFP = IEMERC721A(_pfp);
    }

    function setEMDAO(address _dao) external onlyOwner {
        EMDAO = IEMERC721A(_dao);
    }

    function setEMPackage(address _package) external onlyOwner {
        EMPackage = IEMERC1155(_package);
    }

    function setEMRefundManager(address _refundManager) external onlyOwner {
        EMRefundManager = _refundManager;
    }

    function setEMCouponOne(address _couponOne) external onlyOwner {
         EMCouponOne = IERC20(_couponOne);
    }

    function setEMCouponTwo(address _couponOne) external onlyOwner {
         EMCouponTwo = IERC20(_couponOne);
    }

    
}