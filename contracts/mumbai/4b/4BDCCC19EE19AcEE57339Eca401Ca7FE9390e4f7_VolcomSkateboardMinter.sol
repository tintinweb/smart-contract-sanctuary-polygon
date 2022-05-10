// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ExistingWTCContract{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function punchACard(string memory eventId, uint256 _tID, uint8 increment) external;
    function getNFTPunchesPerCard(string memory eventId, uint256 _tID) external view returns (uint256);
    function tokenExperience(uint tokenId) external view returns (uint);
} 

interface NewWTCContract{
    function mint(address _to, uint256 _eID, string memory _Uri) external ;
    function mint(address _to, uint256 _eID) external ;
}

contract VolcomSkateboardMinter is Ownable{

    ExistingWTCContract public whitelistedContract;
    NewWTCContract public dropContract;
    //uint public maxMints;
    string public eventId;
    mapping(uint => uint) private mints;
    mapping(address => bool) public whitelist;
    uint public price;
    uint private contractBalance;
    bool public whitelistMintActive;
    bool public regularMintActive;
    mapping(uint => uint) public distribution;
    //uint public maxDistribution;
    
    event SecurityWithdrawal(uint amount);
    event Withdrawal(address indexed _to, uint _value);

    // modifier earlyMint (){
    //     require( whitelistMintActive, "Minting through whitelist disabled");
    //     _;
    // }

    // modifier regularMint (){
    //     require( regularMintActive, "Minting disabled");
    //     _;
    // }

    constructor(string memory _eventId, 
                address _whitelistedContract, 
                address _dropContract, 
                address[] memory _whitelist,
                uint _price
                //uint _maxDistribution
                ){

        whitelistedContract = ExistingWTCContract(_whitelistedContract);
        dropContract = NewWTCContract(_dropContract);
        eventId = _eventId;
        price = _price;
        //maxDistribution = _maxDistribution;
        for( uint i=0; i < _whitelist.length; i++ ){
            whitelist[_whitelist[i]]=true;
        }
    }

    // function setMaxDistribution(uint _maxDistribution) external onlyOwner {
    //     maxDistribution = _maxDistribution;
    // }

    function maxDistribution() public view returns (uint) {
        uint8 i = 1;
        uint maxDistribution = 0;
        while( distribution[i] != 0){
            maxDistribution += distribution[i];
            i++;
        }
        return maxDistribution;
    }

    function setDistributionRule(uint _eID, uint amount) external onlyOwner {
        distribution[_eID] = amount;
    }

    function getDistributionRule(uint _eID) public view returns (uint){
        return distribution[_eID];
    }

    function addWhitelistedAddress(address newAddress) external onlyOwner {
        whitelist[newAddress]=true;
    }

    function removeWhitelistedAddress(address oldAddress) external onlyOwner {
        whitelist[oldAddress]=false;
    }

    function setPrice(uint _price) external onlyOwner{
        price = _price;
    }

    function activeWhitelistMint(bool active) external onlyOwner{
        whitelistMintActive = active;
    }

    function activeRegularMint(bool active) external onlyOwner{
        regularMintActive = active;
    }

    function setWhitelistedContract(address _whitelistedContract) external onlyOwner {
        whitelistedContract = ExistingWTCContract(_whitelistedContract);
    }

    function setDropContract(address _dropContract) external onlyOwner {
        dropContract = NewWTCContract(_dropContract);
    }

    function setEventId(string memory _eventId) external onlyOwner {
        eventId = _eventId;
    }

    function getRandomEID() internal view returns (uint){
        uint x = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _msgSender())));
        uint random_n = x % maxDistribution();
        uint rangeStartAt;
        uint i = 1;
        while (distribution[i] != 0){
            if (rangeStartAt <= random_n && (distribution[i] + rangeStartAt) > random_n ){
                uint j = i;
                bool fullCycle;
                while (mints[j] >= distribution[j]){
                    if (distribution[j] == 0 && !fullCycle){
                        j = 1;
                        fullCycle = true;
                    }else if (distribution[j] == 0 && fullCycle){
                        revert("Distribution reached its max capacity.");
                    }
                    else{
                        j++;
                    }
                }
                return j;
            }
            rangeStartAt += distribution[i];
            i++;
        }
    }

    // function mintVIP(uint _tokenIdToPunch) external earlyMint {
    //     require(whitelistedContract.ownerOf(_tokenIdToPunch) == _msgSender(), "You dont own this NFT");
    //     uint whitelistEID = whitelistedContract.tokenExperience(_tokenIdToPunch);
    //     require( whitelistEID == 2, "Not a VIP Metaboard holder");
    //     whitelistedContract.punchACard(eventId, _tokenIdToPunch,  1);
    //     _mint();
    // }

    // function mintWhitelist() external payable earlyMint {
    //     require(whitelist[_msgSender()] , "This address is not in the whitelist");
    //     whitelist[_msgSender()] = false;
    //     require( msg.value >= price, "Not enough Matic");
    //     contractBalance += msg.value;
    //     _mint();
    // }

    function mint() external payable {
        require( msg.value >= price, "Not enough Matic");
        contractBalance += msg.value;
        if (whitelistMintActive && !regularMintActive){
            require(whitelist[_msgSender()] , "This address is not in the whitelist");
        }else if (!whitelistMintActive && !regularMintActive){
            revert("Minting is not enabled");
        }
        uint _eID = getRandomEID();
        mints[_eID]++;
        dropContract.mint( _msgSender(),  _eID);
    }

    // function _mint() internal {
    //     uint _eID = getRandomEID();
    //     mints[_eID]++;
    //     dropContract.mint( _msgSender(),  _eID);
    // }

    function checkBalance() internal returns (bool){
        if (contractBalance != address(this).balance){
            payable(owner()).transfer(address(this).balance);
            emit SecurityWithdrawal(address(this).balance);
            return false;
        }
        else{
            return true;
        }
    }

    /********************************************************************
    * @dev collects the funds stored in this contratc to send it to 
    * a safe address.
    * @param amount to take out from the contract to send to 
    * the collector or safe address.
    * @param to the address of the collector.
    ********************************************************************/
    function withdrawFromContract(uint amount, address payable to) external payable onlyOwner {
        require(amount <= address(this).balance, "Not enough balance");
        if (checkBalance()){
            contractBalance -= amount;
            to.transfer(amount);
            emit Withdrawal(to, amount);
        } 
    }

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