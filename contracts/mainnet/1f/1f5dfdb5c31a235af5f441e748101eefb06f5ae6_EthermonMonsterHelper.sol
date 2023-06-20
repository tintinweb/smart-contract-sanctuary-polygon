/**
 *Submitted for verification at polygonscan.com on 2023-06-20
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

// File: contracts/EthermonHelper.sol


pragma solidity ^0.8.9;



interface EthermonMonsterInterface{
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns(uint256);
    function getMonsterBaseStats(uint64 _monsterId) external view returns(uint256,uint256,uint256,uint256,uint256,uint256);
    function getMonsterCurrentStats(uint64 _monsterId) external view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface EthermonDataInterface{
    function monsterWorld(uint64 _monId) external view returns(uint64, uint32, address, string memory, uint32, uint32, uint32, uint256);
}


contract EthermonMonsterHelper is Ownable {
    address public EthermonMonster = 0x90E65700C6Fd8D054c0f5a4Fe8CDAa7914fe1DBA;
    
    address public EthermonMonsterData = 0x69950B70358820E324215A1d323075CC4770d808;

    
    function setMonsterContract(address addr)
        public
        onlyOwner
        {
            EthermonMonster = addr;
        }

    function setMonsterDataContract(address addr)
        public
        onlyOwner
        {
            EthermonMonster = addr;
        }

    
    function getMonsterData(uint64 _monId)
        public
        view
        returns(uint64 monId, uint32 classId, address trainer, string memory name, uint256[] memory baseStats)
        {
            EthermonDataInterface EthermonDataContract = EthermonDataInterface(EthermonMonsterData);
            (monId, classId, trainer, name,,,,) = EthermonDataContract.monsterWorld(_monId);
            baseStats = getBaseStatsArray(monId);
            return (monId, classId, trainer, name, baseStats);
        }

    function monsterWorldTokenOfOwnerByIndex(address addr, uint256 index)
        public
        view
        returns(uint64 monId, uint32 classId, address trainer, string memory name, uint256[] memory baseStats)
        {
            EthermonMonsterInterface EthermonMonsterContract = EthermonMonsterInterface(EthermonMonster);
            uint256 resp = EthermonMonsterContract.tokenOfOwnerByIndex(addr, index);
            (monId, classId, trainer, name, baseStats) = getMonsterData(uint64(resp));
            return (monId, classId, trainer, name, baseStats);
        }
    
    function getBaseStatsArray(uint64 monId)
        private
        view
        returns (uint256[] memory)
        {
            EthermonMonsterInterface EthermonMonsterContract = EthermonMonsterInterface(EthermonMonster);
            (uint256 hp,uint256 pa,uint256 pd,uint256 sa,uint256 sd,uint256 se) = EthermonMonsterContract.getMonsterBaseStats(monId);
            uint256[] memory baseStats = new uint256[](6);
            baseStats[0] = hp;
            baseStats[1] = pa;
            baseStats[2] = pd;
            baseStats[3] = sa;
            baseStats[4] = sd;
            baseStats[5] = se;
            return baseStats;
        }   
}