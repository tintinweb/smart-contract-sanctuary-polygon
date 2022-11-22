// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EthereumClaimRegistry.sol";


/**
 * @title ChargeMaster
 * @dev This contract is deployed as a single instance and controls all payments to be received by the operator, 
 * it manages the creation of accounts which can have a number of addresses and belong to tiers which store the information
 * Other contracts can query this contract to determine if a payment is required and if so, automate the payment process
 */
contract ChargeMaster is Ownable {

    /**
    * @title Tier
    * @dev Definition of a tier, including prices for different cuts, how many transactions need to be triggered 
    * to jump to the next tier and the number of addresses that can be registered to that account
    */
    struct Tier {
        uint256 price0; //Price to be paid before reaching a cut
        uint256 price1; //Price to be paid while in cut1
        uint256 price2;
        uint256 price3;

        uint256 cut1; //Number of tx to reach t1
        uint256 cut2;
        uint256 cut3;

        uint256 addrNumber; //Number of addresses allowed in account
    }

    /**
    * @title Tier
    * @dev Definition of an account, n of addresses asociated to it, tx done, and tier it belongs to
    */
    struct Account {
        uint256 nRegisteredAddresses; 
        uint256 tierID; 
        uint256 txNumber;
    }

    // Account to receive payments
    address public receiver; 

    // Operator address
    address private _operator;

    // Map of addresses pointing to their accountID
    mapping (address => bytes32) public accountIDs;

    // Map of accountIDs pointing to their accounts
    mapping (bytes32 => Account) public account; // to establish a many to one relationship

    // Map of Tiers pointing to the tier information
    mapping (uint256 => Tier) public tier; // to establish a many to one relationship

    // Total accounts registered on the platform
    uint256 public accountsNumber;

    // Price an unregistered user pays for tx
    uint256 public unregisteredFee = 0;

    // Ethereum Claim Registry contract
    EthereumClaimRegistry private _ethereumClaims;


    //Error thrown when processing fees don't match
    //error FeeAndMsgValueDontMatch(uint256 fee, uint256 sent);

    /**
     * @dev Prevents method from being called from anyone except operator
     */
    modifier onlyOperator() {
        require(tx.origin == _operator, "Beasy: You are not an operator");
        _;
    }

    constructor(
        uint256 p0, uint256 p1, uint256 p2, uint256 p3, uint256 c1, uint256 c2, uint256 c3, uint256 accsN, address rcv, address ethereumClaims_, address operator_
        ) Ownable(){
        // Gotta reserve tier 0 for no tier
        tier[1] = Tier(p0, p1, p2, p3, c1, c2, c3, accsN);
        accountsNumber=0;
        receiver = rcv;
        _ethereumClaims = EthereumClaimRegistry(ethereumClaims_);
        _operator = operator_;
        _operator = operator_;
    }

    /**
     * @dev updates the receiver of tx
     * @param newReceiver to receive tx
     * @return returns ok if tx is successful
     */
    function updateReceiver(address newReceiver) public onlyOperator returns (bool){
        receiver = newReceiver;
        return true;
    }

    /**
     * @dev updates the operator
     * @param newOperator new operator address
     * @return returns ok if tx is successful
     */
    function updateOperator(address newOperator) public onlyOperator returns (bool){
        _operator = newOperator;
        return true;
    }

    /**
     * @dev updates the fees unregistered users are asked to pay
     * @param newFee new fee to be used
     * @return returns ok if tx is successful
     */
    function updateUnregisteredFee(uint256 newFee) public onlyOperator returns (bool){
        unregisteredFee = newFee;
        return true;
    }

    /**
     * @dev Creates a new tier
     * @param p0 ... p3 prices for the new tier
     * @param c1 ... c3 cuts for the tiers
     * @param addrN number of addresses allowed in new tier
     * @param tierID ID for the new tier
     * @return returns ok if tx is successful
     */
    function createTier(
        uint256 p0, uint256 p1, uint256 p2, uint256 p3, uint256 c1, uint256 c2, uint256 c3, uint256 addrN, uint256 tierID
        ) public onlyOperator returns (bool){
        require(tierID!=0, "ChargeMaster: Cant's create tier 0");
        require(tier[tierID].addrNumber==0, "ChargeMaster: Tier already exists");
        tier[tierID] = Tier(p0, p1, p2, p3, c1, c2, c3, addrN);
        return true;
    }

    /**
     * @dev Updates a tier
     * @param p0 ... p3 prices for tier
     * @param c1 ... c3 cuts for tiers
     * @param addrN number of addresses allowed in tier
     * @param tierID ID for the tier
     * @return returns ok if tx is successful
     */
    function updateTier(
        uint256 p0, uint256 p1, uint256 p2, uint256 p3, uint256 c1, uint256 c2, uint256 c3, uint256 addrN, uint256 tierID
        ) public onlyOperator returns (bool){
        require(tier[tierID].addrNumber!=0, "ChargeMaster: Tier doesn't exist");
        tier[tierID] = Tier(p0, p1, p2, p3, c1, c2, c3, addrN);
        return true;
    }

    /**
     * @dev Registers an address to a new account
     * @param user address of the user to be added as the first in account
     * @param tierID TierID of the user
     * @return returns ok if tx is successful
     */
    function registerUser(address user, uint256 tierID, bytes32 role, bytes32 accountID) public onlyOperator returns (bool){ 
    //Can be built into the tx where we assign users a role
        require(accountIDs[user]==0, "ChargeMaster: User is already in an account");

        accountsNumber++;
        accountIDs[user] = accountID;
        account[accountID] = Account(1, tierID, 0);

        return true;
    }

    /**
     * @dev Updates the tier of an account
     * @param accountID AccountID to be updated
     * @param tierID new tier for the account
     * @return returns ok if tx is successful
     */
    function changeAccountTier(bytes32 accountID, uint256 tierID) public onlyOperator returns (bool){ 
        account[accountID].tierID =tierID;
        return true;
    }

    /**
     * @dev Adds a new user to the msg.sender's account
     * @param user address of the user to be added to the existing account
     * @return returns ok if tx is successful
     */
    function addUserToAccountAdmin(address user, bytes32 accountID) public onlyOperator returns (bool){ //Could have a version for owner
        require(accountIDs[user]==0, "ChargeMaster: User is already in an account");

        Account storage msgSenderAccount = account[accountID];
        uint256 maxAddr = tier[msgSenderAccount.tierID].addrNumber;
        
        msgSenderAccount.nRegisteredAddresses++;
        require(msgSenderAccount.nRegisteredAddresses <= maxAddr, "ChargeMaster: Maximum number of addresses registered to your account, updgrade your tier to have more accounts");

        accountIDs[user] = accountID;

        return true;
    }

        /**
     * @dev Deletes a user to the msg.sender's account
     * @param user address of the user to be deleted to the existing account
     * @return returns ok if tx is successful
     */
    function deleteUserToMyAccount(address user) public returns (bool){ //Any address can delete any other address, maybe want to restrict this?

        bytes32 msgSenderAccID = accountIDs[msg.sender];
        bytes32 userAccID = accountIDs[user];
        require(msgSenderAccID==userAccID, "ChargeMaster: Can't delete users outside of your account");

        Account storage msgSenderAccount = account[msgSenderAccID];

        accountIDs[user] = 0;
        msgSenderAccount.nRegisteredAddresses--;

        return true;
    }

        /**
     * @dev Adds a new user to the msg.sender's account
     * @param user address of the user to be added to the existing account
     * @return returns ok if tx is successful
     */
    function addUserToMyAccount(address user) public returns (bool){ //Could have a version for owner
        require(accountIDs[user]==0, "ChargeMaster: User is already in an account");

        bytes32 msgSenderAccID = accountIDs[msg.sender];
        Account storage msgSenderAccount = account[msgSenderAccID];
        uint256 maxAddr = tier[msgSenderAccount.tierID].addrNumber;
        
        msgSenderAccount.nRegisteredAddresses++;
        require(msgSenderAccount.nRegisteredAddresses <= maxAddr, "ChargeMaster: Maximum number of addresses registered to your account, updgrade your tier to have more accounts");

        accountIDs[user] = msgSenderAccID;
        return true;
    }


    /**
     * @dev Return number of tx done by user 
     * @return number of tx done by user 
     */
    function getTxNumber(address user) public view returns (uint256){
        return account[accountIDs[user]].txNumber;
    }

    /**
     * @dev Return Fees to be paid by user
     * @return Fees to be paid by user
     */
    function getFee(address user) public view returns (uint256){
        if(accountIDs[user]==0){
            return unregisteredFee;
        }
        Account memory userAccount= account[accountIDs[user]];
        uint256 userTxN= userAccount.txNumber;
        Tier memory userTier= tier[userAccount.tierID];
        if(userTxN<userTier.cut1){
            return userTier.price0;
        }
        else if (userTxN>=userTier.cut1&&userTxN<userTier.cut2){
            return userTier.price1;
        }
        else if (userTxN>=userTier.cut2&&userTxN<userTier.cut3){
            return userTier.price2;
        }
        return userTier.price3;
    }

    /**
     * @dev Checks if the fee in the tx matches the fee to be paid by user and increases the tx counter for the user
     * @return true if correct
     */
    function processFee(address user, uint256 msgValue) payable public returns (bool){
        uint256 txF = getFee(user);
        require(txF==msgValue, "ChargeMaster: msg.value doesn't match the required fee");
        /*if(txF!=msg.value){
            revert FeeAndMsgValueDontMatch({
                fee: txF,
                sent: msg.value
            });
        }*/
        (bool sent, bytes memory data) = receiver.call{value: msg.value}("");
        require(sent, "ChargeMaster: Failed to send Ether");
        account[accountIDs[user]].txNumber++;
        return true;
    }

    /**
     * @dev Returns address of the operator
     * @return address of the operator
     */
    function getOperator() public view returns (address){
        return _operator;
    }

    /**
     * @dev Returns address of the claims contract
     * @return address of the claims contract
     */
    function getClaimsContract() public view returns (address){
        return address(_ethereumClaims);
    }

    /**
     * @dev Updates the address of the claims contract
     * @param claimsAddress address to be updated to
     * @return bool true if success
     */
    function setClaimsContract(address claimsAddress) public onlyOwner returns (bool){
        _ethereumClaims = EthereumClaimRegistry(claimsAddress);
        return true;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./lib/ERC780.sol";

/**
 * @title EthereumClaimRegistry
 * @dev This contract implements a generic registry for claims on Ethereum addresses.
 */
contract EthereumClaimRegistry is ERC780 {}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ERC780 {

    mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt);

    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt);

    // create or update clams
    function setClaim(address subject, bytes32 key, bytes32 value) public {
        registry[msg.sender][subject][key] = value;
        emit ClaimSet(msg.sender, subject, key, value, block.timestamp);
    }

    function setSelfClaim(bytes32 key, bytes32 value) public {
        setClaim(msg.sender, key, value);
    }

    function getClaim(address issuer, address subject, bytes32 key) public view returns(bytes32) {
        return registry[issuer][subject][key];
    }

    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(msg.sender == issuer);
        delete registry[issuer][subject][key];
        emit ClaimRemoved(msg.sender, subject, key, block.timestamp);
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