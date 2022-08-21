// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury Contract that will have all the donation funds locked and governed
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
**/

contract Treasury is Ownable {
uint public proposalId;
uint public totalDonationAmt;
uint public releasedAmt;
mapping (address => uint) public institutionAmount;
mapping (uint => bool) public idPayment;
mapping (uint => string) public idName;   // This will be used in SVG minting

event FundsReleased(uint ProposalID, address To, uint Amount);
event Received(address, uint);

/**
  @notice Below function is goverened by the timelock
**/
  function releaseFunds(address payable _to, string calldata _name,uint _amount) public onlyOwner {
    require(address(this).balance >= _amount, "Not enough funds");
    //require(idPayment[_proposalId]==false, "Payment already processed");
    //idPayment[_proposalId]=true;
    //proposalId.push(_proposalId);
    ++proposalId;
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send donation");
    institutionAmount[_to] += _amount;
    idName[proposalId] = _name;
    releasedAmt += _amount;
    emit FundsReleased(proposalId, _to, _amount);
  }

  function getIdInfo(uint _proposalId) public view returns(string memory _name){
      return idName[_proposalId];
  }

  function contractBalance() public view returns(uint) {
          return address(this).balance;
    }

receive() external payable {
        totalDonationAmt +=msg.value;
		emit Received(msg.sender, msg.value);
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