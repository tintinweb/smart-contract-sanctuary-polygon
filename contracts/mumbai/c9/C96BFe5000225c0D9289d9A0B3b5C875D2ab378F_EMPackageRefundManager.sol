/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]


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


// File interfaces/IEMPackage.sol

pragma solidity >=0.7.0 <0.9.0;


interface IEMPackage {
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


// File contracts/EMPackageRefundManager.sol


pragma solidity >=0.7.0 <0.9.0;








//import "hardhat/console.sol";

contract EMPackageRefundManager is Ownable, Pausable, ReentrancyGuard {

    event PackageRefunded(address owner, uint256 id, PackageType packageType, uint256 astronautId, uint256 pfpId, uint256 daoId, bool hasRefunded, uint256 refundedTimestamp, uint256 price);

    IEMERC721A EMAstronaut;
    IEMERC721A EMPFP;
    IEMERC721A EMDAO;
    IEMPackage EMPackage;

    uint256 public constant MAX_REFUND_PERIOD = 7 days;
    uint256 public refundPeriod = 7 days;

    modifier onlyAfterAllValidRefund() {

        for (uint8 typeIndex = 0; typeIndex < 4; typeIndex++) {
                uint256 count = EMPackage.packagesPerTypeCount(PackageType(typeIndex));
                for (uint256 index = 0; index < count; index++) {
                    require(!EMPackage.canBeRefuned(PackageType(typeIndex), index, refundPeriod), "The are still refundable packages");
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
        require(EMPackage.ckeckIfPackageRefundale(_packageId), "This package can not be refunded");
        require(EMPackage.ownerOf(_packageType,_packageId) == msg.sender, "You are not the owner of this package");
        Package memory package = EMPackage.getPackageByOwner(msg.sender, _packageType, _packageId);
        uint256 astronautId = package.astronautId;
        uint256 daoId = package.daoId;
        uint256 pfpId = package.pfpId;
        uint256 price = package.price;
        bool hasRefunded = package.hasRefunded;
        bool refundable = package.refundable;
        require(price > 0 && refundable && ! hasRefunded, "can not refund this package");
        require(checkRefundExpiration(package.refundStartTimestamp) == true, "Refund expired");
         
        require(address(this).balance >= price, "not enough balance");

        PackageType packageType = package.packageType;

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
        EMPackage.setPackageRefund(msg.sender, uint256(_packageType), _packageId);

        payable(msg.sender).call{value: price }("");

        emit PackageRefunded(msg.sender, _packageId, _packageType, astronautId, pfpId, daoId, true, currentTime(), price);
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function setRefundPeriod(uint256 _period) external onlyOwner {
        require(_period <= MAX_REFUND_PERIOD, "publicSaleEndTime must be grander than publicSaleStartTime");
        refundPeriod = _period;
    }

    function checkRefundExpiration(uint256 _refundStartTimestamp) public view returns (bool) {
        return block.timestamp <= _refundStartTimestamp + refundPeriod;
    }

    function withdraw() external onlyOwner onlyAfterAllValidRefund {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more than zero");
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "EMPackageRefundManager(withdraw): Failed to send Ether");
    }
    
}