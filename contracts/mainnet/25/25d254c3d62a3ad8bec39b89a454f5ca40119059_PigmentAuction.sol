/**
 *Submitted for verification at polygonscan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.0;

// import "../utils/Context.sol";

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}




pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

interface iINKz {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function transfer(address to_, uint amount) external;
    function burn(address from_, uint amount) external;
}

contract PigmentAuction is Ownable {

    struct auctionDetails {
        // Params
        string name;
        string image;
        uint auctionStartTime;
        uint auctionEndTime;
        uint bidIncrement;
        uint bidTimeExtension;
        // State of auction
        address winner;
        address highestBidder;
        uint highestBid;
        uint spilled;
        bool ended;
    }

    mapping(uint256 => auctionDetails) auctions;
    uint256 public auctionCounter;
    bool internal locked; //for no re-entrancy

    
    event HighestBidIncrease(uint auction, address bidder, uint amount);
    event AuctionEnded(uint auction, address winner, uint amount);

    constructor(){
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    address public INKzAddress;
    iINKz public INKz;

    function createAuction(string memory _name, string memory _image, uint _auctionStartTime, uint _auctionEndTime, uint _bidIncrement, uint _bidTimeExtension, uint _startPrice) external onlyOwner {
        uint256 setAuction = auctionCounter + 1;
        require(auctions[setAuction].auctionStartTime == 0, "There is an active auction with this id");
        auctions[setAuction].name = _name;
        auctions[setAuction].image = _image;
        auctions[setAuction].auctionStartTime = _auctionStartTime;
        auctions[setAuction].auctionEndTime = _auctionEndTime;
        auctions[setAuction].bidIncrement = _bidIncrement;
        auctions[setAuction].bidTimeExtension = _bidTimeExtension;
        auctions[setAuction].highestBid = _startPrice;
        auctionCounter++;
    }

    function setINKz(address address_) external onlyOwner { 
        INKzAddress = address_;
        INKz = iINKz(address_);
    }

    function bid(uint256 _auctionId) public payable noReentrant{
        uint bidTotal = auctions[_auctionId].bidIncrement;
        require(INKz.balanceOf(msg.sender) >= bidTotal, "Sorry, you can't afford this bid");
        require(msg.sender != auctions[_auctionId].highestBidder, "You are already the highest bidder");
        
        if (block.timestamp > auctions[_auctionId].auctionEndTime){
            revert("The auction has ended");
        }

        INKz.burn(msg.sender, bidTotal);

        if (auctions[_auctionId].auctionEndTime - block.timestamp < auctions[_auctionId].bidTimeExtension){
            auctions[_auctionId].auctionEndTime = block.timestamp + auctions[_auctionId].bidTimeExtension;
        }

        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].highestBid = auctions[_auctionId].highestBid + (bidTotal / 100);
        auctions[_auctionId].spilled = auctions[_auctionId].spilled + auctions[_auctionId].bidIncrement;
        emit HighestBidIncrease(_auctionId, msg.sender, auctions[_auctionId].highestBid);
    }


    function withdrawTokens(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function auctionEnd(uint _auctionId) external noReentrant{
        if (block.timestamp < auctions[_auctionId].auctionEndTime){
            revert ("The auction is still running");
        }

        if (auctions[_auctionId].ended){
            revert("The function auctionEnd has already been called");
        }

        if (auctions[_auctionId].highestBidder != msg.sender){
            revert("You are not the winner");
        }

        require(INKz.balanceOf(msg.sender) >= auctions[_auctionId].highestBid, "You do not have enough inkz");
        INKz.burn(msg.sender, auctions[_auctionId].highestBid);

        auctions[_auctionId].ended = true;
        auctions[_auctionId].winner = auctions[_auctionId].highestBidder;
        auctions[_auctionId].spilled = auctions[_auctionId].spilled + auctions[_auctionId].highestBid;
        emit AuctionEnded(_auctionId, auctions[_auctionId].winner, auctions[_auctionId].highestBid);
    }

    // Setters in case there is a mistake in auction setup
    function setBidIncrement(uint _auctionId, uint _bidIncrement) external onlyOwner{
        auctions[_auctionId].bidIncrement = _bidIncrement;
    }

    function setBidTimeExtension(uint _auctionId, uint _bidTimeExtension) external onlyOwner{
        auctions[_auctionId].bidTimeExtension = _bidTimeExtension;
    }

    function setName(uint _auctionId, string memory _name) external onlyOwner{
        auctions[_auctionId].name = _name;
    }

    function setStartTime(uint _auctionId, uint _startTime) external onlyOwner{
        auctions[_auctionId].auctionStartTime = _startTime;
    }

    function setEndTime(uint _auctionId, uint _endTime) external onlyOwner{
        auctions[_auctionId].auctionEndTime = _endTime;
    }

    function setImage(uint _auctionId, string memory _imageUrl) external onlyOwner{
        auctions[_auctionId].image = _imageUrl;
    }

    function getAllAuctions() public view returns(auctionDetails[] memory){
        auctionDetails[] memory lAuctions = new auctionDetails[](auctionCounter);
        for (uint i = 0; i < auctionCounter; i++){
            auctionDetails storage lAuction = auctions[i + 1];
            lAuctions[i] = lAuction;
        }
        return lAuctions;
    }

    function getAuctionInfo(uint256 _auctionId) external view returns(string memory, string memory, uint, uint, uint, uint, address, uint, bool, address, uint){
        auctionDetails storage w = auctions[_auctionId];
        return (
            w.name,
            w.image,
            w.auctionStartTime,
            w.auctionEndTime,
            w.bidIncrement,
            w.bidTimeExtension,
            w.highestBidder,
            w.highestBid,
            w.ended,
            w.winner,
            w.spilled
        );
    }
}