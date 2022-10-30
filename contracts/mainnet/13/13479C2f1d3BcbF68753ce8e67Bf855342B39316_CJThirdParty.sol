/**
 *Submitted for verification at polygonscan.com on 2022-10-30
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/CJThirdParty.sol


pragma solidity 0.8.17;


//      ____       _ _______ _           
//     |  _ \     (_)__   __| |          
//     | |_) |_ __ _   | |  | |__   __ _ 
//     |  _ <| '__| |  | |  | '_ \ / _` |
//     | |_) | |  | |  | |  | | | | (_| |
//     |____/|_|  |_|  |_|  |_| |_|\__,_|
//   _____                  _         _____             
//  / ____|                | |       / ____|            
// | |     _ __ _   _ _ __ | |_ ___ | |  __ _   _ _   _ 
// | |    | '__| | | | '_ \| __/ _ \| | |_ | | | | | | |
// | |____| |  | |_| | |_) | || (_) | |__| | |_| | |_| |
//  \_____|_|   \__, | .__/ \__\___/ \_____|\__,_|\__, |
//               __/ | |                           __/ |
//              |___/|_|                          |___/     


interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract CJThirdParty is Ownable {

    IERC1155 public _cj_poaps;
    bool public _paused = false;
    address public _pool;
    uint8[] public _allowed_claims = [3,5];

    constructor() {
        _cj_poaps = IERC1155(0xB8818Ba78656Afb2FEaA39794fE98737125914f1);
        _pool = 0x568BF57B841Cd790ebE7D7E08b68903559A15901;
    }

    function claim(uint8 _id) external {
        require(!_paused, "ERR:CP");
        require(check_claimable(_id), "ERR:NC");
        _cj_poaps.safeTransferFrom(_pool, msg.sender, _id, 1, "");
    } 

    function check_claimable(uint8 _id) internal view returns(bool) {
        bool temp = false;
        for (uint i = 0; i < _allowed_claims.length; i++) {
            if (_id == _allowed_claims[i]) {
                temp = true;
            }
        }
        return temp;
    }

    function set_claimable(uint8[] calldata _ids ) external onlyOwner {
        delete _allowed_claims;
        _allowed_claims = _ids;
    }

    function set_paused(bool _state) external onlyOwner {
        _paused = _state;
    }


}