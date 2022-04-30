/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface INFT {
	function mint(
		address _to,
		uint256 _id,
		uint256 _quantity,
		bytes memory _data
	) external;
}

contract UAAvengersSale is Ownable {

	mapping(uint => uint) public prices;

	address payable public receiver;
	
	INFT public nft;

	constructor(address _nftAddress, address payable _receiverAddress) public {
		nft = INFT(_nftAddress);
		
		receiver = _receiverAddress;

		prices[1] = 450e18; //5
		prices[2] = 175e18; //10
		prices[3] = 875e18; //2
    prices[4] = 175e18;
    prices[5] = 875e18; //2
    prices[6] = 175e18;
    prices[7] = 175e18;
    prices[8] = 450e18; //5
    prices[9] = 175e18;
    prices[10] = 175e18;
    prices[11] = 450e18; //5
    prices[12] = 175e18;
    prices[13] = 175e18;
    prices[14] = 175e18;
    prices[15] = 175e18;
    prices[16] = 175e18;
    prices[17] = 175e18;
    prices[18] = 175e18;
    prices[19] = 175e18;
    prices[20] = 175e18;
    prices[21] = 175e18;

	}

	function setPrice(uint id, uint newPrice) public onlyOwner {
		prices[id] = newPrice;
	}
	
	/*
	 * @dev function to buy tokens. 
	 * @param _amount how much tokens can be bought.
	 */
	function buyBatch(uint id, uint _amount) external payable {
		require(_amount > 0, "empty input");

		require(prices[id] > 0, "tokens are not on sale");
		uint currentPrice = prices[id] * _amount;
		require(msg.value >= currentPrice, "too low value");
		if(msg.value > currentPrice) {
			//send the rest back
			(bool sent, ) = payable(msg.sender).call{value: msg.value - currentPrice}("");
      require(sent, "Failed to send Ether");
		}
		
		nft.mint(msg.sender, id, _amount, "0x");
		
		(bool sent, ) = receiver.call{value: address(this).balance}("");
    require(sent, "Something wrong with receiver");
	}

	function cashOut(address _to) public onlyOwner {
    // Call returns a boolean value indicating success or failure.
    // This is the current recommended method to use.
    require(_to != address(0), "invalid address");
    
    (bool sent, ) = _to.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }
}