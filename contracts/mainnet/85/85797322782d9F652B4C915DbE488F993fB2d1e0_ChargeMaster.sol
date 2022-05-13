// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EthereumClaimRegistry.sol";


/**
 * @title ChargeMaster
 * @dev Keep track of tx done by users and cost of tx
 */
contract ChargeMaster is Ownable {

    // Definition of a tier, including prices, cuts and total accounts
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

    // Definition of an account, n of addresses asociated to it, tx done, and tier it belongs to
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