/**
 *Submitted for verification at polygonscan.com on 2022-08-01
*/

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

// File: contracts/firebot_market.sol

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface IWeth {
	function transferFrom(address sender, address recipient, uint256 amount) external;
}

interface IFireBots {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract firebot_market is Ownable {
	
	IWeth public weth = IWeth(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
	IFireBots public firebots = IFireBots(0xE9eeE7294dc7c3bb64FD57A514E755022a333295);

	address holder_address;
	uint256 next_bot_id;
	uint256 bot_price;
	
	constructor() {
        holder_address = 0x5d8dc02Ab5659EeAA4536f777B6aDbecbC8E5cBa;
        next_bot_id = 1001;
		bot_price = 444000000000000000; // 0.444
    }
	
	// holder address
	function set_holder_address(address new_holder_address) public onlyOwner {
		holder_address = new_holder_address;
	}
	
	function get_holder_address() public view returns (address) {
		return holder_address;
	}
	
	// next bot for sale
	function set_next_bot_id(uint256 new_next_bot_id) public onlyOwner {
		next_bot_id = new_next_bot_id;
	}
	
	function get_next_bot_id() public view returns (uint256) {
		return next_bot_id;
	}
	
	function find_next_bot_id() public {
		if (firebots.ownerOf(next_bot_id) != holder_address) {
			next_bot_id += 1;
			if (next_bot_id > 10000) {
				next_bot_id = 1001;
			}
			find_next_bot_id();
		}		
	}
	
	// bot price
	function set_bot_price(uint256 new_bot_price) public onlyOwner {
		bot_price = new_bot_price;
	}
	
	function get_bot_price() public view returns (uint256) {
		return bot_price;
	}
	
	// sales functions
    function buy_firebot() public {
        require(firebots.balanceOf(holder_address) > 0, "No more bots to sell");
		find_next_bot_id();
		weth.transferFrom(tx.origin, holder_address, bot_price);
		firebots.safeTransferFrom(holder_address, tx.origin, next_bot_id);
    }

	function buy_firebot(address promoter) public {
		require(firebots.balanceOf(holder_address) > 0, "No more bots to sell");
		find_next_bot_id();
		weth.transferFrom(tx.origin, holder_address, bot_price * 80 / 100);
		weth.transferFrom(tx.origin, tx.origin, bot_price * 10 / 100);
		weth.transferFrom(tx.origin, promoter, bot_price * 10 / 100);
		firebots.safeTransferFrom(holder_address, tx.origin, next_bot_id);
    }
}