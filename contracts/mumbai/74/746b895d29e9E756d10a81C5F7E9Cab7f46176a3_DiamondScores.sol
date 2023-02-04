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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC1155 {
    function balanceOf(address owner, uint256 id) external view returns (uint);
}

contract DiamondScores is Ownable 
{
    mapping(address => string) private addressToNicknames;
    mapping(string => address) private nicknameToAddress;
    mapping(address => string) private scores;

    address[] private usersAddress;

    address public wolf2dContractAddress;

    
    event ScoreAdded(address player, string encryptedScore, string nickname);
    event NicknameAdded(address player, string nickname);


    function addNickname(string memory _nickname) public 
    {
        require(bytes(_nickname).length > 0,"Nickname is empty!");
        require(nicknameToAddress[_nickname] == address(0),"Nickname Already Exists!");
        require(bytes(_nickname).length >= 3 && bytes(_nickname).length <= 25,"Nickname is between 3-25 characters");
        require(bytes(addressToNicknames[msg.sender]).length <= 0,"You aready have a Nickname!");
        addressToNicknames[msg.sender] = _nickname;
        nicknameToAddress[_nickname] = msg.sender;
        emit NicknameAdded(msg.sender, _nickname);
    }

     function addScore(string memory _encryptedScore) public
    {
        if(bytes(scores[msg.sender]).length <= 0){
            usersAddress.push(msg.sender);
        }
        scores[msg.sender] = _encryptedScore;
        emit ScoreAdded(msg.sender, _encryptedScore, addressToNicknames[msg.sender]);
    }

     function getAllScores() public view returns (string[] memory) {
        string[] memory allScores = new string[](usersAddress.length);
        for (uint i = 0; i < usersAddress.length; i++) {
            allScores[i] = scores[usersAddress[i]];
        }
        return allScores;
    }

         function getAllUsernames() public view returns (string[] memory) {
        string[] memory allusernames = new string[](usersAddress.length);
        for (uint i = 0; i < usersAddress.length; i++) {
            allusernames[i] = addressToNicknames[usersAddress[i]];
        }
        return allusernames;
    }

    function getAllUsers() public view returns (address[] memory) {
        return usersAddress;
    }

    function getNicknameByAddress(address _player) public view returns (string memory) {
        return addressToNicknames[_player];
    }

        function getAddressByNickname(string memory nickname) public view returns (address) {
    return nicknameToAddress[nickname];
    }


    function getScore(address _player) public view returns (string memory) {
        return scores[_player];
    }

    function hasNFT( uint256 _tokenId, address user) public view returns (bool) {
    // Get a reference to the NFT contract
    ERC1155 nftContract = ERC1155(wolf2dContractAddress);

    // Get the balance of the NFT for the user
    uint balance = nftContract.balanceOf(user, _tokenId);

    // Return true if the balance is greater than zero, false otherwise
    return balance > 0;
    }

    //Administrator Functions
    function setnftContractAddress(address address2dWolf) public onlyOwner {
        wolf2dContractAddress = address2dWolf;
    }
}