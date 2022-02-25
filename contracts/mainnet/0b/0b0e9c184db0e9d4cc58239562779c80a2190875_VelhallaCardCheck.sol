/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

interface IVelhallaCard {

    function balanceOf(address account, uint256 id) external view returns (uint256);

}

// File: contracts/VelhallaCardCheck.sol


pragma solidity ^0.8.0;



contract VelhallaCardCheck is Ownable {

	uint256 public chapterPerBook = 5;
	uint256 public goldedCardPerBookAmount = 500;
    uint256 public ID_GOLD_CARD_START = 1000000;

    uint256 silverCardBoundary = 10;
    uint256 bookBoundary = 1;
    uint256 cardIssuedAmount = 100;

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    struct pair {
	    uint256 tokenid;
	    uint256 amount;
	}

    struct goldenpair {
	    uint256 book;
	    uint256 tokenid;
	}

    IVelhallaCard public cardContract ;

    constructor() {}


// internal


// public

    function walletOfSilverCardOwner(address _owner) public view returns (pair[] memory) {
        uint256 ownerTokenCount = silverCardBoundary;
        uint256 j = 0;

        for (uint256 i ; i < ownerTokenCount; i++) {
            if (cardContract.balanceOf(_owner, i+1) != 0) {
                j++;
			}
        }

        pair[] memory tokenPair = new pair[](j);		
        uint256 k = 0;
        for (uint256 ir ; ir < ownerTokenCount; ir++) {
            if (cardContract.balanceOf(_owner, ir+1) != 0) {
                tokenPair[k].tokenid = (ir+1);
			    tokenPair[k].amount = (cardContract.balanceOf(_owner, ir+1));
                k++;
			}
        }
        return tokenPair;
    }

    function walletOfGoldCardOwner(address _owner) public view returns (goldenpair[] memory) {
        uint256 k = 0;
        for (uint256 i ; i < bookBoundary; i++) {
            if ( i == (bookBoundary-1)) {    
                for (uint256 j; j < cardIssuedAmount; j++) {
			        if (cardContract.balanceOf(_owner, ((ID_GOLD_CARD_START * (i+1))+j+1)) != 0)
			        {
                        k++;
			        }
                }
            }
			else {
                for (uint256 j; j < goldedCardPerBookAmount ; j++) {
			        if (cardContract.balanceOf(_owner, ((ID_GOLD_CARD_START * (i+1))+j+1)) != 0)
			        {
                        k++;
			        }
                }			
			}
        }
        goldenpair[] memory searchPair = new goldenpair[](k);        
        uint256 l = 0;
        for (uint256 ir ; ir < bookBoundary; ir++) {
            if ( ir == (bookBoundary-1)) {    
                for (uint256 jr; jr < cardIssuedAmount; jr++) {
			        if (cardContract.balanceOf(_owner, ((ID_GOLD_CARD_START * (ir+1))+jr+1)) != 0)
			        {
                        searchPair[l].book = ir + 1;
                        searchPair[l].tokenid = (ID_GOLD_CARD_START * (ir+1)) + jr + 1;
                        l++;
			        }
                }
            }
			else {
                for (uint256 jr; jr < goldedCardPerBookAmount ; jr++) {
			        if (cardContract.balanceOf(_owner, ((ID_GOLD_CARD_START * (ir+1))+jr+1)) != 0)
			        {
                        searchPair[l].book = ir + 1;
                        searchPair[l].tokenid = (ID_GOLD_CARD_START * (ir+1)) + jr + 1;
                        l++;
			        }
                }			
			}
        }		

        return searchPair;
    }

// private

// external

// only owner

    function setCardContractAddress(address _cardContract) external onlyOwner {
        cardContract = IVelhallaCard(_cardContract);
    }

    function setSilverCardSearchBoundary(uint256 _book, uint256 _chapter) external onlyOwner {
        silverCardBoundary = (_book - 1) * chapterPerBook + _chapter;
    }

    function setGoldedCardSearchBoundary(uint256 _book, uint256 _cardissuedamount) external onlyOwner {
        bookBoundary = _book;
		cardIssuedAmount = _cardissuedamount;
    }

    function setChapterPerBook(uint256 _number) external onlyOwner {
        chapterPerBook = _number;
    }

    function setGoldedCardPerBookAmount(uint256 _amount) external onlyOwner {
        goldedCardPerBookAmount = _amount;
    }

}