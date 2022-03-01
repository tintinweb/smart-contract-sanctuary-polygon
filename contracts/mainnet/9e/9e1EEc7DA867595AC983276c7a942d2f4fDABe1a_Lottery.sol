/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/lottery.sol


pragma solidity ^0.8.6;



interface ExternalContract {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function balanceOf(address account) external returns (uint256 balance);
  function balanceOf(address account, uint256 id) external returns (uint256 balance);
  function isApprovedForAll(address account, address operator) external returns (bool approved);
}

contract Lottery is Ownable, ERC1155Holder {
  enum LotteryState { Open, Closed }
  LotteryState public state;

  uint256 public entryFee;

  uint timeUnits = 1 days;
  uint8 public frequencyInDays;
  uint public nextDrawTime;
  uint public gameNumber;
  
  address public lastWinnerAddress;
  address[] public lastWinnerAddressList;
  address[] players;

  mapping (address => bool) public ticketContracts;
  mapping(address => bool) public whitelistedCollections;
  
  event LotteryStateChanged(LotteryState newState);
  event NewEntry(address player);
  event WinnerAddress(address winnerAddress);
  event NextDrawTime(uint nextDrawTime);
  
  modifier isState(LotteryState _state) {
    require(state == _state, "Wrong state for this action");
    _;
  }

  modifier isDrawable {
    require(players.length > 2, "There should be at least 3 players");
    require(block.timestamp >= nextDrawTime, "Is not yet the right time to draw the lottery");
    _;
  }

  constructor(uint256 _entryFee, uint8 _frequencyInDays) Ownable() {
    require(_entryFee > 0, "Entry fee must be greater than 0");
    entryFee = _entryFee;
    frequencyInDays = _frequencyInDays;
    nextDrawTime = block.timestamp + frequencyInDays * timeUnits;
    _changeState(LotteryState.Open);
  }

  function subscribe(address _contractAddress, uint _tokenId) external payable isState(LotteryState.Open) {
    require(msg.value >= entryFee, "Entry fee is required");
    require(ticketContracts[_contractAddress] || whitelistedCollections[_contractAddress], "This Contract is not allowed, contact the Owner");
    
    ExternalContract externalContract = ExternalContract(_contractAddress);
    
    if (ticketContracts[_contractAddress]) { 
      require(externalContract.balanceOf(msg.sender, _tokenId) > 0, "You do not own this Token, verify your Token ID");  
      require(ticketContracts[_contractAddress], "This NFT Ticket Contract is not allowed, contact the Owner");
      require(externalContract.isApprovedForAll(msg.sender, address(this)), "You must first approve() this contract to transfer the Lottery Ticket");
      externalContract.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    } else {
        require(externalContract.balanceOf(msg.sender) > 0, "it seems like you do not own this Token make sure your collection is whitelisted");
    }

    players.push(msg.sender);
    emit NewEntry(msg.sender);
  }

  function addTicketContracts(address[] memory _addresses) external onlyOwner {
    for(uint8 i; i < _addresses.length; i++){
      ticketContracts[_addresses[i]] = true;
    }   
  }

  function removeTicketContracts(address[] memory _addresses) external onlyOwner {
    for(uint8 i; i < _addresses.length; i++){
      ticketContracts[_addresses[i]] = false;
    }   
  }  

  function whitelistCollections(address[] memory _addresses) external onlyOwner {
    for(uint8 i; i < _addresses.length; i++){
      whitelistedCollections[_addresses[i]] = true;
    }   
  }

  function removeCollectionsFromWhitelist(address[] memory _addresses) external onlyOwner {
    for(uint8 i; i < _addresses.length; i++){
      whitelistedCollections[_addresses[i]] = false;
    }   
  }  

  function updateFrequencyInDays(uint8 _frequencyInDays) external onlyOwner {
    frequencyInDays = _frequencyInDays;
    _calculateNextDrawTime();
  }


  function drawAndTransferSplit() external isDrawable returns(address[] memory)  {
    _calculateNextDrawTime();
    uint256 amount;
    uint256 index;
    address drawnAddress;

    lastWinnerAddressList = new address[](0);      

    for (uint8 count = 1; count <= 3; count++) {
      index = random() % players.length;
      drawnAddress = players[index];
      players[index] = players[players.length - 1];
      players.pop();
      
      lastWinnerAddressList.push(drawnAddress);
      amount = (address(this).balance * 50) / 100;
      payable(drawnAddress).transfer(amount);            
    }

    amount = (address(this).balance * 50) / 100;
    payable(owner()).transfer(amount);
    //emit WinnerAddress(lastWinnerAddress);
    players = new address[](0);
    gameNumber++;      
    return lastWinnerAddressList;
  }

  function openLottery() external onlyOwner {
    _changeState(LotteryState.Open);
  }

  function closeLottery() external onlyOwner {
    _changeState(LotteryState.Closed);
  } 

  function setEntryFee(uint256 _entryFee) external onlyOwner {
    entryFee = _entryFee;
  }

  function getPlayers() external view returns (address[] memory) {
    return players;
  }

  function getPlayersCount() external view returns (uint256) {
    return players.length;
  }

  function getAwardBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function random() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function _changeState(LotteryState _newState) private {
		state = _newState;
		emit LotteryStateChanged(state);
	}

  function _calculateNextDrawTime() private {
    nextDrawTime = block.timestamp + frequencyInDays * timeUnits;
    emit NextDrawTime(nextDrawTime);
  } 

}