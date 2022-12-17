//SPDX-License-Identifier:GPL 3.0

// ╔══╗────────────╔══╗
// ║  ║ 9Tales.io  ║  ║
// ║ ╔╬═╦╗╔═╦═╦╦═╦╗║╔╗║ 
// ║ ╚╣╬║╚╣╬║║║║╩╣╚╣╔╗║
// ╚══╩═╩═╩═╩╩═╩═╩═╩══╝

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.9;

interface INitItems {
    function balanceOf(address,uint256) external view returns(uint256);
    function burnFor(address, uint256, uint256) external;
}

contract NitClaimingHub is Ownable {

    // // CLAIM STRUCT
    
    struct Claim {
        address user;
        uint256 itemTokenId;
        uint256 userCounter;
        uint256 userNewBalanceOfItem;
        uint256 timestamp;
        string itemTitle;
        string userDiscord;
    }

    // // STATE

    // CONFIG
    
    bool public claimingPaused;
    address public defaultItemsContract;
    mapping(address => bool) public operators;
    mapping(uint256 => string) public itemTitle;

    // DATA

    uint256 public totalClaimed;
    mapping(address => Claim[]) public userClaims;
    mapping(uint256 => Claim[]) public itemClaims;

    // // EVENTS

    event ItemClaimed(address indexed user, uint256 indexed itemTokenId, uint256 userNewBalanceOfItem, string indexed itemTitle, string discordName);

    // // ERRORS

    error ClaimingPaused();
    error EoaOnly();
    error InsufficientSupply();
    error OnlyOperator();

    // // CONSTRUCTOR

    constructor(address _nitItemsContract) {
        defaultItemsContract = _nitItemsContract;
    }

    // // MAIN FUNCTION

    function claimItem(uint256 _itemId, string memory _discord) public {
        if (claimingPaused) revert ClaimingPaused();
        if (msg.sender != tx.origin) revert EoaOnly();
        uint256 _bal = INitItems(defaultItemsContract).balanceOf(msg.sender, _itemId);
        if (_bal < 1) revert InsufficientSupply();
        uint256 _userCounter = userClaimCounter(msg.sender);
        INitItems(defaultItemsContract).burnFor(msg.sender, _itemId, 1);
        totalClaimed++;
        Claim memory _claim = Claim({
                    user: msg.sender,
                    itemTokenId: _itemId,
                    userCounter: _userCounter,
                    userNewBalanceOfItem: _bal-1,
                    timestamp: block.timestamp,
                    itemTitle: itemTitle[_itemId],
                    userDiscord: _discord
                    
        });
        itemClaims[_itemId].push(_claim);
        userClaims[msg.sender].push(_claim);
        emit ItemClaimed(msg.sender, _itemId, _bal - 1, itemTitle[_itemId], _discord);
    }

    // // VIEW FUNCTIONS

    // COUNTERS

    function userClaimCounter(address _user) public view returns(uint256) {
        return userClaims[_user].length;
    }

    function itemClaimCounter( uint256 _id) public view returns(uint256) {
        return itemClaims[_id].length;
    }

    // ITEM CLAIMERS

    function getItemClaimersRAW(uint256 _id) public view returns(address[] memory) {
        uint256 _len = itemClaims[_id].length;
        if (_len == 0) return new address[](0);
        address[] memory _claimers = new address[](_len);
        for(uint256 i=0; i < _len; i++) {
            _claimers[i] = itemClaims[_id][i].user;
        }
        return _claimers;
    }

    function getItemClaimersPAGE(uint256 _id, uint256 _start, uint256 _maxLen) public view returns(address[] memory) {
        uint256 _len = itemClaims[_id].length;
        if (_start >= _len) return new address[](0);
        uint256 _finalLen = (_start + _maxLen < _len) ? _maxLen : _len - _start;
        address[] memory _claimers = new address[](_finalLen);
        for(uint256 i=0; i < _finalLen; i++) {
            _claimers[i] = itemClaims[_id][_start + i].user;
        }
        return _claimers;
    }

    // USER CLAIMS

    function getUserClaimsRAW(address _user) public view returns(Claim[] memory) {
        uint256 _len = userClaimCounter(_user);
        if (_len == 0) return new Claim[](0);
        Claim[] memory _claims = new Claim[](_len);
        for(uint256 i=0; i < _len; i++) {
            _claims[i] = userClaims[_user][i];
        }
        return _claims;
    }

    function getUserClaimsPAGE(address _user, uint256 _start, uint256 _maxLen ) public view returns(Claim[] memory) {
        uint256 _len = userClaimCounter(_user);
        if (_start >= _len) return new Claim[](0);
        uint256 _finalLen = (_start + _maxLen < _len) ? _maxLen : _len - _start;
        Claim[] memory _claims = new Claim[](_finalLen);
        for(uint256 i=0; i < _finalLen; i++) {
            _claims[i] = userClaims[_user][_start + i];
        }
        return _claims;
    }

    function getUserClaimAmountOfItem(address _user, uint256 _tokenId) public view returns(uint256 numberOfClaims) {
        for(uint256 i=0; i < userClaimCounter(_user); i++) {
            if(userClaims[_user][i].itemTokenId == _tokenId) numberOfClaims++;
        }
    }


    // // OPERATORS

    // MODIFIER 

    modifier onlyOperator() {
        if (!operators[msg.sender] && msg.sender != owner()) revert OnlyOperator();
        _;
    }

    // OPERATOR FUNCTIONS

    function setItemTitle(uint256 _id, string calldata _title) public onlyOperator {
        itemTitle[_id] = _title;
    }

    function setClaimingPaused(bool _newPausedState) public onlyOperator {
        claimingPaused = _newPausedState;
    }
    
    // // OWNER FUNCTIONS
    
    function setDefaultItemsContract(address _defaultItemsContract) public onlyOwner {
        defaultItemsContract = _defaultItemsContract;
    }

    function setOperator(address _operator, bool _isAuthorized) public onlyOwner {
        operators[_operator] = _isAuthorized;
    }

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