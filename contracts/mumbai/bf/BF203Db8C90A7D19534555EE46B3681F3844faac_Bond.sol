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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./interfaces/IBond.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Create smart contracts to represent the bonds to be listed on the marketplace,
// and deploy them to the Polygon network using the Polygon SDK.
contract Bond is IBond, Ownable {
    // Create an mapping to store all of the bonds that have been issued
    mapping(uint256 => BondStruct) bonds;
    mapping(uint256 => address) investors;
    uint256 public totalBonds;
    address escrow;

    constructor() payable {
        totalBonds = 0;
        escrow = msg.sender;
    }

    function issueBond(
        uint256 _faceValue,
        uint256 _couponRate,
        uint256 _maturityDate
    ) external payable onlyOwner {
        require(_faceValue > 0, "Bond: invalid face value");
        require(_maturityDate > block.timestamp, "Bond: invalid maturity date");

        bonds[totalBonds] = BondStruct(
            _faceValue,
            _couponRate,
            _maturityDate,
            msg.sender
        );

        emit BondIssued(totalBonds, msg.sender);

        totalBonds = totalBonds + 1;
    }

    function getBondDetails(
        uint256 bondId
    ) external view returns (uint256, uint256, uint256, address) {
        BondStruct storage bondDetail = bonds[bondId];
        return (
            bondDetail.faceValue,
            bondDetail.couponRate,
            bondDetail.maturityDate,
            bondDetail.issuer
        );
    }

    function setInvestor(uint256 bondId, address investor) external payable {
        investors[bondId] = investor;
    }

    function checkIfInvestor(
        uint256 bondId,
        address investor
    ) external view returns (bool) {
        return investors[bondId] == investor;
    }

    function setEscrow(address _escrow) external payable onlyOwner {
        escrow = _escrow;
    }

    function getEscrow() external view returns (address) {
        return escrow;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBond {
    // Define the BondStruct struct to represent a bond
    struct BondStruct {
        uint256 faceValue;
        uint256 couponRate;
        uint256 maturityDate;
        address issuer;
    }

    event BondIssued(uint256 bondId, address issuer);

    function issueBond(
        uint256 _faceValue,
        uint256 _couponRate,
        uint256 _maturityDate
    ) external payable;

    function getBondDetails(
        uint256 bondId
    ) external view returns (uint256, uint256, uint256, address);

    function setInvestor(uint256 bondId, address investor) external payable;

    function checkIfInvestor(
        uint256 bondId,
        address investor
    ) external view returns (bool);

    function setEscrow(address _escrow) external payable;

    function getEscrow() external view returns (address);
}