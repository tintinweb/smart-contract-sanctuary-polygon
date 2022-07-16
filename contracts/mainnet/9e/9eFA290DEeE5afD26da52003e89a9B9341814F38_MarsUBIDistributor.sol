// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/OwnablePausable.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

interface IREDDIES {
  function mint(address to, uint256 amount) external;
  function burn(address to, uint256 amount) external;
}

contract MarsUBIDistributor is OwnablePausable, FxBaseChildTunnel {

  IREDDIES public reddies;

  uint256 public start;
  uint256 public end;
  uint256 public rate;
  uint256 public period;

  struct ClaimInfo {
    address recipient;
    uint64 lastClaim;
  }

  mapping(uint256 => ClaimInfo) public claimInfo;

  event Claim(address claimer, uint256[] tokenIds, uint256 amount, uint256 claimId);
  event Configuration(uint256 start, uint256 period, uint256 rate);
  event End(uint256 end);

  constructor(address _fxChild, address _reddies, uint256 _start, uint256 _period, uint256 _rate) FxBaseChildTunnel(_fxChild) {
    reddies = IREDDIES(_reddies);
    setParameters(_start, _period, _rate);
  }

  /**
  * @dev enables owner to configure the UBI
  */
  function setParameters(uint256 _start, uint256 _period, uint256 _rate) public onlyOwner {
    start = _start;
    period = _period;
    rate = _rate;
    emit Configuration(start, period, rate);
  }

  /**
  * @dev enables owner to set an end to UBI
  * @param _end the end timestamp
  */
  function setEnd(uint256 _end) external onlyOwner {
    require(_end > start, "MUST BE AFTER THE START");
    end = _end;
    emit End(end);
  }

  function getSeconds(uint256 _start, uint256 _end, uint256 last) public pure returns(uint256) {
    return (_end - (last >= _start ? last : _start));
  }

  function getEnd() public view returns(uint256 _end) {
    if(end == 0) {
      return block.timestamp;
    } else {
      return end < block.timestamp ? end : block.timestamp;
    }
  }

  function getClaimable(uint16[] calldata tokenIds) public view returns(uint256 totalClaimable) {

    uint _end = getEnd();
    for (uint i = 0; i < tokenIds.length; i++) {
      totalClaimable += getSeconds(start, _end, claimInfo[tokenIds[i]].lastClaim);
    }
    totalClaimable = rate * totalClaimable / period;
  }

    // @notice override to decode the data and call claimPlayers
  function _processMessageFromRoot(uint256 , address sender, bytes memory data)
		internal override validateSender(sender) 
	{
		 (uint256[] memory tokenIds, address payable recipient, uint256 claimId) = abi.decode(data, (uint256[], address, uint256));
		 _claimFromRoot(tokenIds, recipient, claimId);
	}

  // @notice set root contract (Owner only)
  function setTunnel(address _fxRootTunnel) public onlyOwner {
      fxRootTunnel = _fxRootTunnel;
  }

  function _claimFromRoot(uint256[] memory tokenIds, address recipient, uint256 claimId) internal whenNotPaused {
    
    uint256 totalClaimable;
    uint256 _end = getEnd();
    
    for (uint i = 0; i < tokenIds.length; i++) {
      totalClaimable += getSeconds(start, _end, claimInfo[tokenIds[i]].lastClaim);
      claimInfo[tokenIds[i]] = ClaimInfo(recipient, uint64(_end));
    }
    totalClaimable = rate * totalClaimable / period;
    reddies.mint(recipient, totalClaimable);
    emit Claim(recipient, tokenIds, totalClaimable, claimId);
  }

  function claim(uint256[] memory tokenIds) public whenNotPaused {
    
    uint256 totalClaimable;
    uint256 _end = getEnd();
    
    for (uint i = 0; i < tokenIds.length; i++) {
      require(msg.sender == claimInfo[tokenIds[i]].recipient, "NOT YOUR TOKEN");
      totalClaimable += getSeconds(start, _end, claimInfo[tokenIds[i]].lastClaim);
      claimInfo[tokenIds[i]] = ClaimInfo(msg.sender, uint64(_end));
    }
    totalClaimable = rate * totalClaimable / period;
    reddies.mint(msg.sender, totalClaimable);
    emit Claim(msg.sender, tokenIds, totalClaimable, 0);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// @notice utility contract which is ownable and pausable
contract OwnablePausable is Ownable, Pausable {
  
  constructor() {
  }

  /**
  * @dev enables owner to pause / unpause minting
  * @param _bPaused the flag to pause or unpause
  */
  function setPaused(bool _bPaused) public onlyOwner {
      if (_bPaused) _pause();
      else _unpause();
  }

}