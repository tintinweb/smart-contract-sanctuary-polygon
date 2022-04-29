/**
 *Submitted for verification at polygonscan.com on 2022-04-28
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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


// File contracts/EMPackageFactory.sol



pragma solidity >=0.7.0 <0.9.0;



//import "hardhat/console.sol";

error DoNotHavePackage();

contract EMPackageFactory {
    event PackageCreated(address owner, uint256 id, PackageType packageType, uint256 astronautId, uint256 pfpId, uint256 daoId, bool refundable, uint256 refundStartTimestamp, uint256 creationTime, uint256 price);
    event PackageRefunded(address owner, uint256 id, PackageType packageType, uint256 astronautId, uint256 pfpId, uint256 daoId, bool hasRefunded, uint256 refundedTimestamp, uint256 price);

    mapping (PackageType => mapping (uint256 => address)) internal ownership;
    mapping (address => mapping (PackageType => Package[]))  internal userPackagesPerType;// User packes per types
    mapping (PackageType => Package[]) internal packagesPerType;
    mapping (address => uint256) internal userPackagesCount;
    mapping (uint256 => bool) internal isPackageRefundale;
    mapping (uint256 => uint256) internal astronautToDao;
    uint256 internal packagesToBeRefundedCount;
    uint256 internal totalPackagesCount;

    function createPackage(address _owner,
    PackageType _packageType,
    uint256 _tokenId,
    uint256 _astronautId,
    uint256 _pfpId,
    uint256 _daoId,
    bool _refundable,
    uint256 _price) internal {
        ownership[_packageType][_tokenId] = _owner;
        userPackagesCount[_owner]++;
        totalPackagesCount++;

        uint256 time = 0;
        if(_refundable){
            time = currentTime();
            isPackageRefundale[_tokenId] = true;
            packagesToBeRefundedCount++;
        }
        if(_daoId > 0){
            astronautToDao[_astronautId]=_daoId;
        }
        Package memory pack = Package(
                _tokenId,
                _packageType,
                _astronautId,
                _pfpId,
                _daoId,
                _refundable,
                false,
                currentTime(),
                time,
                0,
                _price
            );
        userPackagesPerType[_owner][_packageType].push(pack);
        packagesPerType[_packageType].push(pack);
        emit PackageCreated(_owner, _tokenId, _packageType, _astronautId, _pfpId, _daoId, _refundable, time, currentTime(), _price);
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function getPackagesByOwner(address _owner, PackageType _packageType) public view returns(Package[] memory) 
    {
        if(userPackagesCount[_owner] == 0 || userPackagesPerType[_owner][_packageType].length == 0) revert DoNotHavePackage();
        return userPackagesPerType[_owner][_packageType];
    }
}



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


// File interfaces/IERC20.sol



pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transferFor(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



pragma solidity >=0.7.0 <0.9.0;

interface IEMPackage {
    function mint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external;

    function burnToken(
        address owner,
        uint256 id,
        uint256 value
    ) external;

}


// File enums/SaleStep.sol


pragma solidity >=0.7.0 <0.9.0;


enum SaleStep { PrivateComingSoon, PrivateSale, PublicSale, PrivateSoldOut, SoldOut, Reveal }


// File contracts/EMPackageRefundManager.sol


pragma solidity >=0.7.0 <0.9.0;







//import "hardhat/console.sol";

contract EMPackageRefundManager is Ownable, Pausable, ReentrancyGuard, EMPackageFactory {
    IEMERC721A EMAstronaut;
    IEMERC721A EMPFP;
    IEMERC721A EMDAO;
    IEMPackage EMPackage;

    uint256 public constant MAX_REFUND_PERIOD = 7 days;
    uint256 public refundPeriod = 7 days;

    modifier onlyAfterAllValidRefund() {

        for (uint8 typeIndex = 0; typeIndex < 4; typeIndex++) {
                for (uint256 index = 0; index < packagesPerType[PackageType(typeIndex)].length; index++) {
                    require(!canBeRefuned(PackageType(typeIndex), index), "The are still refundable packages");
                }
            }
        _;
    }

    constructor(
        IEMERC721A astronaut_,
        IEMERC721A pfp_,
        IEMERC721A dao_,
        IEMPackage package_
        ){
        EMAstronaut = astronaut_;
        EMPFP = pfp_;
        EMDAO = dao_;
        EMPackage = IEMPackage(package_);
    }
    
    function refund(PackageType _packageType, uint256 _packageId) external nonReentrant whenNotPaused {
        require(isPackageRefundale[_packageId], "This package can not be refunded");
        require(ownership[_packageType][_packageId] == msg.sender, "You are not the owner of this package");
        bool refundable = userPackagesPerType[msg.sender][_packageType][_packageId].refundable;
        bool hasRefunded = userPackagesPerType[msg.sender][_packageType][_packageId].hasRefunded;
        uint256 price =  userPackagesPerType[msg.sender][_packageType][_packageId].price;
        
        require(price > 0 && refundable && !hasRefunded, "can not refund this package");
        require(checkRefundExpiration(_packageType, _packageId), "Refund expired");
         
        require(address(this).balance >= price, "not enough balance");
        userPackagesPerType[msg.sender][_packageType][_packageId].hasRefunded = true;

        uint256 astronautId = userPackagesPerType[msg.sender][_packageType][_packageId].astronautId;
        uint256 daoId = userPackagesPerType[msg.sender][_packageType][_packageId].daoId;
        uint256 pfpId = userPackagesPerType[msg.sender][_packageType][_packageId].pfpId;
       
        PackageType packageType = userPackagesPerType[msg.sender][_packageType][_packageId].packageType;

        EMAstronaut.burn(astronautId);
        if( packageType == PackageType.EXPLORER
        || packageType == PackageType.HEADSTART){
            EMPFP.burn(pfpId);
        }
        if( packageType == PackageType.FOUNDER){
            EMDAO.burn(daoId);
            EMPFP.burn(pfpId);
        }
        EMPackage.burnToken(msg.sender, _packageId, 1);
        packagesToBeRefundedCount--;
        isPackageRefundale[_packageId] = false;
        userPackagesCount[msg.sender]--;
        packagesToBeRefundedCount--;
        delete ownership[_packageType][_packageId];
        delete userPackagesPerType[msg.sender][_packageType][_packageId];
        (bool sent, ) = payable(msg.sender).call{value: price }("");
        require(sent, "Failed to send Ether");

        emit PackageRefunded(msg.sender, _packageId, _packageType, astronautId, pfpId, daoId, true, currentTime(), price);
    }

    function setRefundPeriod(uint256 _period) external onlyOwner {
        require(_period <= MAX_REFUND_PERIOD, "publicSaleEndTime must be grander than publicSaleStartTime");
        refundPeriod = _period;
    }

    function checkRefundExpiration(PackageType _packageType, uint256 _packageId) public view returns (bool) {
        return block.timestamp <= packagesPerType[_packageType][_packageId].refundStartTimestamp + refundPeriod;
    }

    function canBeRefuned(PackageType _packageType, uint256 _index) private view returns(bool){
       return packagesPerType[_packageType][_index].refundStartTimestamp > 0 &&
        checkRefundExpiration(_packageType, _index) &&
        !packagesPerType[_packageType][_index].hasRefunded;
    }

    function withdraw() external onlyOwner onlyAfterAllValidRefund {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more than zero");
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
    
}


// File contracts/EMPackageSaleManager.sol



pragma solidity >=0.7.0 <0.9.0;











//import "hardhat/console.sol";

contract EMPackageSaleManager is EMPackageFactory, Pausable, Ownable {

    IERC20 EMCouponOne;
    IERC20 EMCouponTwo;
    IEMERC721A EMAstronaut;
    IEMERC721A EMPFP;
    IEMERC721A EMDAO;
    IEMPackage EMPackage;

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
    bytes32 public merkleRoot;
    uint256 public guildSalePrice = 1e18;
    uint256 public guildSaleStartTime = 1651701600;
    uint256 public guildSaleEndTime = 1652219999;
    uint256 public whiteListeSaleStartTime = 1651701600;
    uint256 public whiteListeSaleEndTime = 1652219999;
    uint256 public publicSaleStartTime = 1652220000;
    uint256 public publicSaleEndTime = 1652911198;
    SaleStep private saleStep;

    modifier updateSaleStape() {
        if(currentTime() < guildSaleStartTime)
            saleStep = SaleStep.PrivateComingSoon;
        if(guildSaleStartTime <= currentTime() && currentTime() < whiteListeSaleEndTime)
            saleStep = SaleStep.PrivateSale;
        if(publicSaleStartTime < currentTime() && currentTime() < publicSaleEndTime)
            saleStep = SaleStep.PublicSale;
        if(privateSaleCount == MAX_PRIVATE)
            saleStep = SaleStep.PrivateSoldOut;
        if(totalPackagesCount == MAX_SUPPLY)
            saleStep = SaleStep.SoldOut;
        _;
    }

    constructor(
        IERC20 couponOne_,
        IERC20 couponTwo_,
        IEMERC721A astronaut_,
        IEMERC721A pfp_,
        IEMERC721A dao_,
        IEMPackage package_,
        bytes32 merkleRoot_){
        EMCouponOne = IERC20(couponOne_);
        EMCouponTwo = IERC20(couponTwo_);
        EMAstronaut = astronaut_;
        EMPFP = pfp_;
        EMDAO = dao_;
        merkleRoot = merkleRoot_;
        EMPackage = IEMPackage(package_);
    }

    function guildSale()
    external
    whenNotPaused
    updateSaleStape
    {
        require(guildSalePrice != 0, "Price is 0");
        // require(currentTime() >= guildSaleStartTime,"Sorry, guild sale has not started yet");
        // require(currentTime() <= guildSaleEndTime, "Sorry, guild sale is ended");
        require(EMCouponOne.balanceOf(msg.sender) >= guildSalePrice
            || EMCouponTwo.balanceOf(msg.sender) >= guildSalePrice , "You dont have enough coupon");
        require(
            EMAstronaut.totalMinted() <= MAX_PRIVATE && EMPFP.totalMinted() <= MAX_PRIVATE,
            "Max supply exceeded"
        );

        PackageType packageType;
        if(EMCouponOne.balanceOf(msg.sender) >= guildSalePrice) {
            EMCouponOne.transferFor(msg.sender, address(this), guildSalePrice);
            packageType = PackageType.FOUNDER;
        }
        else if (EMCouponTwo.balanceOf(msg.sender) >= guildSalePrice ){
            EMCouponTwo.transferFor(msg.sender, address(this), guildSalePrice);
            packageType = PackageType.HEADSTART;
        }

        uint256 daoStartId;
        uint256 characterStartId = EMAstronaut.currentIndex();
        uint256 pfpStartId = EMPFP.currentIndex();
        EMAstronaut.safeMint(msg.sender, 1);
        EMPFP.safeMint(msg.sender, 1);

        if(packageType == PackageType.FOUNDER){
            daoStartId = EMDAO.currentIndex();
            EMDAO.safeMint(msg.sender, 1);
        }
        uint256 nextIndex = totalPackagesCount;
        EMPackage.mint(msg.sender,
        uint256(packageType),
        1,
        bytes(abi.encodePacked("Elon Must Package #", Strings.toString(uint256(packageType)),
        Strings.toString(nextIndex))));
        createPackage(msg.sender, packageType, nextIndex, characterStartId, pfpStartId, daoStartId, false, 0);
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
        // require(msg.value >= entryPrice * _quantity, "Not enough funds");
        // require(currentTime() >= whiteListeSaleStartTime,"Sorry, whiteList sale has not started yet");
        // require(currentTime() <= whiteListeSaleEndTime, "Sorry, whiteList sale is ended");
        // bool isPrivateSale = false;
        // if(currentTime() >= publicSaleStartTime && currentTime() < publicSaleEndTime){
        //      require(totalPackagesCount <= MAX_SUPPLY, "Max supply exceeded");
        // } else{
        //     require(isWhiteListed(msg.sender, _proof), "Not whiteListed");
        //     require(privateSaleCount <= MAX_PRIVATE, "Max supply exceeded");
        //     isPrivateSale = true;
        // }
        require(_quantity <= mintPerTransaction, "You can't mint more than 10 tokens in one time");
        require(_quantity + userPackagesCount[msg.sender] <= mintPerWallet, "You can't mint more than 20 tokens");

        uint256 price = entryPrice;
        if(_packageType == PackageType.FOUNDER){
            price = publicSaleFounderPrice;
            require(msg.value >= publicSaleFounderPrice * _quantity, "Not enough funds");
        }

        if(_packageType == PackageType.HEADSTART){
            price = publicSaleHeadStartPrice;
            require(msg.value >= publicSaleHeadStartPrice * _quantity, "Not enough funds");
        }

        if(_packageType == PackageType.EXPLORER){
            price = explorerPrice;
            require(msg.value >= explorerPrice * _quantity, "Not enough funds");
        }
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
            for (uint256 index = 0; index < _quantity; index++) {
                uint256 nextIndex = totalPackagesCount;
                characterStartId = characterStartId + index;
                daoStartId = daoStartId + index;
                pfpStartId = pfpStartId + index;
                EMPackage.mint(msg.sender,
                uint256(packageType),
                1,
                bytes(abi.encodePacked("Elon Must Package #", Strings.toString(uint256(packageType)),
                Strings.toString(nextIndex))));
                createPackage(msg.sender, packageType, nextIndex, characterStartId, pfpStartId, daoStartId, refundable, price);
            }
         }

        if(_packageType == PackageType.HEADSTART){
            PackageType packageType = _packageType;
            pfpStartId = EMPFP.currentIndex();
            EMPFP.safeMint(msg.sender, _quantity);
            createBatch(_quantity, packageType, characterStartId, pfpStartId, refundable, price);
         }

        if(_packageType == PackageType.EXPLORER){
            PackageType packageType = _packageType;
            pfpStartId = EMPFP.currentIndex();
            EMPFP.safeMint(msg.sender, _quantity);
            createBatch(_quantity, packageType, characterStartId, pfpStartId, refundable, price);
        }
    }

    function createBatch(uint8 _quantity, PackageType packageType, uint256 _characterStartId, uint256 _pfpStartId, bool refundable, uint256 price) private {
        for (uint256 index = 0; index < _quantity; index++) {
                uint256 nextIndex = totalPackagesCount;
                uint256 characterStartId = _characterStartId + index;
                uint256 pfpStartId = _pfpStartId + index;
                EMPackage.mint(msg.sender,
                uint256(packageType),
                1,
                bytes(abi.encodePacked("Elon Must Package #", Strings.toString(uint256(packageType)),
                Strings.toString(nextIndex))));
                createPackage(msg.sender, packageType, nextIndex, characterStartId, pfpStartId, 0, refundable, price);
            }
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

    function getSaleStep() public updateSaleStape returns(SaleStep){
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
}