/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/GlobalPassRoyalties.sol


pragma solidity ^0.8.0;
contract GlobalPassRoyalties {

    event RoyaltiesTransfer( uint, uint);
    struct royaltyInfo {
        address payable recipient;
        uint24 percentage;
    }
    mapping (address => uint) deposits;
    mapping(uint256 => royaltyInfo) _royalties;
    //mapping (address=>bool) GlobalPassWhiteList;
    // function _setTokenRoyalty(uint256 tokenId,address payable recipient,uint256 value) internal {
    //     require((value >= 0 && value < 100), "Royalties must be Between 0 and 99");
    //     _royalties[tokenId] = royaltyInfo(recipient, uint24(value));
    // }
    
    function _royaltyAndGlobalPassFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal  {
        
        require(msg.value==_NftPrice,"Not enough Amount provided"); 
        uint _TotalNftPrice = msg.value;                                // require(msg.value >= NftPrice[NftId], "Error! Insufficent Balance");
       // uint _GlobalPassFee = _calculateGlobalPassFee(_NftPrice, serviceFee);
        //_TotalNftPrice = _TotalNftPrice - _GlobalPassFee;     //Remaining Price After Deduction  
        uint _AdminFee = _calculateAndSendMinterFee(_TotalNftPrice , percentage,  minterAddress);
        _TotalNftPrice = _TotalNftPrice - _AdminFee;
        _transferAmountToSeller( _TotalNftPrice, NftSeller);            // Send Amount to NFT Seller after Tax deduction
        emit RoyaltiesTransfer(_AdminFee, _TotalNftPrice);
            }
    // function _calculateGlobalPassFee(uint Price, uint8 serviceFee) internal pure returns(uint) {
    //     require((Price/10000)*10000 == Price, "Error!Price Too small");
    //     return (Price*serviceFee)/1000;
    // }
    

    function _transferAmountToSeller(uint amount, address payable seller) internal {
        seller.transfer(amount);
    }

    function _calculateAndSendMinterFee(uint _NftPrice, uint Percentage, address payable minterAddr) internal returns(uint) {
        uint AmountToSend = (_NftPrice*Percentage)/100;           //Calculate Minter percentage and Send to his Address from Struct
        minterAddr.transfer(AmountToSend);                       // Send this Amount To Transfer Address from Contract balacne
        return AmountToSend;
    }
    // function depositAmount(address payee,uint amountToDeposit) internal {
    //     require(msg.value == amountToDeposit, "Error while Deposit");
    //     deposits[payee] += amountToDeposit;
    // }
    // function deductAmount(address from, uint amount) internal {
    //     require(deposits[from]>0, "0 Deposit");
    //     require(amount <= deposits[from] , "amountToDeposit > deposits[from]");
    //     deposits[from] -= amount;
    // }


}
// File: contracts/GlobalPassAuctions.sol


pragma solidity ^0.8.0;
// import "./GlobalPass.sol";
contract GlobalPassAuction {  //is SpaceERC20 
    event availableForAuction (uint, string) ;
    event removeFormSale (uint, string );
    enum saleTypeChoice {onAuction, onRent, OnfixedPrice, NotOnSale}
    saleTypeChoice public CurrentStatus;
    struct TicketDetails{
        uint [] numOfCopies;
        bool Exists;
        uint eventIDforTicket;
        saleTypeChoice salestatus;
        }

    struct ticketPackage {
        uint[] ticketIDs;
        uint[] bidAmount;
        uint[] numOfCopies;
        address[] bidderAddress;
        uint32 auctionStartTime;
        uint32 auctionEndTime;
        bool Exists;
         // Using minimumPrice == minimumBid  
        uint minimumPrice;
        uint index;
        saleTypeChoice salestatus;
        mapping(address => bool) hasBidden;
    }
     // TicketOwnerAddress to PackageId to PackageDetails (Struct) 
    mapping(address=>mapping(uint => ticketPackage)) ticketsPackage;
    
    // TicketOwnerAddress to ticketID to TicketDetails (Struct) 
    mapping(address => mapping(uint => TicketDetails)) Ticket;

    //mapping to store bids amount of each address
    mapping (address => uint) BidsAmount;
    modifier NftExist (address _owner, uint ticketID){
        require(Ticket[_owner][ticketID].Exists == true , "Not Owner of Ticket or NFT Does't Exist ");
        _;
    }

     modifier PackageExists (address _owner, uint packageID){
        require(ticketsPackage[_owner][packageID].Exists == true , "Not Owner of Package or Package Does't Exist ");
        _;
    }

    modifier notOnSale (address owner,uint packageID) {
        require(ticketsPackage[owner][packageID].salestatus == saleTypeChoice.NotOnSale, "Error! Ticket is Already on Sale");
        _;
    }

    modifier onFixedPrice (address owner, uint packageID){
        require( ticketsPackage[owner][packageID].salestatus == saleTypeChoice.OnfixedPrice, "Ticket is Not Available for Fixed Price");
        _;
    }
    modifier onAuction (address owner, uint packageID){
        require( ticketsPackage[owner][packageID].salestatus == saleTypeChoice.onAuction, "Ticket is Not Available for Auctions");
        _;
    }
//    


//     //Place NFT to Accept Bids
    function _placeNftForBids(address _owner, uint packageID ) notOnSale(_owner,packageID) NftExist(_owner , packageID) internal {
        CurrentStatus = saleTypeChoice(0);
        // AuctionDetails storage NftDetailobj = Nft[packageID];   I think it will create Storage Obj automatically,  Nft[packageID].salestatus  
        ticketsPackage[_owner][packageID].salestatus = CurrentStatus;
        emit availableForAuction (packageID, "Accepting Bids");
    }
    function _pushBidingValues (address nftOwnerAddress,address bidderAddress, uint packageID, uint _bidAmount, uint _numOfCopies) onAuction(nftOwnerAddress,packageID) internal{
        ticketsPackage[nftOwnerAddress][packageID].bidAmount.push(_bidAmount);
        ticketsPackage[nftOwnerAddress][packageID].bidderAddress.push(bidderAddress);
        ticketsPackage[nftOwnerAddress][packageID].numOfCopies.push(_numOfCopies);
    }
    function _placePackageForFixedPrice(address owner, uint packageID, uint16[] memory _ticketIDs , uint[] memory ticketCopiesCount, uint packageFixPrice) internal {
        CurrentStatus = saleTypeChoice(2);
        ticketsPackage[owner][packageID].ticketIDs = _ticketIDs;
        ticketsPackage[owner][packageID].salestatus = CurrentStatus;
        ticketsPackage[owner][packageID].numOfCopies = ticketCopiesCount;
        ticketsPackage[owner][packageID].minimumPrice = packageFixPrice;
        ticketsPackage[owner][packageID].Exists = true;
        
    }

    function _placePackageForTimedAuction( address owner, uint packageID, uint16[] memory _ticketIDs , uint[] memory ticketCopiesCount, uint32 _auctionStartTime, uint32 _auctionEndTime, uint packageMinPrice) internal {
        // start time should be near to Block.timestamp

        require (_auctionStartTime != _auctionEndTime && block.timestamp < _auctionEndTime , "Error! Time Error");
        CurrentStatus = saleTypeChoice(0);
        ticketsPackage[owner][packageID].ticketIDs = _ticketIDs;
        ticketsPackage[owner][packageID].salestatus = CurrentStatus;
        ticketsPackage[owner][packageID].auctionStartTime = _auctionStartTime;
        ticketsPackage[owner][packageID].numOfCopies = ticketCopiesCount;
        ticketsPackage[owner][packageID].auctionEndTime = _auctionEndTime;
        ticketsPackage[owner][packageID].minimumPrice = packageMinPrice;
        ticketsPackage[owner][packageID].Exists = true;
        
        emit availableForAuction (packageID, " Accepting Bids");
    }

     function _removeFromSale(address ownerAddress, uint packageID) NftExist(ownerAddress,packageID) internal {
        // check Already on Sale 
        CurrentStatus = saleTypeChoice(3);
        ticketsPackage[ownerAddress][packageID].salestatus = CurrentStatus;
        emit removeFormSale(packageID , "Error! NFT is removed from Sale ");
    }

    function _addAuctionBid(address owner, uint packageID, uint _bidAmount, uint noOfCopies) onAuction(owner, packageID) internal{
        // Check is time remaining to Bid
        require(block.timestamp <= ticketsPackage[owner][packageID].auctionEndTime, "Time is Overed");
        //address nftOwnerAddress,address bidderAddress, uint packageID, uint _bidAmount, uint _numOfCopies
        _pushBidingValues(owner,msg.sender, packageID, _bidAmount, noOfCopies);
        _updateBiddingMapping(msg.sender, _bidAmount);
       ticketsPackage[owner][packageID].hasBidden[msg.sender]=true;
        _getIndexOfHighestBid(owner,packageID);
    }

    function _getIndexOfHighestBid(address owner, uint packageID) internal returns (uint){
        uint temp = 0;
        for (uint i=0; i<ticketsPackage[owner][packageID].bidAmount.length; i++){
            if (temp<ticketsPackage[owner][packageID].bidAmount[i])
            {
                temp = ticketsPackage[owner][packageID].bidAmount[i];
                ticketsPackage[owner][packageID].index = i;
            }
        }
        return ticketsPackage[owner][packageID].index;
    }
    function _updateBiddingMapping(address _address , uint _biddingAmount) internal {
        BidsAmount[_address] += _biddingAmount;
        
    }
    function _releaseBiddingValue(address owner, uint packageID) internal {
        for (uint i=0; i<ticketsPackage[owner][packageID].bidderAddress.length; i++){
            BidsAmount[ticketsPackage[owner][packageID].bidderAddress[i]] -= ticketsPackage[owner][packageID].bidAmount[i];
        }
    }

     function _bidAccepted(address owner, uint packageID) internal {
        for(uint i=0;i<ticketsPackage[owner][packageID].bidAmount.length;i++)
            {
                ticketsPackage[owner][packageID].hasBidden[ticketsPackage[owner][packageID].bidderAddress[i]]=false;
            }
        delete ticketsPackage[owner][packageID].bidAmount;
        delete ticketsPackage[owner][packageID].bidderAddress;
    }
    function CheckSaleType(address nftOwner, uint packageID) view public returns(saleTypeChoice){
        return ticketsPackage[nftOwner][packageID].salestatus;
    }

}

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: contracts/GlobalPass.sol


pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;







contract GlobalPass is ERC1155, Ownable, Pausable, ERC1155Burnable, GlobalPassAuction,GlobalPassRoyalties, ReentrancyGuard {

    //enum ticketCategory {Administration, VIP, Public}

    struct TicketType
    {
        uint eventIDforTicket;
        string ticketName;
        uint ticketFixPrice;
        uint32[] validDates;
        uint totalCopies;
        string ticketURI;
        uint32 copiesSold;
        address royaltyReceiver;
        uint royaltyPercentage;
        uint servicePercentage;
        address firstMinter;
       saleTypeChoice ticketSaleType;
    }

    //[[1,"Ticket1",100000,9738178 ,7886858 ,100,"http://URI",0,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,2,5,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2], [1,"Ticket2",100000,9738178 ,7886858 ,100,"http://URI2",0,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,2,5,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2]]
    
    //1 ETH test for royalties
    //For an event scheduled from 8-15 november
    //_eventStartDate: 1667847600
    //_eventEndDate: 1668452400

    //Friday 11 nOvember
    //[[1,"Ticket1",1000000000000000000,[1668106800] ,100,"http://URI",0,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,2,5,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2]]
    
    // 13 & 14 November
    //[[1,"Ticket2",1000000000000000000,[1668279600,1668452400] ,100,"http://URI",0,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,10,10,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2]]
    struct Event
    {
        uint32 eventStartDate;
        uint32 eventEndDate;
        TicketType[] eventTickets;
        uint organiserId;
    }
    
    bool public contractStatus = false;
    uint public eventsCount;
    uint public ticketsCount;

    event EventRegistered(Event);
    event TicketCreated(TicketType, uint);
    
    //to check event details from ID
    mapping(uint => Event) eventDetails;

    //to check if a ticket exists
    mapping(uint => TicketType) ticketTypeDetails;
    
    //event is paused or not
    mapping(uint => bool) public eventIsPaused;

    //to check if event exists or not
    mapping(uint => bool) eventExists;

    //to check if a ticket already exists or not
    mapping(uint => bool) ticketExists;

    //Total Copies minted wrt a ticket
    mapping (uint => uint) totalCopiesMinted;
    

    //TicketIDs to their no of copies on bid w.r.t each address
   mapping(address=> mapping(uint => uint)) public CopiesOnBidOrSale;

    //Ticket Prices w.r.t each ticket holder
    mapping (address=>mapping(uint=>uint)) public tickets_Prices;
    mapping (uint=>string) tokenURI;

    //User Balances in Contract
    mapping(address => uint) public user_Balance;
    event URI(string value, bytes indexed id);

    //To check all tickets of an event
    mapping(uint => uint[]) eventticketTypeDetails;

    // mapping of eventID => TicketID => holderAddress => true/false;
    mapping(uint => mapping (uint =>mapping (address => bool))) isEventTicketHolder;

    //To check if even already exists or not
    modifier eventIsRegistered(uint _eventID){
        require(eventExists[_eventID] == true, "Event Does not exist");
        _;
    }

    modifier eventIsNotPaused(uint _eventID){
        require(eventIsPaused[_eventID] == false, "Event is Paused");
        _;
    }

    //To check if even already exists or not
    modifier TicketExists(uint packageID){
        require(ticketExists[packageID] == true, "Ticket Does not exist");
        _;
    }
    function setURI(uint _id, string memory _uri) private  {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }
    constructor( ) ERC1155("") {
        pause();
        eventsCount = 0;
        ticketsCount = 0;
        
    }

    function name() public pure returns(string memory){
    return "Rush49 GlobalPass";
   }

    function symbol() public pure returns(string memory){
        return "R49GP";
    }

    function isAdmin() public view returns (bool){
            if(_msgSender()==owner()) return true;
            else return false;
        }

    function changeEventState(uint _eventID, bool state) external onlyOwner {
            eventIsPaused[_eventID] = state;
    }
    
    //Only Admin can register events
    // tickets will be created on time of event registration
     function registerEvent(
        uint32 _eventStartDate,
        uint32 _eventEndDate,
        uint16 ticketTypesCount,
        TicketType[] memory _TicketTypes,
        // uint32[] memory _auctionStartTimes,
        // uint32[] memory _auctionEndTimes,
        uint _organiserId) external whenNotPaused onlyOwner  {
        eventsCount++;
        uint _eventID = eventsCount;
        //Event-ID cannot be duplicated
        require(eventExists[_eventID] == false, "Event with same ID Already Registered");
         eventDetails[_eventID].eventStartDate = _eventStartDate;
         eventDetails[_eventID].eventEndDate = _eventEndDate + 24 hours;
        eventExists[_eventID] = true;
        eventIsPaused[_eventID] = false;
        eventDetails[_eventID].organiserId = _organiserId;

        
        addTicketType( ticketTypesCount, _eventID, _TicketTypes /*_auctionStartTimes, _auctionEndTimes */) ;
         
         emit EventRegistered(eventDetails[_eventID]);
    }

        //Only Admin can Update events
     function updateEvent(uint _eventID,
        uint32 _eventStartDate,
        uint32 _eventEndDate,
        uint _organiserId) external whenNotPaused onlyOwner eventIsRegistered(_eventID)  {

         eventDetails[_eventID].eventStartDate = _eventStartDate;
         eventDetails[_eventID].eventEndDate = _eventEndDate;
         eventDetails[_eventID].organiserId = _organiserId;
    }

    //Delete Event 
    function deleteEvent(uint _eventID) external onlyOwner eventIsRegistered(_eventID) whenNotPaused{
        eventExists[_eventID] = false;
        delete eventDetails[_eventID];
    }

    //Get Event Details
    function getEventDetails(uint _eventID) public view  whenNotPaused eventIsRegistered(_eventID)  returns 
    (
    TicketType[] memory eventTickets,
    uint eventStartDate, 
    uint eventEndDate) {
        return (
            eventDetails[_eventID].eventTickets,
            eventDetails[_eventID].eventStartDate,
            eventDetails[_eventID].eventEndDate
            // eventticketCategorys[_eventID]
        );
    }

        function scanTickets(uint ticketID) public view TicketExists(ticketID) returns(bool){
            require(balanceOf(_msgSender(),ticketID)>0, "You dont have this ticket");
            bool response;
            for(uint8 i=0; i < ticketTypeDetails[ticketID].validDates.length ; i++){
            if(block.timestamp >= ticketTypeDetails[ticketID].validDates[i] && block.timestamp <= (ticketTypeDetails[ticketID].validDates[i]+ 86399))
                 response = true;
            else
                response = false;
        }
        return response;
            // [[1,"Ticket2",1000000000000000000,[1668193200] ,100,"http://URI",0,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,10,10,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2]]
           
        }

        //Add new ticket type for an event
       function addTicketType(
        uint16 ticketTypesCount,
        uint eventID,
        TicketType[] memory _ticketTypes
    ) public whenNotPaused onlyOwner  eventIsRegistered(eventsCount) {
        for(uint8 i=0; i < ticketTypesCount ; i++)
         {
             ticketsCount++;
            require(ticketExists[ticketsCount] == false, "Ticket with same ID Already Exists");
            require(eventDetails[eventID].eventStartDate <= _ticketTypes[i].validDates[i] && eventDetails[eventID].eventEndDate >= _ticketTypes[i].validDates[i], "Validity dates must be withing Event Dates");            
            //require(noOfTickets[_eventID][_category] == _noOfTickets, "Incorrect no of Copies");            
            ticketTypeDetails[ticketsCount].eventIDforTicket = eventID;


            ticketTypeDetails[ticketsCount].ticketName = _ticketTypes[i].ticketName;
            ticketTypeDetails[ticketsCount].ticketFixPrice = _ticketTypes[i].ticketFixPrice;
            //ticketTypeDetails[packageIDs[i]].ticketSaleType = _ticketTypes[i].ticketSaleType;
            ticketTypeDetails[ticketsCount].totalCopies = _ticketTypes[i].totalCopies;
            ticketTypeDetails[ticketsCount].ticketURI = _ticketTypes[i].ticketURI;
            
           // for(uint j = 0; j<ticketTypeDetails[ticketsCount].validDates.length; j++)
                ticketTypeDetails[ticketsCount].validDates = _ticketTypes[i].validDates;
            
            ticketTypeDetails[ticketsCount].royaltyReceiver = owner();
            ticketTypeDetails[ticketsCount].royaltyPercentage = _ticketTypes[i].royaltyPercentage;
            ticketTypeDetails[ticketsCount].servicePercentage = _ticketTypes[i].servicePercentage;
             ticketTypeDetails[ticketsCount].firstMinter = owner();
            eventticketTypeDetails[eventsCount].push(ticketsCount);
           // ticketsPackage[_msgSender()][ticketIDs[i]].Exists = true;

            // if(_ticketTypes[i].ticketSaleType == saleTypeChoice.OnfixedPrice)
                placeTicketForFixedPrice(owner() , ticketsCount,  _ticketTypes[i].ticketFixPrice );
            // else if(_ticketTypes[i].ticketSaleType == saleTypeChoice.onAuction)
            // _putNftForTimedAuction(owner(), packageIDs[i] , _auctionStartTimes[i], _auctionEndTimes[i], _ticketTypes[i].ticketFixPrice);
            eventDetails[eventsCount].eventTickets.push(ticketTypeDetails[ticketsCount]);
            setURI( ticketsCount,_ticketTypes[i].ticketURI);
            ticketExists[ticketsCount] = true;
            emit TicketCreated(ticketTypeDetails[ticketsCount], ticketsCount);
         }
    }

    //To add no of copies of a ticket type of an event
    function updateTicketCount(
        uint _eventID,
        uint[] memory ticketIDs,
        uint[] memory _newTicketsCount
    ) external whenNotPaused onlyOwner eventIsRegistered(_eventID){

        for(uint i = 0; i < ticketIDs.length; i++){
            require(ticketExists[ticketIDs[i]] == true, "Ticket Does not Exist");
            ticketTypeDetails[ticketIDs[i]].totalCopies = _newTicketsCount[i];
        }
    }

    //get all details of a ticket
    // function getticketTypeDetails(address owner, uint ticketID) public view returns(
    //     ticketTypeDetails memory Ticket
    //     ){
    //         return Ticket[owner][ticketID];
    // }

    function mintTicketsWithFixPrice(address account, uint ticketID, uint32 noOfCopies) public payable eventIsNotPaused(ticketTypeDetails[ticketID].eventIDforTicket) {
        require((ticketTypeDetails[ticketID].copiesSold + noOfCopies) < ticketTypeDetails[ticketID].totalCopies, "Not enough Copies available");
        require(msg.value == (ticketTypeDetails[ticketID].ticketFixPrice)*noOfCopies, "Not enough amount provided");
        // require() 
        user_Balance[owner()] += msg.value;
        mint(account, ticketID, noOfCopies, "");
        totalCopiesMinted[ticketID]+=noOfCopies;
        CurrentStatus = saleTypeChoice(3);
        Ticket[account][ticketID].salestatus = CurrentStatus;
        Ticket[account][ticketID].Exists = true;
        setApprovalForAll(address(this),true);
      //  Ticket[account][ticketID].eventIDforTicket = ticketTypeDetails[ticketID].
    }

    //Secondary Sales for Auction & Fix Price
    // function placePackageForTimedAuction(uint _eventID,address owner, uint packageID, uint16[] memory _ticketIDs , uint[] memory ticketCopiesCount, uint32 _auctionStartTime, uint32 _auctionEndTime, uint packageMinPrice) external {
    //     for(uint i = 0; i<_ticketIDs.length; i++)
    //    {
    //       // require(Ticket[owner][_ticketIDs[i]].Exists && (balanceOf(_msgSender(), _ticketIDs[i]) - CopiesOnBidOrSale[_msgSender()][_ticketIDs[i]]) <= ticketCopiesCount[i] &&   _eventID ==  ticketTypeDetails[_ticketIDs[i]].eventIDforTicket, "Error: Cannot Place package for Fixed Price");
    //       require(Ticket[owner][_ticketIDs[i]].Exists, "Ticket not exist"); 
    //       require((balanceOf(_msgSender(), _ticketIDs[i]) - CopiesOnBidOrSale[_msgSender()][_ticketIDs[i]]) >= ticketCopiesCount[i], "Balance Problem");
    //       require(_eventID ==  ticketTypeDetails[_ticketIDs[i]].eventIDforTicket, "Event ID Problem");
    //        CopiesOnBidOrSale[owner][_ticketIDs[i]] += ticketCopiesCount[i];
    //    }
       
    //     _placePackageForTimedAuction(_msgSender(),packageID, _ticketIDs , ticketCopiesCount, _auctionStartTime, _auctionEndTime, packageMinPrice);
    // }

    function placePackageForFixedPrice(uint _eventID, address owner, uint packageID, uint16[] memory _ticketIDs , uint[] memory ticketCopiesCount, uint packageFixPrice) external {
        for(uint i = 0; i<_ticketIDs.length; i++)
       {
          // require(Ticket[owner][_ticketIDs[i]].Exists && (balanceOf(_msgSender(), _ticketIDs[i]) - CopiesOnBidOrSale[_msgSender()][_ticketIDs[i]]) <= ticketCopiesCount[i] &&   _eventID ==  ticketTypeDetails[_ticketIDs[i]].eventIDforTicket, "Error: Cannot Place package for Fixed Price");
          require(Ticket[owner][_ticketIDs[i]].Exists, "Ticket not exist"); 
          require((balanceOf(_msgSender(), _ticketIDs[i]) - CopiesOnBidOrSale[_msgSender()][_ticketIDs[i]]) >= ticketCopiesCount[i], "Balance Problem");
          require(_eventID ==  ticketTypeDetails[_ticketIDs[i]].eventIDforTicket, "Event ID Problem");
           CopiesOnBidOrSale[owner][_ticketIDs[i]] += ticketCopiesCount[i];
       }
       _placePackageForFixedPrice( owner,  packageID,  _ticketIDs , ticketCopiesCount, packageFixPrice);

    }

    // I Think we dont need this function
    // function getPackageDetails (address owner, uint packageID) public view returns (ticketPackage memory Package){
    //     return ticketsPackage[owner][packageID];
    // }

    //  function addAuctionBid(address owner, uint packageID, uint _bidAmount) public payable  PackageExists(owner,packageID) {
    //     if(ticketsPackage[owner][packageID].bidAmount.length != 0)
    //         require(_bidAmount >= (ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index] + (ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index]*10)/100), "Bid Amount Must be greater than 10% of current Highest Bid");
    //     if (user_Balance[_msgSender()] < _bidAmount){
    //         _getBidBalance(payable(_msgSender()), _bidAmount);
    //     }
    //     require( _bidAmount >= ticketsPackage[owner][packageID].minimumPrice && _bidAmount <= user_Balance[_msgSender()], "Error! Insufficient Balance or Low Biding Amount");
    //     _addAuctionBid(owner, packageID,_bidAmount, balanceOf(owner, packageID));
    // }
    // HighestBidder Address:      ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index]
    // HighestBidder Index:        ticketsPackage[owner][packageID].index
    // HighestBidder Bid Amount:   ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index]
    //Only Owner of Tickets can accept bids

    //Only admin can place tickets for fix price while creating tickets
    function placeTicketForFixedPrice(address owner, uint ticketID,  uint _ticketFixPrice) internal  onlyOwner {
        tickets_Prices[owner][ticketID] = _ticketFixPrice;
        CurrentStatus = saleTypeChoice(2);
        ticketTypeDetails[ticketID].ticketSaleType = CurrentStatus;
        ticketTypeDetails[ticketID].ticketFixPrice = _ticketFixPrice;
        
    }
    function buyPackageForFixedPrice( address from, address to, uint packageID, uint _eventID) external payable  PackageExists(from,packageID) {

        require (msg.value == ticketsPackage[from][packageID].minimumPrice, "Not Enough amount Provided");
        CurrentStatus = saleTypeChoice(3);
        uint percentage = 0;
         for(uint i = 0; i<ticketsPackage[from][packageID].ticketIDs.length; i++)
        {
            
            require((balanceOf(from, ticketsPackage[from][packageID].ticketIDs[i]) >= CopiesOnBidOrSale[from][ticketsPackage[from][packageID].ticketIDs[i]]) &&   (_eventID ==  ticketTypeDetails[ticketsPackage[from][packageID].ticketIDs[i]].eventIDforTicket), "Error: Cannot Purchase package for Fixed Price");
            CopiesOnBidOrSale[from][ticketsPackage[from][packageID].ticketIDs[i]] -= ticketsPackage[from][packageID].numOfCopies[i];
            ticketsPackage[from][packageID].Exists = false;
            Ticket[to][ticketsPackage[from][packageID].ticketIDs[i]].Exists = true;
            percentage += ticketTypeDetails[ticketsPackage[from][packageID].ticketIDs[i]].royaltyPercentage + ticketTypeDetails[ticketsPackage[from][packageID].ticketIDs[i]].servicePercentage;
            Ticket[to][ticketsPackage[from][packageID].ticketIDs[i]].salestatus = CurrentStatus;
            this.safeTransferFrom(from, to, ticketsPackage[from][packageID].ticketIDs[i], ticketsPackage[from][packageID].numOfCopies[i], "");
            
        }
        _royaltyAndGlobalPassFee(ticketsPackage[from][packageID].minimumPrice, percentage, payable(owner()), payable(from) );
        //_royaltyAndGlobalPassFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller, uint8 servicePercentage)
        setApprovalForAll(address(this),true);
        
        user_Balance[from] += msg.value;

    }

    //  function AcceptYourHighestBid (uint packageID, uint _eventID) external  {
    //      address owner = _msgSender();
    //      require(ticketsPackage[owner][packageID].Exists, "You are not owner of the Package");
    //     _getIndexOfHighestBid(owner, packageID);
    //     _deductBiddingAmount(ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index], ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index]);   // Deduct Bidder Amount of Bidding 
    //     CurrentStatus = saleTypeChoice(3);
    //      for(uint i = 0; i<ticketsPackage[owner][packageID].ticketIDs.length; i++)
    //     {
    //         require((balanceOf(owner, ticketsPackage[owner][packageID].ticketIDs[i]) >= CopiesOnBidOrSale[owner][ticketsPackage[owner][packageID].ticketIDs[i]]) &&   (_eventID ==  ticketTypeDetails[ticketsPackage[owner][packageID].ticketIDs[i]].eventIDforTicket), "Error: Cannot Purchase package for Fixed Price");
    //         CopiesOnBidOrSale[owner][ticketsPackage[owner][packageID].ticketIDs[i]] -= ticketsPackage[owner][packageID].numOfCopies[i];
    //         ticketsPackage[owner][packageID].Exists = false;
    //         Ticket[ ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index]][ticketsPackage[owner][packageID].ticketIDs[i]].Exists = true;
    //         Ticket[ ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index]][ticketsPackage[owner][packageID].ticketIDs[i]].salestatus = CurrentStatus;
    //         this.safeTransferFrom(owner,  ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index], ticketsPackage[owner][packageID].ticketIDs[i], ticketsPackage[owner][packageID].numOfCopies[i], "");
    //     }   
    //     //_royaltyAndGlobalPassFee (ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index], _royalties[packageID].amount, _royalties[packageID].recipient, payable(ownerOf(packageID)) , _servicePercentage);
    //     //_transfer(_owners[packageID], ticketsPackage[owner][packageID].bidderAddress[Nft[packageID].index], packageID);
    //     //safeTransferFrom(owner, ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index], packageID, ticketsPackage[owner][packageID].numOfCopies[ticketsPackage[owner][packageID].index], "");
    //     //_setTicketPrice(ticketsPackage[ticketsPackage[owner][packageID].bidderAddress[ticketsPackage[owner][packageID].index]][packageID].bidderAddress[ticketsPackage[owner][packageID].index],packageID, ticketsPackage[owner][packageID].bidAmount[ticketsPackage[owner][packageID].index]);
    //     _removeNftFromSale(owner, packageID);
    //     _bidAccepted(owner, packageID);
    // }

    //Simply transfer a package
    // function _transferPackage(address from, address to, uint packageID, uint _eventID) internal {
    //     CurrentStatus = saleTypeChoice(3);
    //      for(uint i = 0; i<ticketsPackage[from][packageID].ticketIDs.length; i++)
    //       {
    //         require((balanceOf(from, ticketsPackage[from][packageID].ticketIDs[i]) >= CopiesOnBidOrSale[from][ticketsPackage[from][packageID].ticketIDs[i]]) &&   (_eventID ==  ticketTypeDetails[ticketsPackage[from][packageID].ticketIDs[i]].eventIDforTicket), "Error: Cannot TRansfer package.");
    //         CopiesOnBidOrSale[from][ticketsPackage[from][packageID].ticketIDs[i]] -= ticketsPackage[from][packageID].numOfCopies[i];
    //         Ticket[to][ticketsPackage[from][packageID].ticketIDs[i]].salestatus = CurrentStatus;
    //         ticketsPackage[from][packageID].Exists = false;
    //         this.safeTransferFrom(from, to, ticketsPackage[from][packageID].ticketIDs[i], ticketsPackage[from][packageID].numOfCopies[i], "");
    //     }
    //     setApprovalForAll(address(this),true);
        
    // }

    /*
        safeTransferFrom Arguments
        safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
    */

    //Not in use anymore because we are dealing with packages only

    // function transferTickets(address account, uint packageID, uint32 noOfCopies) public {
    //     require(balanceOf(_msgSender(), packageID) >= noOfCopies, "You dont have enough Tickets to transfer");
    //     ticketsPackage[account][packageID].Exists = true;
    //     safeTransferFrom(_msgSender(), account, packageID, noOfCopies, "");
    //     ticketsPackage[account][packageID].salestatus = saleTypeChoice.NotOnSale;
    // }

    function withdrawAmount (uint amount) external payable {
        require(user_Balance[_msgSender()]>=amount, "Your Balance must be Greater Than or Equal to withdraw Amount");
        user_Balance[_msgSender()] -= amount;
        payable(_msgSender()).transfer(amount);
    }
    function checkMintedTickets(uint _ticketID) public view returns (uint) {
        return totalCopiesMinted[_ticketID];
    }

    //  function _getBidBalance(address payable payee, uint bidAmount) internal{
    //     require(msg.value >= bidAmount, "Insufficient balance");
    //     user_Balance[payee] += bidAmount;  
    // }
    // function _deductBiddingAmount(uint _bidAmount, address highestBidderAddress) internal {
    //     require(user_Balance[highestBidderAddress] >= _bidAmount, "Error! Insifficent Balance");
    //     user_Balance[highestBidderAddress]-= _bidAmount;
    // }

    // function _setTicketPrice(address owner, uint packageID, uint _ticketPrice) internal {
    //     tickets_Prices[owner][packageID] = _ticketPrice;
    // }
    
    // function _removeNftFromSale(address owner, uint packageID) internal {
    //     ticketsPackage[owner][packageID].Exists = false;
    //     _removeFromSale(owner, packageID);
    //     _releaseBiddingValue (owner, packageID);
    // }

    function setBaseURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
        whenNotPaused
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        whenNotPaused
    {
        _mintBatch(to, ids, amounts, data);
    }

    function uri(uint _id)  override public view returns (string memory) {
        return tokenURI[_id];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}