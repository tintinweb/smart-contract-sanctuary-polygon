// SPDX-License-Identifier: MIT
/// @author Mr D 

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NftPacks.sol";
import "./SquadToken.sol";

/**
 * @title mPCKT Presale
 */
contract SquadPresale is Ownable, ReentrancyGuard {
    using SafeERC20 for SquadToken;
    using SafeERC20 for IERC20;
    
    using EnumerableSet for EnumerableSet.AddressSet;
 
 	// address for the dev share
 	address devWallet; 

 	// address for the marketing share
 	address marketingWallet; 

 	// address for the operations share
 	address operationsWallet; 

 	// address to store funds for LP launch
 	address lpWallet; 

    // TVL address
    address tvlAddress;

    // the amount of each sale that goes to the TVL 1000 == 100%
    uint256 public tvlPercent = 500;

 	// how to split project funds after TVL is taken (should total 1000)
 	uint256 private devShare = 0;
 	uint256 private marketingShare = 0;
 	uint256 private operationsShare = 0;
 	uint256 private lpShare = 1000;
     


 	// token contract we are giving out
 	SquadToken public tokenContract;
 	
 	// nft pack contract to open
 	NftPacks private nftPacksContract;
    
   


    struct PackSetting {
    	// min amount of native token to spend to get this pack
    	uint256 packCost;

    	// id of the pack to open
    	uint256 packId;
    }

    // struct to hold the breakdown of fund allocation
    struct ToSend {
        uint256 toTvl;
        uint256 toProject;
        uint256 toDev;
        uint256 toMarketing;
        uint256 toOperations;
        uint256 toLp;
    }

    struct PresaleInfo {
    	bool isActive;      // is active flag, used to start or pause a presale
    	uint256 startTime; // start time for the presale
    	uint256 endTime;  // end time for the presale
        uint256 nativePerToken; // cost of native token per presale token
        uint256 daysLocked; // number of days for total lock
        uint256 hardCap;     // max amount of native tokens that can be raised
        uint256 minPerAddress;  // min native token each addrss must spend, disabled if 0
        uint256 maxPerAddress; // max native token each address can spend 
        uint256 totalRaised;  // total amount of native token raised
        uint256 totalAllocated; // total amount of presale token minted
        bool useWhitelist; // enable/disable white lists for this sale
        IERC20 buyToken; //  set to erc20 token you want to accept for the sale. leave as 0x0 for native bnb/eth/matic
        PackSetting[] packSettings; // pack ids and amount thresholds
        
        
    }

    struct UserLock {
        uint256 nativeAmount; // how much they spent to get in
        uint256 tokenAmount;    // total amount locked
        
        uint256 claimedAmount; // total amount they have withdrawn
        uint256 tokensPerDay;
        uint256 lastClaim;

        uint256 startTime; // start of the lock
        uint256 endTime;  //when the lock ends
        uint256 packId; // which pack the opened
    }


    mapping(uint256 => PresaleInfo) public presales;
    uint256 public totalPresales;
    // total native raised
    uint256 public totalRaised;

    // total stable raised
    uint256 public totalRaisedToken;

    // total owned by sale
    uint256 public totalAllocated;

    // total alloted to a presale
    uint256 public totalAssigned;

    // total packs opened
    uint256 public totalPacks;

    // whitelisted addresses for this presale)
    mapping(uint256 => EnumerableSet.AddressSet) private whitelists; 

    // maping for the users locks
    mapping(uint256 => mapping( address => UserLock)) public userLocks;

    event Claimed(address account, uint256 presaleId, uint256 amount);
    event PurchasedNative(address account, uint256 presaleId, uint256 nativeSpent, uint256 tokensMinted, uint256 packId, uint256 lockEnd);
    event PurchasedErc20(address account, uint256 presaleId, uint256 nativeSpent, uint256 tokensMinted, uint256 packId, uint256 lockEnd);
    event AddedToWhitelist(address account, uint256 presaleId);
    event AddedToWhitelistBatch(address[] accounts, uint256 presaleId);
    event RemovedFromWhitelist(address account, uint256 presaleId);
    event PresaleSetActive(uint256 presaleId, bool isActive);
    event ShareSettingsSet(address account, uint256 devShare, uint256 marketingShare, uint256 operationsShare, uint256 lpShare, uint256 tvlPercent);
    constructor(
        SquadToken _tokenContract,
        NftPacks _nftPacksContract,
        address _tvlAddress
    ) {
        tokenContract = _tokenContract;
        nftPacksContract = _nftPacksContract;
        tvlAddress = _tvlAddress;
    }

    function isWhitelisted(uint256 _presaleId, address _user) external view returns(bool){
    	return whitelists[_presaleId].contains(_user);
    }

    function purchase(uint256 _presaleId) public payable nonReentrant {
    	PresaleInfo storage presale = presales[_presaleId];
        require(presale.hardCap > 0, "Invalid Presale");
        require(presale.buyToken == IERC20(address(0)), 'not a native presale');
    	require(presale.isActive && presale.startTime <= block.timestamp && presale.endTime > block.timestamp,'Presale Not Active');
    	require(presale.totalRaised < presale.hardCap, 'Hard Cap Hit');
    	require(!presale.useWhitelist || whitelists[_presaleId].contains(msg.sender),'Not on the Whitelist');
    	require(userLocks[_presaleId][msg.sender].tokenAmount == 0,'Already Participated');
    	require(msg.value >= presale.minPerAddress,'Purchase too small');
    	require(msg.value <= presale.maxPerAddress,'Purchase too large');

    	
    	// if the last person in can't get fully filled, fill what we can and return the rest
    	uint256 toReturn = 0;
    	uint256 amount = msg.value;

    	if((presale.totalRaised + amount) > presale.hardCap) {
    		toReturn = (presale.totalRaised + amount) - presale.hardCap;
    		amount = msg.value - toReturn;
    	}

        ToSend memory toSend;

    	// send X% to the TVL
        toSend.toTvl = _calculateSplit(amount,tvlPercent);

        // split the rest between project wallets
        toSend.toProject = amount - toSend.toTvl;

        toSend.toDev = _calculateSplit(toSend.toProject,devShare);
        toSend.toMarketing = _calculateSplit(toSend.toProject,marketingShare);
        toSend.toOperations = _calculateSplit(toSend.toProject,operationsShare);
        toSend.toLp = amount - toSend.toTvl - toSend.toDev - toSend.toMarketing - toSend.toOperations;

        // send to wallets
        bool send;
        if(toReturn > 0){
        	// return 
	        (send,) = payable(address(msg.sender)).call{value: toReturn}("");
	        require(send, "Failed to send return");
        }

        if(toSend.toTvl > 0){
            // TVL
            (send,) = payable(address(tvlAddress)).call{value: toSend.toTvl}("");
            require(send, "Failed to send tvl");
        }

        if(toSend.toDev > 0){
            // dev
            (send,) = payable(address(devWallet)).call{value: toSend.toDev}("");
            require(send, "Failed to send dev");
        }

        if(toSend.toMarketing > 0){
            // marketing
            (send,) = payable(address(marketingWallet)).call{value: toSend.toMarketing}("");
            require(send, "Failed to send marketing");
        }

        if(toSend.toOperations > 0){
            // operations
            (send,) = payable(address(operationsWallet)).call{value: toSend.toOperations}("");
            require(send, "Failed to send operations");
        }

        if(toSend.toLp > 0){
            // LP fund
            (send,) = payable(address(lpWallet)).call{value: toSend.toLp}("");
            require(send, "Failed to send LP");
        }

        uint256 tokenAmount = (amount * 1 ether)/presale.nativePerToken;

        // presales stats
        presale.totalRaised = presale.totalRaised + amount;
        presale.totalAllocated = presale.totalAllocated + tokenAmount;

        // global stats
        totalRaised = totalRaised + amount;
        totalAllocated = totalAllocated + tokenAmount;

        // set the lock
        uint256 unlockTime = block.timestamp + (presale.daysLocked * 1 days);

        userLocks[_presaleId][msg.sender].nativeAmount = amount;
        userLocks[_presaleId][msg.sender].tokenAmount = tokenAmount;
        userLocks[_presaleId][msg.sender].tokensPerDay = tokenAmount/presale.daysLocked;
        userLocks[_presaleId][msg.sender].startTime = block.timestamp;
        userLocks[_presaleId][msg.sender].lastClaim = block.timestamp;
        userLocks[_presaleId][msg.sender].endTime = unlockTime;

        // figure out which pack they get
        uint256 packId;
        for (uint256 i = 0; i < presale.packSettings.length; i++) {
        	if(amount >= presale.packSettings[i].packCost){
        		packId = presale.packSettings[i].packId;
        	} else {
        		break;
        	}
        }

        userLocks[_presaleId][msg.sender].packId = packId;

        // mint the tokens 
        // tokenContract.mint(address(this),tokenAmount);



        if(packId > 0){
            totalPacks = totalPacks + 1;
            // open the pack
            nftPacksContract.open(
              packId,
              msg.sender,
              1
            );
        }

        emit PurchasedNative(msg.sender, _presaleId, amount, tokenAmount, packId, unlockTime);

    }

    function purchaseErc20(uint256 _presaleId, uint256 _amount) public payable nonReentrant {
        PresaleInfo storage presale = presales[_presaleId];

        require(presale.hardCap > 0, "Invalid Presale");
        require(presale.buyToken != IERC20(address(0)), 'not an erc20 presale');
        require(presale.isActive && presale.startTime <= block.timestamp && presale.endTime > block.timestamp,'Presale Not Active');
        require(presale.buyToken.balanceOf(msg.sender) >= _amount, 'balance too low');
        require(presale.totalRaised < presale.hardCap, 'Hard Cap Hit');
        require(!presale.useWhitelist || whitelists[_presaleId].contains(msg.sender),'Not on the Whitelist');
        require(userLocks[_presaleId][msg.sender].tokenAmount == 0,'Already Participated');
        require(_amount >= presale.minPerAddress,'Purchase too small');
        require(_amount <= presale.maxPerAddress,'Purchase too large');

        // move the tokens
        presale.buyToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        
        // if the last person in can't get fully filled, fill what we can and return the rest
        uint256 toReturn = 0;
        uint256 amount = _amount;

        if((presale.totalRaised + amount) > presale.hardCap) {
            toReturn = (presale.totalRaised + amount) - presale.hardCap;
            amount = _amount - toReturn;
        }

        ToSend memory toSend;

        // send X% to the TVL
        toSend.toTvl = _calculateSplit(amount,tvlPercent);

        // split the rest between project wallets
        toSend.toProject = amount - toSend.toTvl;

        toSend.toDev = _calculateSplit(toSend.toProject,devShare);
        toSend.toMarketing = _calculateSplit(toSend.toProject,marketingShare);
        toSend.toOperations = _calculateSplit(toSend.toProject,operationsShare);
        toSend.toLp = amount - toSend.toTvl - toSend.toDev - toSend.toMarketing - toSend.toOperations;

        // send to wallets
        if(toReturn > 0){
            // return 
            // move the tokens
            presale.buyToken.safeTransfer(address(msg.sender), toReturn);
        }

        if(toSend.toTvl > 0){
            // TVL
            presale.buyToken.safeTransfer(address(tvlAddress), toSend.toTvl);
        }
        
        if(toSend.toDev > 0){
            // dev
            presale.buyToken.safeTransfer(address(devWallet), toSend.toDev);
        }

        if(toSend.toMarketing > 0){
            // marketing
            presale.buyToken.safeTransfer(address(marketingWallet), toSend.toMarketing);
        }
        
        if(toSend.toOperations > 0){
            // operations
            presale.buyToken.safeTransfer(address(operationsWallet), toSend.toOperations);
        }
        
        if(toSend.toLp > 0){
            // LP fund
            presale.buyToken.safeTransfer(address(lpWallet), toSend.toLp);
        }

        uint256 tokenAmount = (amount * 1 ether)/presale.nativePerToken;

        // presales stats
        presale.totalRaised = presale.totalRaised + amount;
        presale.totalAllocated = presale.totalAllocated + tokenAmount;

        // global stats
        totalRaisedToken = totalRaisedToken + amount;
        totalAllocated = totalAllocated + tokenAmount;


        // set the lock
        uint256 unlockTime = block.timestamp + (presale.daysLocked * 1 days);

        userLocks[_presaleId][msg.sender].nativeAmount = amount;
        userLocks[_presaleId][msg.sender].tokenAmount = tokenAmount;
        userLocks[_presaleId][msg.sender].tokensPerDay = tokenAmount/presale.daysLocked;
        userLocks[_presaleId][msg.sender].startTime = block.timestamp;
        userLocks[_presaleId][msg.sender].lastClaim = block.timestamp;
        userLocks[_presaleId][msg.sender].endTime = unlockTime;

        // figure out which pack they get
        uint256 packId;
        for (uint256 i = 0; i < presale.packSettings.length; i++) {
            if(amount >= presale.packSettings[i].packCost){
                packId = presale.packSettings[i].packId;
            } else {
                break;
            }
        }

        userLocks[_presaleId][msg.sender].packId = packId;

        // mint the tokens 
        // tokenContract.mint(address(this),tokenAmount);



        if(packId > 0){
            totalPacks = totalPacks + 1;
            // open the pack
            nftPacksContract.open(
              packId,
              msg.sender,
              1
            );
        }

        emit PurchasedErc20(msg.sender, _presaleId, amount, tokenAmount, packId, unlockTime);

    }

    function claimLock(uint256 _presaleId) public nonReentrant {
        require(userLocks[_presaleId][msg.sender].tokenAmount > 0, 'Not Locked');
        require( (userLocks[_presaleId][msg.sender].tokenAmount - userLocks[_presaleId][msg.sender].claimedAmount) > 0 , 'Nothing to claim');

        uint256 toClaim = _pendingRewards(_presaleId, msg.sender);
       
        require(toClaim > 0, 'Nothing to claim.');

        userLocks[_presaleId][msg.sender].claimedAmount = userLocks[_presaleId][msg.sender].claimedAmount + toClaim;
        userLocks[_presaleId][msg.sender].lastClaim = block.timestamp;

        // move the tokens
        tokenContract.safeTransfer(address(msg.sender), toClaim);
        emit Claimed(msg.sender, _presaleId, toClaim);
    }

    function pendingRewards(uint256 _presaleId, address _user) public view returns(uint256) {
        return _pendingRewards(_presaleId, _user);
    }

    function _pendingRewards(uint256 _presaleId, address _user) private view returns(uint256) {
        
        uint256 blockTime = block.timestamp;
        uint256 totalRemain = userLocks[_presaleId][_user].tokenAmount - userLocks[_presaleId][_user].claimedAmount;
        bool lockComplete;
        if(userLocks[_presaleId][_user].endTime < blockTime){
            blockTime = userLocks[_presaleId][_user].endTime;
            lockComplete = true;
        }

        uint256 pending = (blockTime - userLocks[_presaleId][_user].lastClaim) * ( userLocks[_presaleId][_user].tokensPerDay/86400);

        if(!lockComplete){
            return pending;
        }

        // make sure there's no loose change after lock is up
        if(totalRemain > 0){
            return totalRemain;
        }

        return 0;
    }


    function getPresaleNfts(uint256 _presaleId) public view returns(PackSetting[] memory){
        return presales[_presaleId].packSettings;
    }


    event CreatePresale(uint256 hardCap, uint256 startTime, uint256 totalTokens);
    function createPresale(
    	uint256 _hardCap, 
    	uint256[2] calldata _times,
    	uint256 _nativePerToken,
    	uint256 _daysLocked,
    	uint256 _minPerAddress,
    	uint256 _maxPerAddress,
        bool _useWhitelist,
        IERC20 _buyToken,
    	uint256[] calldata _packCosts,
    	uint256[] calldata _packIds
    ) public onlyOwner {
        uint256 totalTokens = (_hardCap * 1 ether)/_nativePerToken; 

        require(totalTokens <= unAssignedTokens(),'Not enough tokens left');

    	presales[totalPresales].hardCap = _hardCap;
    	presales[totalPresales].startTime = _times[0];
    	presales[totalPresales].endTime =  _times[1];
    	presales[totalPresales].nativePerToken = _nativePerToken;
    	presales[totalPresales].daysLocked = _daysLocked;
    	presales[totalPresales].minPerAddress = _minPerAddress;
    	presales[totalPresales].maxPerAddress = _maxPerAddress;
        presales[totalPresales].useWhitelist = _useWhitelist;
        presales[totalPresales].buyToken = _buyToken;
        
    	setPresalePacks(totalPresales, _packCosts, _packIds);

        totalAssigned += totalTokens;
    	totalPresales = totalPresales +1;
        emit CreatePresale(_hardCap,_times[0],totalTokens);
    }

    
    function setPresalePacks(uint256 _presaleId, uint256[] calldata _packCosts, uint256[] calldata _packIds) public onlyOwner {
    	require(presales[_presaleId].hardCap > 0, 'No Presale');

        delete presales[_presaleId].packSettings;
        for (uint256 i = 0; i < _packCosts.length; ++i) {

            presales[_presaleId].packSettings.push(PackSetting({
                packCost: _packCosts[i],
                packId: _packIds[i]
            }));
        }

    }

    function setPresaleActive(uint256 _presaleId, bool _active) public onlyOwner {
    	presales[_presaleId].isActive = _active;
    	emit PresaleSetActive(_presaleId, _active);
    }

    function setFeeAddresses(
        address _devWallet,
        address _marketingWallet,
        address _operationsWallet,
        address _lpWallet
    ) public onlyOwner {
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;
        operationsWallet = _operationsWallet;
        lpWallet = _lpWallet;
    }


    function setShareSettings(uint256 _devShare, uint256 _marketingShare, uint256 _operationsShare, uint256 _lpShare, uint256 _tvlPercent) public onlyOwner {
        devShare = _devShare;
        marketingShare = _marketingShare;
        operationsShare = _operationsShare;
        lpShare = _lpShare;
        tvlPercent = _tvlPercent;

        emit ShareSettingsSet(msg.sender, devShare,marketingShare, operationsShare, lpShare, tvlPercent);
    }
    // manage the Enumerable Sets
    function addToWhitelist(uint256 _presaleId, address _user) public onlyOwner {
    	require(presales[_presaleId].hardCap > 0, 'No Presale');
    	require(!whitelists[_presaleId].contains(_user), 'Already on the list');

        whitelists[_presaleId].add(_user);
        emit AddedToWhitelist(_user, _presaleId);
    }

    function addToWhitelistBatch(uint256 _presaleId, address[] calldata _users) public onlyOwner {
        require(presales[_presaleId].hardCap > 0, 'No Presale');

        for(uint256 i =0; i<_users.length; ++i){
            if(!whitelists[_presaleId].contains(_users[i])){
                whitelists[_presaleId].add(_users[i]);
            }
        }
     
        emit AddedToWhitelistBatch(_users, _presaleId);
    }

    // manage the Enumerable Sets
    function removeFromWhitelist(uint256 _presaleId, address _user) public onlyOwner {
    	require(presales[_presaleId].hardCap > 0, 'No Presale');
    	require(whitelists[_presaleId].contains(_user), 'Not on the list');

        whitelists[_presaleId].remove(_user);
        emit RemovedFromWhitelist(_user, _presaleId);
    }

    function _calculateSplit(uint256 amount, uint256 splitPercent) private pure returns (uint256) {
        return (amount*splitPercent) / 1000;
    }

    // total tokens in the contract that were assigned but not purchased
    function unAllocatedTokens() public view returns (uint256) {
        return tokenContract.balanceOf(address(this)) - totalAllocated;
    }

    // tokens that can still be added to a presale
    function unAssignedTokens() public view returns (uint256) {
        return tokenContract.balanceOf(address(this)) - totalAssigned;
    }

    
    /**
     * @dev burn all unallocated tokens
     */
    event CompleteAllSales(uint256 toBurn);
    function completeAllSales() public onlyOwner {
        uint256 toBurn = tokenContract.balanceOf(address(this)) - totalAllocated;
        // tokenContract.safeTransfer(address(0xdead), toBurn);
        // tokenContract.burn(toBurn);
        emit CompleteAllSales(toBurn);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
    function _beforeTokenTransfer(
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDEXPair {function sync() external;}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11; 

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import './Concat.sol';

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, Ownable, AccessControl {
    using SafeMath for uint256;
    using Strings for string;

//    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public tokenInitialMaxSupply;

    address public constant burnWallet = address(0xdead);
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri

    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "erc721tradable#uri: NONEXISTENT_TOKEN");
        string memory _uri = super.uri(_id);
        return Concat.strConcat(_uri, Strings.toString(_id));
    }


    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function initialMaxSupply(uint256 _id) public view returns (uint256) {
        return tokenInitialMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) public returns (uint256 tokenId) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

         if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
      
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        tokenInitialMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 newSupply = tokenSupply[_id].add(_quantity);
        require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
         _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
        * @dev Mint tokens for each id in _ids
        * @param _to          The address to mint tokens to
        * @param _ids         Array of ids to mint
        * @param _quantities  Array of amounts of tokens to mint per id
        * @param _data        Data to pass if receiver is contract
    */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        for (uint256 i = 0; i < _ids.length; i++) {
          uint256 _id = _ids[i];
          uint256 quantity = _quantities[i];
          uint256 newSupply = tokenSupply[_id].add(quantity);
          require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
          
          tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    function burn(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) external virtual {
        require((msg.sender == _address) || isApprovedForAll(_address, msg.sender), "ERC1155#burn: INVALID_OPERATOR");
        require(balanceOf(_address,_id) >= _amount, "Trying to burn more tokens than you own");

        //_burnAndReduce(_address,_id,_amount);
         _burn(_address, _id, _amount);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(from,id,amount);
        // reduce max supply
        tokenMaxSupply[id] = tokenMaxSupply[id] - amount;
    }
    

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

     /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,ERC1155) returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Concat {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/PancakeLibs.sol";


contract SquadToken is Ownable, IERC20, IERC20Metadata, AccessControlEnumerable, Pausable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // standard ERC20 vars
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _totalBurned;
    string private _name;
    string private _symbol;


    // role constants
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CAN_TRANSFER_ROLE = keccak256("CAN_TRANSFER_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    // flag to stop swaps before there is LP 
    bool tradingActive;

    // The burn address
    address public constant burnAddress = address(0xdead);

    // the max tokens that can ever exist
    uint256 public maxSupply;

    // Dev address 
    address marketingWallet;

    // Squads contract address
    address tvlAddress;

    bool private _isSwapping;

    // USDC/stable coin address
    IERC20 stableToken;

    EnumerableSet.AddressSet private _amms;
    EnumerableSet.AddressSet private _systemContracts;
    EnumerableSet.AddressSet private _excludeTaxes;
    EnumerableSet.AddressSet private _excludeLocks;

    // TAX SETTINGS
    
    // Main Ttaxes
    // hard coded max tax limit
    uint256 constant _maxTax = 25;

    // % taxed on sells
    uint256 sellTax = 7;

    // % taxed and burned on buys
    uint256 buyTax = 7;


    // Sub-Taxes
    // % of post taxed amount that is sent to the squads contract
    uint256 tvlTax = 43;
    // % of post taxed amount that is sent to marketing wallet
    uint256 marketingTax = 29;
    // % of post taxed amount that used for LP
    uint256 lpTax = 14;
    // % of post taxed amount that is burned
    uint256 burnTax = 14;
    
    /**
     * Anti-Dump & Anti-Bot Settings
     **/

    // a hard capped number on the max tokens that can be sold in one TX
    uint256 maxSell;

    // max % sell of total supply that can be sold in one TX, default 1%
    uint256 constant maxSellPercent = 100; 

    // min tokens to collect before swapping for fees
    uint256 private swapThresh;

    // max tokens a wallet can hold, defaults to 1% initial supply
    uint256 maxWallet;

    // seconds to lock transactions to aything but system contracts after a sell
    uint256 txLockTime;
    mapping (address => uint256) private txLock;

    // PCS router
    address public immutable lpAddress; 
    IPancakeRouter02 private  _routerAddress; 

    address private immutable Router;

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 _maxSupply,
        address _marketingWallet,
        IERC20 _stableToken,
        address _tvlAddress,
        address _router
    ) {
        
        require(_router != address(0), "ERC20: router not set");
        require(_marketingWallet != address(0), "ERC20: marketing address not set");

        _name = name_;
        _symbol = symbol_;

        Router = _router;

        marketingWallet = _marketingWallet;
        stableToken = _stableToken;
        tvlAddress = _tvlAddress;

        maxSupply = _maxSupply;
        _balances[msg.sender] = _maxSupply;
        _totalSupply = _maxSupply;

        maxWallet = _calculateTax(_maxSupply,1,100);
        swapThresh = _totalSupply / 100000;

        _routerAddress = IPancakeRouter02(Router);
        lpAddress = IPancakeFactory(_routerAddress.factory()).createPair(address(_stableToken), address(this));

        _amms.add(lpAddress);

        require(
            _excludeTaxes.add(address(0)) && 
            _excludeTaxes.add(msg.sender) && 
            _excludeTaxes.add(address(this)) && 

            _excludeLocks.add(address(0)) &&
            _excludeLocks.add(msg.sender) && 
            _excludeLocks.add(address(this)) &&
        
            _systemContracts.add(address(0)) &&
            _systemContracts.add(address(this)) &&
            _systemContracts.add(address(_marketingWallet)), "error adding to lists");
       
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(CAN_TRANSFER_ROLE, msg.sender);
        _grantRole(CAN_TRANSFER_ROLE, address(_marketingWallet));

    }

    // modifier for functions only the team can call
    modifier onlyTeam() {
        require(hasRole(TEAM_ROLE,  msg.sender) || msg.sender == owner(), "Caller not in Team");
        _;
    }


     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    
     function burn(uint256 _amount) external virtual {
        _burn(msg.sender, _amount);
    }

    /**
     * @dev pause the token for transfers other than addresses with the CanTransfer Role
     */
    function pause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "ERC20: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev unpause the token for anyone to transfer
     */
    function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "ERC20: must have pauser role to unpause");
        _unpause();
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);

        

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        bool isBuy = _amms.contains(sender);
        bool isSell = _amms.contains(recipient);
        bool isToSystem = _systemContracts.contains(recipient);
        bool isFromSystem = _systemContracts.contains(sender) || sender == address(_routerAddress);
        uint256 postTaxAmount = amount;

        require(isToSystem || isSell || ( _balances[recipient] + amount) <= maxWallet, 'Max Wallet' );

        require(tradingActive || isToSystem || isFromSystem || (!isSell && !isBuy), 'Trading not started' );

        if(recipient == burnAddress){
            _burn(sender,amount);
        } else {

            require(isFromSystem || isToSystem || txLock[sender] <= block.timestamp, "ERC20: Transactions Locked");

            unchecked {
                _balances[sender] -= amount;
            }
            
            uint256 toBurn;
            if(tradingActive){
                if(isSell){
                    // make sure we we aren't getting dumpped on
                    if(!isToSystem && !isFromSystem){
                        uint256 maxPercentAmount = (_totalSupply * maxSellPercent)/10000;
                        if(maxPercentAmount < maxSell){
                            maxPercentAmount = maxSell;
                        }
                        require(
                            (maxSell == 0 || amount <= maxSell) && 
                            (maxPercentAmount == 0 || amount <= maxPercentAmount), 
                            'ERC20: Y Dump?');
                    }

                    
                    // see if we need to tax 
                    if(!_isSwapping && !isToSystem && !isFromSystem && !_excludeTaxes.contains(sender) && sellTax > 0){
                         // lock the sells for the cool down peirod
                        _setTxLock(sender);
                        (postTaxAmount, toBurn) = _takeTax(amount, sellTax, true);
                    }
                    
                }

                if(isBuy){
                    
                    // see if we need to tax 
                    if(!_isSwapping && !isToSystem && !isFromSystem && !_excludeTaxes.contains(recipient) && buyTax > 0){
                        (postTaxAmount, toBurn) = _takeTax(amount, buyTax, false);
                    }
                    
                }
            }
            
            
            // burn
            if(toBurn > 0){
                _burn(address(this),toBurn);    
            }

            _balances[recipient] += postTaxAmount;

            emit Transfer(sender, recipient, postTaxAmount);

        }
    }

    function _takeTax(uint256 _amount, uint256 _tax, bool _doSwap) private returns(uint256, uint256){
       // calc the taxes 
        uint256 taxAmount = _calculateTax(_amount,_tax,100);
        
        // send the tax to the contract
        _balances[address(this)] += taxAmount;

        uint256 _postTax = _amount - taxAmount;
        uint256 _toBurn;
        uint256 _toLp;
        uint256 _toTvl;
        uint256 _toMarketing;

        if(_doSwap && _balances[address(this)] >= swapThresh){

                uint256 remain = _balances[address(this)];
                // see if we have a burn tax before we swap
                if(burnTax > 0){
                    _toBurn = _calculateTax(_balances[address(this)], burnTax, 100);
                    remain -= _toBurn;
                }

                // pull out the LP share to swap
                if(lpTax > 0){
                    _toLp = _calculateTax(_balances[address(this)], lpTax, 100);
                    remain -= _toLp;
                }

                // pull out the LP share to swap
                // get TVL share
                if(tvlTax > 0){
                    _toTvl = _calculateTax(_balances[address(this)], tvlTax, 100);
                    remain -= _toTvl;
                }

                // get Marketing share
                if(marketingTax > 0){
                    _toMarketing = remain;
                }

                // do the swaps
                if(_toTvl > 0){
                    // send to TVL
                    _swapTokenForStable(_toTvl, address(tvlAddress)); 
                }

                if(_toMarketing > 0){
                    // send to Marketing
                    _swapTokenForStable(_toMarketing, address(marketingWallet)); 
                }

                if(_toLp > 0){
                    _transfer(address(this),address(lpAddress),_toLp);
                    IDEXPair(lpAddress).sync();
                }

                
    
        }

        return (_postTax, _toBurn);
    }

    function _setTxLock(address _addr) private {    
        if(!_excludeLocks.contains(_addr) && txLockTime > 0){
            txLock[_addr] = block.timestamp + txLockTime;
        }
    }

    //Calculates the token that should be taxed
    function _calculateTax(uint256 amount, uint256 tax, uint256 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }

    //swaps token for token
    function _swapTokenForStable(uint256 amount, address to) public {
        _isSwapping = true;
        _approve(address(this), address(_routerAddress), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(stableToken);

         try _routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(to),
            block.timestamp
        ){}
        catch{}
       _isSwapping = false;
    }


    /**
     * Set the various taxes.
     * No tax can ever be higher than the global max
     **/
    event SetTaxes(uint256 sellTax, uint256 _buyTax);
    function setTaxes(
        uint256 _sellTax, 
        uint256 _buyTax
    ) external onlyTeam {
        require(
            _sellTax <= _maxTax && 
            _buyTax <= _maxTax, 'Tax too high'
        );

        sellTax = _sellTax;
        buyTax = _buyTax;

        emit SetTaxes(_sellTax, _buyTax);
    }


    event SetSubTaxes(uint256 tvlTax, uint256 lpTax, uint256 marketingTax, uint256 burnTax);
    function setSubTaxes(
        uint256 _tvlTax,
        uint256 _lpTax,
        uint256 _marketingTax,
        uint256 _burnTax
    ) external onlyTeam {
        require(_tvlTax + _lpTax + _marketingTax + _burnTax  <= 100,'tax too high');
        tvlTax = _tvlTax;
        lpTax = _lpTax;
        marketingTax = _marketingTax;
        burnTax = _burnTax;

        emit SetSubTaxes(_tvlTax, _lpTax, _marketingTax, _burnTax );
    }

    // update the sell protection settings
    event SetSellProtection(uint256 maxSell, uint256 maxSellPercent, uint256 txLock);
    function setSellProtection(uint256 _maxSell, uint256 _maxSellPercent, uint256 _txLockTime) external onlyTeam {
        // must be higher than 0.1% 
        require(_maxSellPercent > 10, 'Sell Percent too low');

        // must be lower or equal to 10% 
        require(_maxSellPercent <= 1000, 'Sell Percent too high');

        // lock time must a day or less
        require(_txLockTime <= 86400, 'lock time too long');
        
        maxSell = _maxSell;
        txLockTime = _txLockTime;
        emit SetSellProtection(_maxSell, _maxSellPercent, _txLockTime);
    }

    // set max wallet to a given percent
    event SetMaxWallet(uint256 maxWalletPercent, uint256 maxWallet);
    function setMaxWallet(uint256 _maxWalletPercent) external onlyTeam {
        require(_maxWalletPercent <= 15, 'too high');
        require(_maxWalletPercent >= 1, 'too low');

        maxWallet = _calculateTax(maxSupply,_maxWalletPercent,100);
        emit SetMaxWallet(_maxWalletPercent, maxWallet);
    }

    event SetSwapThresh(uint256 swapThresh);
    function setSwapThresh(uint256 _swapThresh) external onlyTeam {
        swapThresh = _swapThresh;
        emit SetSwapThresh(_swapThresh);
    }
    
    // one time use, will enable trading after LP is setup
    event SetTradingActive();
    function setTradingActive() external onlyTeam {
        tradingActive = true;
        if(paused()){
            _unpause();
        }

        emit SetTradingActive();
    }

    event SetTvlAddress(address oldAddress, address newAddress);
    function setTvlAddress(address _tvlAddress) external onlyTeam {
        require(_tvlAddress != address(0), "Invalid Address");
        emit SetTvlAddress(tvlAddress, _tvlAddress);
        tvlAddress = _tvlAddress;
    }

    // manage the Enumerable Sets
    event AddAmmAddress(address amm);
    function addAmmAddress(address _amm) external onlyTeam {
        require(_amm != address(0), "Invalid Address");
        require(_amms.add(_amm), 'list error');
        emit AddAmmAddress(_amm);
    }

    event RemoveAmmAddress(address amm);
    function removeAmmAddress(address _amm) external onlyTeam {
        require(_amms.remove(_amm), 'list error');
        emit RemoveAmmAddress(_amm);
    }

    event AddSystemContract(address addr);
    function addSystemContractAddress(address _addr) external onlyTeam {
        require(_addr != address(0), "Invalid Address");
        require(_systemContracts.add(_addr), 'list error');
        emit AddSystemContract(_addr);
    }

    event RemoveSystemContract(address addr);
    function removeSystemContractAddress(address _addr) external onlyTeam {
        require(_systemContracts.remove(_addr), 'list error');
        emit RemoveSystemContract(_addr);
    }

    event AddExcludeTaxes(address addr);
    function addExcludeTaxesAddress(address _addr) external onlyTeam {
        require(_addr != address(0), "Invalid Address");
        require(_excludeTaxes.add(_addr), 'list error');
        emit AddExcludeTaxes(_addr);
    }

    event RemoveExcludeTaxes(address addr);
    function removeExcludeTaxesAddress(address _addr) external onlyTeam {
        require(_excludeTaxes.remove(_addr), 'list error');
        emit RemoveExcludeTaxes(_addr);
    }

    event AddExcludedLocks(address addr);
    function addExcludedLocksAddress(address _addr) external onlyTeam {
        require(_addr != address(0), "Invalid Address");
        require(_excludeLocks.add(_addr), 'list error');
        emit AddExcludedLocks(_addr);
    }

    event RemoveExcludedLocks(address addr);
    function removeExcludedLocksAddress(address _addr) external onlyTeam {
       require(_excludeLocks.remove(_addr), 'list error');
       emit RemoveExcludedLocks(_addr);
    }


    event SetMarketingAddress(address oldAddress, address newAddress);
    function setMarketingAddress(address _marketingWallet) external onlyTeam {
        require(_marketingWallet != address(0), "ERC20: marketingWallet address not set");
        _systemContracts.remove(address(marketingWallet));
        emit SetMarketingAddress(marketingWallet, _marketingWallet);
        marketingWallet = _marketingWallet;
        _systemContracts.add(address(_marketingWallet));
    }



    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
       
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

         _transfer(sender, recipient, amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    event BurnTokens(address from, address to, uint256 amount);
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

       _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
       require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        _totalBurned += amount;


        emit Transfer(account, address(0), amount);
        emit BurnTokens(msg.sender, account, amount);
        
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 
    ) internal virtual {
        // super._beforeTokenTransfer(from, to, amount);
        require(!paused() || hasRole(CAN_TRANSFER_ROLE, from) || hasRole(CAN_TRANSFER_ROLE, to) || _systemContracts.contains(from) || _systemContracts.contains(to), "ERC20Pausable: token transfer while paused");
    }

    // move any tokens sent to the contract
    function teamTransferToken(address tokenAddress, address recipient, uint256 amount) external onlyTeam {
        require(tokenAddress != address(0), "Invalid Address");
        IERC20 _token = IERC20(tokenAddress);
        _token.safeTransfer(recipient, amount);
    }


    // pull all the eth/bnb/matic out of the contract, needed for migrations/emergencies and transfers to other chains
    function withdrawETH() external onlyTeam {
         (bool sent,) =address(owner()).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./libs/ERC1155Tradable.sol";

/**
 * @title NftPack 
 * NftPack - a randomized and openable lootbox of Nfts
 */

contract NftPacks is Ownable, Pausable, AccessControl, ReentrancyGuard, VRFConsumerBaseV2, IERC1155Receiver {
  using Strings for string;

  ERC1155Tradable public nftContract;

  // amount of items in each grouping/class
  mapping (uint256 => uint256) public Classes;
  bool[] public Option;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

  uint256 constant INVERSE_BASIS_POINT = 10000;
  bool internal allowMint;

  // Chainlink VRF
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 subscriptionId;
  bytes32 internal keyHash;
  address internal vrfCoordinator;
  uint32 internal callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  // uint256[] private _randomWords;
  uint256 private _randomness;
  uint256 private _seed;
  

  event cardPackOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);
  event Warning(string message, address account);
  event SetLinkFee(address indexed user, uint256 fee);
  event SetNftContract(address indexed user, ERC1155Tradable nftContract);

  struct OptionSettings {
    // which group of classes this belongs to 
    uint256 groupingId;
    // Number of items to send per open.
    // Set to 0 to disable this Option.
    uint32 maxQuantityPerOpen;
    // Probability in basis points (out of 10,000) of receiving each class (descending)
    uint16[] classProbabilities; // NUM_CLASSES
    // Whether to enable `guarantees` below
    bool hasGuaranteedClasses;
    // Number of items you're guaranteed to get, for each class
    uint16[] guarantees; // NUM_CLASSES
  }

  /** 
   * @dev info on the current zck being opened 
   */
  struct PackQueueInfo {
    address userAddress; //user opening the pack
    uint256 optionId; //packId being opened
    uint256 amount; //amount of packs
  }

  uint256 private defaultNftId = 1;

  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => mapping (uint256 => uint256[])) public classToTokenIds;

  // keep track of the times each token is minted, 
  // if internalMaxSupply is > 0 we use the internal data
  // if it is 0 we will use supply of the NFT contract instead
  mapping (uint256 => mapping (uint256 =>  mapping (uint256 => uint256)))  public internalMaxSupply;
  mapping (uint256 => mapping (uint256 =>  mapping (uint256 => uint256))) public internalTokensMinted;
  
  mapping (address => uint256[]) public lastOpen;
  mapping (address => uint256) public isOpening;
  mapping(uint256 => PackQueueInfo) private packQueue;


  constructor(
    ERC1155Tradable _nftAddress,
    address _vrfCoordinator,
    bytes32 _vrfKeyHash, 
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(
    _vrfCoordinator
  ) {

    nftContract = _nftAddress;

    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    subscriptionId = _subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _vrfKeyHash;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

  }

   /** 
     * @notice Modifier to only allow updates by the VRFCoordinator contract
     */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'Fulfillment only allowed by VRFCoordinator');
        _;
    }

    // modifier for functions only the team can call
    modifier onlyTeam() {
        require(hasRole(TEAM_ROLE,  msg.sender) || msg.sender == owner(), "Caller not in Team");
        _;
    }

  /**
   * @dev Add a Class Id
   */
   function setClassLength(uint256 _groupingId, uint256 _classLength) public onlyOwner {
      Classes[_groupingId] = _classLength;
   }


  /**
   * @dev If the tokens for some class are pre-minted and owned by the
   * contract owner, they can be used for a given class by setting them here
   */
  function setClassForTokenId(
    uint256 _groupingId,
    uint256 _classId,
    uint256 _tokenId,
    uint256 _amount
  ) public onlyOwner {
  //  _checkTokenApproval();
    _addTokenIdToClass(_groupingId, _classId, _tokenId, _amount);
  }

  /**
   * @dev bulk replace all tokens for a class
   */
  function setClassTokenIds(
    uint256 _groupingId,
    uint256 _classId,
    uint256[] calldata _tokenIds
  ) public onlyOwner {
    classToTokenIds[_groupingId][_classId] = _tokenIds;
  }

 
  /**
   * @dev Remove all token ids for a given class, causing it to fall back to
   * creating/minting into the nft address
   */
  function resetClass(
    uint256 _groupingId,
    uint256 _classId
  ) public onlyOwner {
    delete classToTokenIds[_groupingId][_classId];
  }

  /**
   * @param _groupingId The Grouping this Option is for
   * @param _optionId The Option to set settings for
   * @param _maxQuantityPerOpen Maximum number of items to mint per open.
   *                            Set to 0 to disable this pack.
   * @param _classProbabilities Array of probabilities (basis points, so integers out of 10,000)
   *                            of receiving each class (the index in the array).
   *                            Should add up to 10k and be descending in value.
   * @param _guarantees         Array of the number of guaranteed items received for each class
   *                            (the index in the array).
   */
  function setOptionSettings(
    uint256 _groupingId,
    uint256 _optionId,
    uint32 _maxQuantityPerOpen,
    uint16[] calldata _classProbabilities,
    uint16[] calldata _guarantees
  ) external onlyOwner {
    addOption(_optionId);
    // Allow us to skip guarantees and save gas at mint time
    // if there are no classes with guarantees
    bool hasGuaranteedClasses = false;
    for (uint256 i = 0; i < Classes[_groupingId]; i++) {
      if (_guarantees[i] > 0) {
        hasGuaranteedClasses = true;
      }
    }

    OptionSettings memory settings = OptionSettings({
      groupingId: _groupingId,
      maxQuantityPerOpen: _maxQuantityPerOpen,
      classProbabilities: _classProbabilities,
      hasGuaranteedClasses: hasGuaranteedClasses,
      guarantees: _guarantees
    });

    
    optionToSettings[_optionId] = settings;
  }


  function getLastOpen(address _address) external view returns(uint256[] memory) {
    return lastOpen[_address];
  }

  function getIsOpening(address _address) external view returns(uint256) {
    return isOpening[_address];  
  }
  
  /**
   * @dev Add an option Id
   */
  function addOption(uint256 _optionId) internal onlyOwner{
    if(_optionId >= Option.length || _optionId == 0){
      Option.push(true);
    }
  }


  /**
   * @dev Open the NFT pack and send what's inside to _toAddress
   */
  function open(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount
  ) external onlyRole(MINTER_ROLE) {
    _mint(_optionId, _toAddress, _amount, "");
  }


  /**
   * @dev Main minting logic for NftPacks
   */
  function _mint(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount,
    bytes memory /* _data */
  ) internal whenNotPaused onlyRole(MINTER_ROLE) nonReentrant returns (uint256) {
    // Load settings for this box option
    
    OptionSettings memory settings = optionToSettings[_optionId];

    require(settings.maxQuantityPerOpen > 0, "NftPack#_mint: OPTION_NOT_ALLOWED");
    require(isOpening[_toAddress] == 0, "NftPack#_mint: OPEN_IN_PROGRESS");

   // require(LINK.balanceOf(address(this)) > linkFee, "Not enough LINK - fill contract with faucet");

    isOpening[_toAddress] = _optionId;
    uint256 _requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      1
    );

    PackQueueInfo memory queue = PackQueueInfo({
      userAddress: _toAddress,
      optionId: _optionId,
      amount: _amount
    });
    
    packQueue[_requestId] = queue;

    return _requestId;
 
  }

  /**
   * @notice Callback function used by VRF Coordinator
  */
   function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {

    // _randomWords = randomWords;
    _randomness = randomWords[0];
    
    PackQueueInfo memory _queueInfo = packQueue[requestId];
    doMint(_queueInfo.userAddress, _queueInfo.optionId, _queueInfo.amount);

  }

  function doMint(address _userAddress, uint256 _optionId, uint256 _amount) internal onlyVRFCoordinator {
    
    OptionSettings memory settings = optionToSettings[_optionId];
   
    isOpening[_userAddress] = 0;

    delete lastOpen[_userAddress];
    uint256 totalMinted = 0;
    // Iterate over the quantity of packs to open
    for (uint256 i = 0; i < _amount; i++) {
      // Iterate over the classes
      uint256 quantitySent = 0;
      if (settings.hasGuaranteedClasses) {
        // Process guaranteed token ids
        for (uint256 classId = 1; classId < settings.guarantees.length; classId++) {
            uint256 quantityOfGaranteed = settings.guarantees[classId];

            if(quantityOfGaranteed > 0) {
              lastOpen[_userAddress].push(_sendTokenWithClass(settings.groupingId, classId, _userAddress, quantityOfGaranteed));
              quantitySent += quantityOfGaranteed;    
            }
        }
      }

      // Process non-guaranteed ids
      while (quantitySent < settings.maxQuantityPerOpen) {
        uint256 quantityOfRandomized = 1;
        uint256 classId = _pickRandomClass(settings.classProbabilities);
        lastOpen[_userAddress].push(_sendTokenWithClass(settings.groupingId, classId, _userAddress, quantityOfRandomized));
        quantitySent += quantityOfRandomized;
      }
      totalMinted += quantitySent;
    }

    emit cardPackOpened(_optionId, _userAddress, _amount, totalMinted);
  }

  function numOptions() external view returns (uint256) {
    return Option.length;
  }

  function numClasses(uint256 _groupingId) external view returns (uint256) {
    return Classes[_groupingId];
  }

  // Returns the tokenId sent to _toAddress
  function _sendTokenWithClass(
    uint256 _groupingId,
    uint256 _classId,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
     // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);


    uint256 tokenId = _pickRandomAvailableTokenIdForClass(_groupingId, _classId);
      
      //super fullback to a set ID
      if(tokenId == 0){
        tokenId = defaultNftId;
      }

      //nftContract.mint(_toAddress, tokenId, _amount, "0x0");

      // @dev some ERC1155 contract doesn't support the: _toAddress
      // we need to transfer it to the address after mint
      if(nftContract.balanceOf(address(this),tokenId) == 0 ){
        nftContract.mint(address(this), tokenId, _amount, "0x0");
      }
      
      nftContract.safeTransferFrom(address(this), _toAddress, tokenId, _amount, "0x0");
    

    return tokenId;
  }

  function _pickRandomClass(
    uint16[] memory _classProbabilities
  ) internal returns (uint256) {
    uint16 value = uint16(_random()%INVERSE_BASIS_POINT);
    // Start at top class (length - 1)
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint16 probability = _classProbabilities[i];
      if (value < probability) {
        return i;
      } else {
        value = value - probability;
      }
    }
    return 1;
  }

  function _pickRandomAvailableTokenIdForClass(
    uint256 _groupingId,
    uint256 _classId
  ) internal returns (uint256) {

    uint256[] memory tokenIds = classToTokenIds[_groupingId][_classId];
    require(tokenIds.length > 0, "NftPack#_pickRandomAvailableTokenIdForClass: NO_TOKENS_ASSIGNED");
 
    uint256 randIndex = _random()%tokenIds.length;
    // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);

      for (uint256 i = randIndex; i < randIndex + tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i % tokenIds.length];

        // first check if we have a balance in the contract
        if(nftContract.balanceOf(address(this),tokenId)  > 0 ){
          return tokenId;
        }

        if(allowMint){
          uint256 curSupply;
          uint256 maxSupply;
          if(internalMaxSupply[_groupingId][_classId][tokenId] > 0){
            maxSupply = internalMaxSupply[_groupingId][_classId][tokenId];
            curSupply = internalTokensMinted[_groupingId][_classId][tokenId];
          } else {
            maxSupply = nftContract.tokenMaxSupply(tokenId);
            curSupply = nftContract.tokenSupply(tokenId);
          }

          uint256 newSupply = curSupply + 1;
          if (newSupply <= maxSupply) {
            internalTokensMinted[_groupingId][_classId][tokenId] = internalTokensMinted[_groupingId][_classId][tokenId] + 1;
            return tokenId;
          }
        }


      }

      return 0;    
  }

  /**
   * @dev Take oracle return and generate a unique random number
   */
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encode(_randomness, _seed)));
    _seed += 1;
    return randomNumber;
  }


  /**
   * @dev emit a Warning if we're not approved to transfer nftAddress
   */
  function _checkTokenApproval() internal {
//    ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);
    if (!nftContract.isApprovedForAll(owner(), address(this))) {
      emit Warning("NftContract contract is not approved for trading collectible by:", owner());
    }
  }

  function _addTokenIdToClass(uint256 _groupingId, uint256 _classId, uint256 _tokenId, uint256 _amount) internal {
    classToTokenIds[_groupingId][_classId].push(_tokenId);
    internalMaxSupply[_groupingId][_classId][_tokenId] = _amount;
  }

  /**
   * @dev set the nft contract address callable by owner only
   */
  function setNftContract(ERC1155Tradable _nftAddress) public onlyOwner {
      nftContract = _nftAddress;
      emit SetNftContract(msg.sender, _nftAddress);
  }

  function setDefaultNftId(uint256 _nftId) public onlyOwner {
      defaultNftId = _nftId;
  }
  
  function resetOpening(address _toAddress) public onlyTeam {
    isOpening[_toAddress] = 0;
  }

  function setAllowMint(bool _allowMint) public onlyOwner {
      allowMint = _allowMint;
  }

  /**
   * @dev transfer LINK out of the contract
   */
/*  function withdrawLink(uint256 _amount) public onlyOwner {
      require(LINK.transfer(msg.sender, _amount), "Unable to transfer");
  }*/

  // @dev transfer NFTs out of the contract to be able to move into packs on other chains or manage qty
  function transferNft(ERC1155Tradable _nftContract, uint256 _id, uint256 _amount) public onlyOwner {
      _nftContract.safeTransferFrom(address(this),address(owner()),_id, _amount, "0x00");
  }
  /**
   * @dev update the link fee amount
   */
  function setLinkGas(uint32 _callbackGasLimit) public onlyOwner {
      callbackGasLimit = _callbackGasLimit;
      // emit SetLinkFee(msg.sender, _linkFee);
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
  }


  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
  }

  function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,IERC165) returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
}