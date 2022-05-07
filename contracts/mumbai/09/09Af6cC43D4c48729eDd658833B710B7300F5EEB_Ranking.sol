/**
 *Submitted for verification at polygonscan.com on 2022-05-06
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

// File: contracts/Rank.sol

pragma solidity ^0.8.0;


abstract contract IRanking{

}

//Nethny was here
contract Ranking is Ownable{

    struct Rank{
        string Name;
        string[] pNames;
        uint32[] pValues;
        bool isChangeable;
    }

    //0 - дефолтный ранг всех пользователей
    Rank[] private _ranks;
    mapping(address => uint256) _rankTable;

    /*TEST ==================
    "First", ["1 param", "2 param", "3 param", "4 param"],  [1,2,3,4], True
    "Second", ["1 param", "2 param", "3 param", "4 param"],  [4,3,2,1], True
    //TEST ==================*/

    function giveRank(address[] memory users, string memory rank) public onlyOwner returns(bool){
        uint256 index = searchRank(rank);

        for(uint256 i = 0; i < users.length; i++){
            _rankTable[users[i]] = index;
        }

        return true;
    }

    function giveRank(address user, string memory rank) public onlyOwner returns(bool){
        uint256 index = searchRank(rank);
        
        _rankTable[user] = index;

        return true;
    }


    //Only Rank Functions ====================================================================================================================
    function createRank(string memory Name, string[] memory pNames, uint32[] memory pValues, bool isChangeable) public onlyOwner returns(bool){
        require(pNames.length == pValues.length, "RANK: Each parameter must have a value!");

        Rank memory rank = Rank(Name, pNames, pValues, isChangeable);
        _ranks.push(rank);
        return true;
    }

    //Change Rank ======================================
    function changeRank(string memory Name, string[] memory pNames, uint32[] memory pValues, bool isChangeable) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");
        require(pNames.length == pValues.length, "RANK: Each parameter must have a value!");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");

        _ranks[index] = Rank(Name, pNames, pValues, isChangeable);
        return true;
    }

    //Names
    function changeRank(string memory Name, string[] memory pNames) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");
        require(pNames.length == _ranks[index].pNames.length, "RANK: Each parameter must have a value!");

        _ranks[index].pNames = pNames;
        return true;
    }

    //Values
    function changeRank(string memory Name, uint32[] memory pValues) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");
        require(pValues.length == _ranks[index].pValues.length, "RANK: Each parameter must have a value!");

        _ranks[index].pValues = pValues;
        return true;
    }

    function lockRank(string memory Name) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");

        _ranks[index].isChangeable = false;
        return true;
    }

    function renameRankParam(string memory Name, string memory NewParName, uint256 NumberPar) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");
        require(_ranks[index].pNames.length > NumberPar, "RANK: There is no such parameter!");
        
        _ranks[index].pNames[NumberPar] = NewParName;
        return true;
    }

    function changeRankParam(string memory Name, uint32 NewValue, uint256 NumberPar) public onlyOwner returns(bool){
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(_ranks[index].isChangeable, "RANK: This rank cannot be changed!");
        require(_ranks[index].pNames.length > NumberPar, "RANK: There is no such parameter!");
        
        _ranks[index].pValues[NumberPar] = NewValue;
        return true;
    }

    //Inside ======================================
    function searchRank(string memory Name) internal view returns(uint256){
        for (uint i = 0; i < _ranks.length; i++){
            if(keccak256(abi.encode(_ranks[i].Name)) == keccak256(abi.encode(Name))){
                return i;
            }
        }
        revert("RANK: Rank not found!");
    }

    //View ======================================
    function showRanks() public view onlyOwner returns(Rank[] memory){
        require(_ranks.length > 0, "RANK: There are no ranks.");
        return _ranks;
    }

    function showRank(string memory Name) public view onlyOwner returns(string memory , string[] memory, uint32[] memory, bool){
        return (_ranks[searchRank(Name)].Name, _ranks[searchRank(Name)].pNames, _ranks[searchRank(Name)].pValues, _ranks[searchRank(Name)].isChangeable);
    }

    function showRank(uint256 Number) public view onlyOwner returns(string memory , string[] memory, uint32[] memory, bool){
        require(_ranks.length > Number, "RANK: There are no ranks.");
        return (_ranks[Number].Name, _ranks[Number].pNames, _ranks[Number].pValues, _ranks[Number].isChangeable);
    }

    function getRank(address user) public view returns(string memory , string[] memory, uint32[] memory, bool){
        return (_ranks[_rankTable[user]].Name, _ranks[_rankTable[user]].pNames, _ranks[_rankTable[user]].pValues, _ranks[_rankTable[user]].isChangeable);
    }

    function getNameParRank(string memory Name) public view returns(string[] memory){
        return _ranks[searchRank(Name)].pNames;
    }

    function getParRank(string memory Name) public view returns(uint32[] memory){
        return _ranks[searchRank(Name)].pValues;
    }
    
}