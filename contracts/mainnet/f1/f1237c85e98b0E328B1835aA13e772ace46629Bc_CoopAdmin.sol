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
pragma solidity 0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function mintIncrementalCards(uint256 numberOfCards, address recipient) external returns (uint256);
    function TraitRegistry() external returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ITraitRegistry {
    function getImplementer(uint16 traitID) external returns (address);
    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external;
    function hasTrait(uint16 traitID, uint16 tokenId) external view returns (bool);
}

interface ITraitUint256ValueImplementer {
    function setValue(uint16 _tokenId, uint256 _value) external;
    function getValue(uint16 _tokenId) external view returns (uint256);
}

interface ITraitUint8ValueImplementer {
    function setValue(uint16 _tokenId, uint8 _value) external;
    function getValue(uint16 _tokenId) external view returns (uint8);
}

contract CoopAdmin is Ownable {
    uint8 internal constant ACTIVATED_TRAIT_ID = 1;
    uint8 internal constant STAKE_TRAIT_ID = 2;
    uint8 internal constant FULL_MEMBERSHIP_TRAIT_ID = 6;

    uint8 internal constant CALLTYPE_TRANSFER_FROM_OWNER = 0;
    uint8 internal constant CALLTYPE_MINT = 1;
    uint8 internal constant CALLTYPE_SET_ACTIVE = 2;


    IToken token;
    ITraitRegistry traitRegistry;
    ITraitUint256ValueImplementer stakeImplementer;
    ITraitUint8ValueImplementer activatedImplementer;

    mapping (address => bool) public allowedMint;

    event CoopAdminEvent(uint8 calltype, uint16 tokenId, address owner ,uint8 activated, uint256 stake, bool fullMembership, uint256 timestamp);

    constructor(address tokenAddress) Ownable(){
        token = IToken(tokenAddress);
        traitRegistry = ITraitRegistry(token.TraitRegistry());               
        stakeImplementer = ITraitUint256ValueImplementer(traitRegistry.getImplementer(STAKE_TRAIT_ID));
        activatedImplementer = ITraitUint8ValueImplementer(traitRegistry.getImplementer(ACTIVATED_TRAIT_ID));
    }

    function mintMultiple(address to, uint16 numberOfCards) public onlyOwner{
        require(numberOfCards <= 100, "CoopAdmin: max 100 cards at a time");
        token.mintIncrementalCards(numberOfCards, to);
    }

    function transferFromOwner(uint16 tokenId, address to, uint256 stake, uint8 activated, bool fullMembership) public onlyOwner {
        require(activatedImplementer.getValue(tokenId) == 0, "CoopAdmin: token already activated");
        token.safeTransferFrom(owner(), to, tokenId);
        activatedImplementer.setValue(tokenId, activated);
        stakeImplementer.setValue(tokenId, stake);
        traitRegistry.setTrait(FULL_MEMBERSHIP_TRAIT_ID, tokenId, fullMembership); 
        emit CoopAdminEvent(CALLTYPE_TRANSFER_FROM_OWNER ,tokenId, to, activated, stake, fullMembership, block.timestamp);
    }

    function mint(address to, uint256 stake, uint8 activated, bool fullMembership ) public allowMint {
        require(to != address(0), "CoopAdmin: cannot mint to zero address");
        uint256 tokenId = token.mintIncrementalCards(1, to) - 1;
        
        stakeImplementer.setValue(uint16(tokenId), stake);
        activatedImplementer.setValue(uint16(tokenId), activated);
        traitRegistry.setTrait(FULL_MEMBERSHIP_TRAIT_ID, uint16(tokenId), fullMembership);
        emit CoopAdminEvent(CALLTYPE_MINT, uint16(tokenId), to, activated, stake, fullMembership , block.timestamp);
    }

    function setActive(uint16 tokenId, uint8 activated, address owner) public onlyOwner {
        require(token.ownerOf(tokenId) == owner, "CoopAdmin: Not the expected owner");
        activatedImplementer.setValue(tokenId, activated);
        emit CoopAdminEvent(CALLTYPE_SET_ACTIVE ,tokenId, owner , activated, stakeImplementer.getValue(tokenId), traitRegistry.hasTrait(FULL_MEMBERSHIP_TRAIT_ID, tokenId) ,block.timestamp);
    }

    modifier allowMint(){
        require(msg.sender == owner() || allowedMint[msg.sender], "CoopAdmin: not allowed to mint");
        _;
    }

    function setAllowedMint(address _address, bool _allowed) public onlyOwner {
        allowedMint[_address] = _allowed;
    }
}