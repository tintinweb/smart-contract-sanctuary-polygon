/**
 *Submitted for verification at polygonscan.com on 2022-07-11
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

// File: contracts/SoccerTransfers.sol


pragma solidity >= 0.7.0 < 0.9.0;



interface GenericContractInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
}

contract SoccerTransfers is Ownable {

    struct playersOfCollectionInTransfers {
        address collectionAddress;
        string name;
        uint256 [] players;
    }

    mapping (address => mapping(uint256 => bool)) public playersInTransferCheck;
    mapping (address => uint256 []) public playersInTransferIds;

    mapping(address => bool) public approvedContracts;

    address [] public approvedContractsAddresses;


    function addToTransfer (uint256 _id) external {
        require(approvedContracts[msg.sender]);
        require(!playersInTransferCheck[msg.sender][_id]);

        playersInTransferCheck[msg.sender][_id] = true;

        playersInTransferIds[msg.sender].push(_id);
    }


    function removeFromTransfer(uint256 _id) external {
        require(approvedContracts[msg.sender]);
        require(playersInTransferCheck[msg.sender][_id]);
        playersInTransferCheck[msg.sender][_id] = false;

        for (uint256 i = 0; i < playersInTransferIds[msg.sender].length; i++) {
            if(playersInTransferIds[msg.sender][i] == _id){
                uint256 len = playersInTransferIds[msg.sender].length;
                playersInTransferIds[msg.sender][i] = playersInTransferIds[msg.sender][len - 1];
                playersInTransferIds[msg.sender].pop();
            }
        }
    }


    function beforeTransferInfo(uint256 _id) external view returns(bool) {
        require(approvedContracts[msg.sender]);
        return (playersInTransferCheck[msg.sender][_id]);
    }


    function getAllTransfersIds(address _collectionAddress) public view returns (uint256 [] memory) {
        return playersInTransferIds[_collectionAddress];
    }


    function getApprovedPlayersContracts () public view returns (address [] memory) {
        return approvedContractsAddresses;
    }

    //###################################

    // view functions
    function getPlayersInTransfer(address coach) public view returns (playersOfCollectionInTransfers [] memory) {
        playersOfCollectionInTransfers [] memory result = new playersOfCollectionInTransfers [](approvedContractsAddresses.length);
        uint256 countCollection = 0;

        for(uint256 i = 0; i < approvedContractsAddresses.length; i++){
            GenericContractInterface contractInstance = GenericContractInterface(approvedContractsAddresses[i]);

            uint256 [] memory playersId = new uint256[](contractInstance.balanceOf(coach));
            uint256 count = 0;

            for(uint256 j = 0; j < playersInTransferIds[approvedContractsAddresses[i]].length; j++) {
                uint256 player = playersInTransferIds[approvedContractsAddresses[i]][j];
                if(contractInstance.ownerOf(player) == coach) {
                    playersId[count] = player;
                    count += 1;
                }
            }
            
            result[countCollection] = playersOfCollectionInTransfers (approvedContractsAddresses[i], contractInstance.name(), playersId);
            countCollection += 1;
        }

        return result;

    }


    function getPlayersInTransfer(address _coach, address _collection) public view returns(uint256 [] memory) {
        uint256 [] memory ids = new uint256[](playersInTransferIds[_collection].length);
        uint256 count = 0;

        GenericContractInterface contractInstance = GenericContractInterface(_collection);

        for(uint256 i = 0; i < playersInTransferIds[_collection].length; i++) {
            if( contractInstance.ownerOf(playersInTransferIds[_collection][i]) != _coach ) {
                ids[count] = playersInTransferIds[_collection][i];
                count += 1;
            }
        }

        return ids;
    }


    //###################################

    // setting functions
    function approveContract(address _newAddress) public onlyOwner {
        approvedContracts[_newAddress] = true;
        approvedContractsAddresses.push(_newAddress);
    }


    function disapproveContract(address _oldAddress) public onlyOwner {
        approvedContracts[_oldAddress] = false;

        for (uint256 i = 0; i<approvedContractsAddresses.length; i++) {
            if(approvedContractsAddresses[i] == _oldAddress){
                approvedContractsAddresses[i] = approvedContractsAddresses[approvedContractsAddresses.length - 1];
                approvedContractsAddresses.pop();
            }
        }
    }
    // ###############################################
}