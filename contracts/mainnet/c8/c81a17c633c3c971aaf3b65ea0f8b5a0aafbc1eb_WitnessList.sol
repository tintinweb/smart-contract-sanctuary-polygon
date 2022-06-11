/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

pragma solidity <6.0 >=0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract UniqueAppendOnlyAddressList is Ownable {
    struct ExistAndActive {
        bool exist;
        bool active;
    }
    uint256 internal num;
    address[] internal items;
    mapping(address => ExistAndActive) internal existAndActives;

    function count() public view returns (uint256) {
        return items.length;
    }

    function numOfActive() public view returns (uint256) {
        return num;
    }

    function isExist(address _item) public view returns (bool) {
        return existAndActives[_item].exist;
    }

    function isActive(address _item) public view returns (bool) {
        return existAndActives[_item].active;
    }

    function activateItem(address _item) internal returns (bool) {
        if (existAndActives[_item].active) {
            return false;
        }
        if (!existAndActives[_item].exist) {
            items.push(_item);
        }
        num++;
        existAndActives[_item] = ExistAndActive(true, true);
        return true;
    }

    function deactivateItem(address _item) internal returns (bool) {
        if (existAndActives[_item].exist && existAndActives[_item].active) {
            num--;
            existAndActives[_item].active = false;
            return true;
        }
        return false;
    }

    function getActiveItems(uint256 offset, uint8 limit) public view returns (uint256 count_, address[] memory items_) {
        require(offset < items.length && limit != 0);
        items_ = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (offset + i >= items.length) {
                break;
            }
            if (existAndActives[items[offset + i]].active) {
                items_[count_] = items[offset + i];
                count_++;
            }
        }
    }
}

contract WitnessList is Ownable, UniqueAppendOnlyAddressList {
    event WitnessAdded(address indexed witness);
    event WitnessRemoved(address indexed witness);

    function isAllowed(address _witness) public view returns (bool) {
        return isActive(_witness);
    }

    function addWitness(address _witness) public onlyOwner returns (bool success_) {
        if (activateItem(_witness)) {
            emit WitnessAdded(_witness);
            success_ = true;
        }
    }

    function removeWitness(address _witness) public onlyOwner returns (bool success_) {
        if (deactivateItem(_witness)) {
            emit WitnessRemoved(_witness);
            success_ = true;
        }
    }

}