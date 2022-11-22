//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./CollectionFactory.sol";

/**
* @title MetaTxCollectionFactory
* @dev This contract takes the logic of the Factory and implements the meta transaction functionality
*/
contract MetaTxCollectionFactory is CollectionFactory, ContextMixin, NativeMetaTransaction {

    string public constant name = "BeasyCollectionFactory"; 
    constructor (address collectibleLogic, address ethereumClaimRegistry, address collectibleClaimRegistry, address authClaimIssuer, address royaltyDistributorFactory, address chargeMaster) 
        CollectionFactory(collectibleLogic, ethereumClaimRegistry, collectibleClaimRegistry, authClaimIssuer, royaltyDistributorFactory, chargeMaster) {
        _initializeEIP712(name);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MetaTxCollection.sol";
import "./ChargeMaster.sol";
import "./RoyaltyDistributorFactory.sol";

/**
* @title CollectionFactory
* @dev This contract is a factory for Collectible contracts. It is used to create new Collectible contracts.
* It allows for custom logic to be used for each Collectible contract, and deploys contracts deterministically
* with minimal proxies drastically increasing gas efficiency vs. traditional factory patterns or manual deployments.
*/
contract CollectionFactory is Ownable {
    // ======== Immutable storage ========
    // address for the logic contract
    address private _defaultLogic;

    // ethereumClaim Registry contract address
    address private _ethereumClaimRegistry;

    // collectibleClaim Registry contract address
    address private _collectibleClaimRegistry;

    // collectibleClaim Registry contract address
    address private _authClaimIssuer;
        
    // Royalty distribution Factory contract address
    address private _royaltyDistributorFactory;

    // ChargeMaster contract address
    address private _chargeMaster;
    
    mapping(uint32 => address) private collections;

    mapping(string => bool) public collectionNameExists;

    uint32 private _collectionID;

    string private _baseURI;

    /** 
     * Emitted when an Collection is created reserving the corresponding token name.
     * @param collectionID of newly created Collecton
     * @param tokenAddress of newly created 
     */
    event CollectionBuilt(uint32 indexed collectionID,address tokenAddress, address tokenCreator);
    
    /** 
     * Emitted when Factory is deployed.
     * @param beaconAddress of factory
     */
    event CollectionFactoryCreated(address beaconAddress);

    /// Initializes implementation contract
    constructor(address collectibleLogic, address ethereumClaimRegistry, address collectibleClaimRegistry, address authClaimIssuer, address royaltyDistributorFactory, address chargeMaster) {
        _collectionID = 0;
        _defaultLogic = collectibleLogic;
        _ethereumClaimRegistry = ethereumClaimRegistry;
        _collectibleClaimRegistry = collectibleClaimRegistry;
        _authClaimIssuer = authClaimIssuer;
        _royaltyDistributorFactory = royaltyDistributorFactory;
        _chargeMaster = chargeMaster;
        emit CollectionFactoryCreated(_defaultLogic);
    }

    /**
     * @dev Updates the referenced contracts on the main library
     */
    function updateReferencedContracts(
        address collectibleLogic, address ethereumClaimRegistry, address collectibleClaimRegistry, address authClaimIssuer, address royaltyDistributorFactory, address chargeMaster
        ) public onlyOwner {
        _defaultLogic = collectibleLogic;
        _ethereumClaimRegistry = ethereumClaimRegistry;
        _collectibleClaimRegistry = collectibleClaimRegistry;
        _authClaimIssuer = authClaimIssuer;
        _royaltyDistributorFactory = royaltyDistributorFactory;
        _chargeMaster = chargeMaster;
    }

    /**
     * @dev Deploys a new collection
     * @param name_ collection name
     * @param symbol_ collection symbol as per standard ERC721
     * @param baseURI_ Base URI used to query tokens
     * @param contractURI_ IPFS CID of contract level metadata
     * @param operator address of the operator
     * @param salt bytes32 Salt to generate RoyaltyDistributor address
     * @return returns proxy address
     */
    function buildCollection(
        string memory name_, 
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address[] memory royaltyHolders,
        uint32[] memory royaltyHoldersPercentages,
        address operator,
        bytes32 salt
    ) external payable returns (address) {
        require(collectionNameExists[name_]==false, "CollectionFactory: There is already a registered collection with that name"); // This check avoids the edge for meta tx to ensure re-broadcast across collections when a user owns the same token at the same collection 712 nonce is not a problem
        collectionNameExists[name_]=true;
        ChargeMaster(_chargeMaster).processFee(_msgSender(), msg.value);
        ++_collectionID;
        address collectibleAddress = Clones.cloneDeterministic(_defaultLogic, salt);
        MetaTxCollection(payable(collectibleAddress)).initialize(name_, symbol_, baseURI_, contractURI_, _chargeMaster, operator, _msgSender());

        collections[_collectionID] = collectibleAddress;
        emit CollectionBuilt(_collectionID, collectibleAddress, _msgSender());

        createRoyaltyDistributor(
            collectibleAddress,
            royaltyHolders,
            royaltyHoldersPercentages,
            salt
        );
        return collectibleAddress;
    }

    /**
     * @dev Deploys a new custom collection with custom logic
     * @param name_ collection name
     * @param symbol_ collection symbol as per standard ERC721
     * @param baseURI_ Base URI used to query tokens
     * @param contractCID_ IPFS CID of contract level metadata
     * @param operator address of the operator
     * @param salt bytes32 Salt to generate RoyaltyDistributor address
     * @return returns proxy address
     */
    function buildCustomCollection(
        address customLogicAddress, 
        string memory name_, 
        string memory symbol_,
        string memory baseURI_,
        string memory contractCID_,
        address[] memory royaltyHolders,
        uint32[] memory royaltyHoldersPercentages,
        address operator,
        bytes32 salt
    ) external payable returns (address) {
        require(collectionNameExists[name_]==false, "CollectionFactory: There is already a registered collection with that name");
        collectionNameExists[name_]=true;
        ChargeMaster(_chargeMaster).processFee(_msgSender(), msg.value);
        ++_collectionID;
        address collectibleAddress = Clones.cloneDeterministic(customLogicAddress, salt);
        Collectible(collectibleAddress).initialize(name_, symbol_, baseURI_, contractCID_, _chargeMaster, operator);

        collections[_collectionID] = collectibleAddress;
        emit CollectionBuilt(_collectionID, collectibleAddress, _msgSender());

        createRoyaltyDistributor(
            collectibleAddress,
            royaltyHolders,
            royaltyHoldersPercentages,
            salt
        );
        return collectibleAddress;
    }
    
    /**
     * @dev get collection address by its ID
     * @param collectionID_ Collection id
     * @return returns collection address
     */
    function getTokenAddress(uint32 collectionID_) external view returns (address) {
        return collections[collectionID_];
    }

    /**
     * @dev returns _defaultLogic address
     * @return returns _defaultLogic address
     */
    function getLogic() public view returns (address){
        return _defaultLogic;
    }

    /**
     * @dev updates defaultLogic
     * @param newLogicAddress address Address of the new logic
     * @return returns true if address was updated
     */
    function setLogic(address newLogicAddress) public onlyOwner returns (bool){
        _defaultLogic = newLogicAddress;
        return true;
    }


    /**
     * @dev Creates a RoyaltyDistributor
     * @param percentages uint64 Total percentage of royalties
     * @param holders bytes32[] Address list and percentages of royalty holders
     * @param salt bytes32 Salt to generate RoyaltyDistributor address
     */
    function createRoyaltyDistributor(
        address collectionAddress, address[] memory holders, uint32[] memory percentages, bytes32 salt
        ) internal returns(address) {
        RoyaltyDistributorFactory rdf = RoyaltyDistributorFactory(_royaltyDistributorFactory);
        address royaltiesDistributorAddr = rdf.createRoyaltiesContract(collectionAddress, holders, percentages, salt);
        return royaltiesDistributorAddr;
    }

    /**
     * @dev Sets base URI
     * @param URI string Base URI for contract metadata
     */
    function setBaseURI(string memory URI) external onlyOwner {
        _baseURI = URI;
    }

    /**
     * @dev returns computed deterministic address based on given salt
     * @param salt used for address generation 
     * @return returns predicted address
     */
    function computeAddress(bytes32 salt) public view returns (address) {
        return Clones.predictDeterministicAddress(_defaultLogic, salt);
    }

    /**
     * @dev Sets authorization claim issuer address
     * @param address_ address Authorization claim issuer address
     */
    function setAuthClaimIssuer(address address_) external virtual onlyOwner {
        _authClaimIssuer = address_;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./Collectible.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */

/**
 * @title ContextMixin
 * @dev This contract provides methods to access the msg.sender and msg.data in a static context, it's used to recognized the original sender of a meta transaction
 */
abstract contract ContextMixin {

    /**
     * @dev This function is to be used instead of the msg.sender, it returns the original sender of the transaction, follows the context contract format
     */
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}


/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/EIP712Base.sol
 */

/**
* @title EIP712Base
* @dev Helper methods for signatures following the EIP712 standard.
*/
contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;


    /**
    * @dev supposed to be called once while initializing.
    * one of the contractsa that inherits this contract follows proxy pattern
    * so it is not possible to do this in a constructor
    */
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    /**
    * @dev set domain seperator for EIP712, used to avoid replay attacks across contracts in the same network
    */
    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    /**
    * @dev get domain seperator for EIP712
    */
    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    /**
    * @dev get chainID for EIP712, used to avoid replay attacks across different networks
    */
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev  Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/NativeMetaTransaction.sol
 */
/**
* @title NativeMetaTransaction
* @dev This contract holds the implementation of Native meta transactions to abstract complexity from the user
*/
contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
    * @dev Main function to be called by the gas payer to execute the meta transaction
    */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    /**
    * @dev Function to simplify nonce extraction for a specific user in a specific contract instance
    */
    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

/**
* @title MetaTxCollection
* @dev This contract takes the logic of the collection and implements the meta transaction functionality
*/
contract MetaTxCollection is Collectible, ContextMixin, NativeMetaTransaction {

    constructor () {
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Constructor replacement
     * @param name_ string Token name
     * @param symbol_ string Token symbol
     * @param baseURI_ string Token base URI
     * @param contractURI_ string Token contract level metadata URI
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address chargeMasterAddress_, 
        address operator_,
        address owner
    ) public {
        _initializeEIP712(name_);
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
        _contractURI = contractURI_;
        _transferOwnership(owner);
        _chargeMasterAddress = chargeMasterAddress_;
        _operator = operator_;
    }

}

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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RoyaltyDistributor.sol";

/**
* @title RoyaltyDistributorFactory
* @dev This contract is used to deploy RoyaltyDistributor contracts
*/
contract RoyaltyDistributorFactory is Ownable {
    // ======== Immutable storage ========
    // address for the logic contract
    address private _royaltyDistributorLogic;

    mapping(address => address) private _collectionToRoyaltyDistributor;

    /** 
     * Emitted when an a new royalty contract is created.
     * @param collectionAddress of newly created Collecton
     * @param tokenAddress of newly created 
     */
    event RoyaltyDistributorCreated(address collectionAddress, address tokenAddress);
    
    /** 
     * Emitted when Factory is deployed.
     * @param logic of RoyaltyDistributor
     */
    event RoyaltyDistributorFactoryCreated(address logic);

    /// Initializes implementation contract
    constructor(address royaltyDistributorLogic) {
        _royaltyDistributorLogic = royaltyDistributorLogic;
        emit RoyaltyDistributorFactoryCreated(_royaltyDistributorLogic);
    }

    /**
     * @dev Creates a new royalty contract asociated to a collection
     * @param collectionAddress address collection address
     * @param holders address[] of the royalty holders
     * @param percentages uint32[] of each royalty holder
     * @param salt bytes32 for deterministic address creation
     * @return returns proxy address
     */
    function createRoyaltiesContract(address collectionAddress, address[] memory holders, uint32[] memory percentages, bytes32 salt) external returns (address) {
        if (holders.length > 0) {
            address royaltyDistributorAddress = Clones.cloneDeterministic(_royaltyDistributorLogic, salt);
            RoyaltyDistributor(payable(royaltyDistributorAddress)).initialize(collectionAddress, holders, percentages);
            _collectionToRoyaltyDistributor[collectionAddress] = royaltyDistributorAddress;
            emit RoyaltyDistributorCreated(collectionAddress, royaltyDistributorAddress);
            return royaltyDistributorAddress;
        } else {
            return address(0);
        }
    }
    
    /**
     * @dev get collection address by its ID
     * @param collectionAddress address of collection 
     * @return returns RoyaltyContractAddress
     */
    function getRoyaltyContractAddress(address collectionAddress) external view returns (address) {
        return _collectionToRoyaltyDistributor[collectionAddress];
    }

    /**
     * @dev returns beacon address
     * @return returns beacon address
     */
    function getImplementation() public view returns (address){
        return address(_royaltyDistributorLogic);
    }

    /**
     * @dev returns computed deterministic address based on given salt
     * @param salt used for address generation 
     * @return returns predicted address
     */
    function computeAddress(bytes32 salt) public view returns (address) {
        return Clones.predictDeterministicAddress(_royaltyDistributorLogic, salt);
    }

}

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ChargeMaster.sol";

/**
 * @title Collectible
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation and offers additional functionality
 * like minting, burning, creation, enumeration and token URI management.
 */
contract Collectible is Ownable, Initializable, IERC165, IERC721, IERC721Metadata {
    using Strings for uint256;
    using Address for address;

/******************************************************************************
 * 
 *                            !!! ATTENTION!!!!
 * 
 *               NEVER EVER ADD NEW FIELDS ABOVE EXISTING ONE
 *           THIS WILL RUINE DEPLOYED PROXY CONTRACTS BEYOND REPAIR
 *
 *     See documentation on how proxy contract works to figure out why
 *
 *****************************************************************************/

    // *** ERC721 ***
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Base token URI
    string internal _baseTokenURI;


    // *** ERC721Enumerable ***
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;


    // *** Business logic ***
    // Maping from collectible ID to IPFS CID
    mapping(uint256 => string) private _collectibleCID;

    // Mapping from collectible ID to list of minted token IDs
    mapping(uint256 => uint256[]) private _collectibleTokens;
    
    // Mapping from token ID to index of the collectible tokens list
    mapping(uint256 => uint256) private _collectibleTokensIndex;

    // Claim name for user role
    bytes32 private constant CL_COLLECTIBLE_CREATOR = keccak256("X-Beasy-Collectible-Creator");

    // Operator address
    address internal _operator;

    // Contract level metadata URI
    string internal _contractURI;

    // ChargeMaster contract address
    address internal _chargeMasterAddress;

// ================ ADD NEW FIELDS STRICTLY BELOW THIS LINE ===================


/******************************************************************************
 *
 * Implementation of ERC165
 *
 *****************************************************************************/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || interfaceId == type(IERC165).interfaceId
        ;
    }

/******************************************************************************
 *
 * Implementation of Initializable
 *
 *****************************************************************************/

    /**
     * @dev Constructor replacement
     * @param name_ string Token name
     * @param symbol_ string Token symbol
     * @param baseURI_ string Token base URI
     * @param contractURI_ string Token contract level metadata URI
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address chargeMasterAddress_, 
        address operator_ 
    ) public virtual {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
        _contractURI = contractURI_;
        _transferOwnership(_msgSender());
        _chargeMasterAddress = chargeMasterAddress_;
        _operator = operator_;
    }
/* 
    constructor(
        string memory name_,
        string memory symbol_,
        string memory URI_,
        address ethereumClaimRegistry_,
        address collectibleClaimRegistry_,
        address authClaimIssuer_
    ) {
        initialize(name_, symbol_, URI_, ethereumClaimRegistry_, collectibleClaimRegistry_, authClaimIssuer_);
    }
*/

/******************************************************************************
 *
 * Implementation of ERC721
 *
 *****************************************************************************/

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

/******************************************************************************
 *
 * Implementation of ERC721Metadata
 *
 *****************************************************************************/

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return collectibleURI(tokenId & ~uint256(0xffffffff));
    }

    /**
     * @dev Opensea collection metadata.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

/******************************************************************************
 *
 * Various configuration methods
 *
 *****************************************************************************/

    /**
     * @dev Sets base token URI
     * @param URI string base URI
     */
    function setBaseURI(string memory URI) external virtual onlyOperatorOrOwner {
        _baseTokenURI = URI;
    }

    /**
     * @dev Sets contract URI for contract level metadata
     * @param URI string contract URI
     */
    function setContractURI(string memory URI) external virtual onlyOperatorOrOwner {
        _contractURI = URI;
    }

    
    /**
     * @dev Sets default operator address
     * @param address_ address Operator address
     */
    function setOperator(address address_) external virtual onlyOperatorOrOwner {
        _operator = address_;
    }

    /**
     * @dev Sets default operator address
     * @param address_ address Operator address
     */
    function setOwner(address address_) external virtual onlyOperatorOrOwner {
        _transferOwnership(address_);
    }

/******************************************************************************
 *
 * Business logic
 *
 *****************************************************************************/

    event collectible(uint256 indexed collectibleId, string CID, address creator);
    event collectibleDeleted(uint256 indexed collectibleId, string CID);
    event ContributorSet(uint256 indexed collectibleId, bytes32 value);

    /**
     * @dev Prevents method from being called from anyone except operator
     */
    modifier onlyOperatorOrOwner() {
        require(_msgSender() == _operator || _msgSender() == owner(), "Beasy: You are not an operator or the collection owner");
        _;
    }

    /**
     * @dev Mints a token within specified collectible
     * @param to address Initial owner of all them items of the collectible
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @param data bytes
     * @return uint256 token ID
     */
    function safeMint (
        address to,
        uint256 collectibleId,
        bytes memory data
    ) virtual onlyOperatorOrOwner public returns(uint256) {
        require((collectibleId & 0xffffffff) == 0, "Beasy: Malformed collectible ID");
        require(bytes(_collectibleCID[collectibleId]).length != 0, "Beasy: Minting token of nonexistent collectible");

        uint256 tokenId = collectibleId + _collectibleTokens[collectibleId].length;

        _collectibleTokens[collectibleId].push(tokenId);
        
        _safeMint(to, tokenId, data);
        return tokenId;
    }

    /**
     * @dev Mints a token within specified collectible
     * @param to address Initial owner of all them items of the collectible
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @return uint256 token ID
     */
    function safeMint (address to, uint256 collectibleId) virtual public returns(uint256) {
         return safeMint(to, collectibleId, "");
    }

    /**
     * @dev Burns existing token
     * @param tokenId uint256 token ID to burn
     */
    function burn(uint256 tokenId) virtual public {
        _burn(tokenId);
    }

    /**
     * @dev Creates a collectible with specified attributes
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @param CID string IPFS CID for collectible metadata
     * @param contributors bytes32[] List of contributor records
     */
    function createCollectible(uint256 collectibleId, string memory CID, bytes32[] memory contributors) virtual onlyOperatorOrOwner public payable returns(uint256) { // FIXME https://blog.soliditylang.org/2021/04/21/custom-errors/  ALSO THIS IS INHERITED FROM DEFAULT COLLECTION
        ChargeMaster(_chargeMasterAddress).processFee(_msgSender(), msg.value);
        require((collectibleId & 0xffffffff) == 0, "Beasy: Malformed collectible ID");
        require(bytes(_collectibleCID[collectibleId]).length == 0, "Beasy: Collectible already exist");

        _collectibleCID[collectibleId] = CID;
        emit collectible(collectibleId, CID, _msgSender());
        if(_operator != _msgSender()) {
            setApprovalForAll(_operator, true); 
        }
        return collectibleId;
    }

    /**
     * @dev Deletes a collectible with specified attributes
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     */
    function deleteCollectible(uint256 collectibleId, string memory CID) virtual onlyOperatorOrOwner public returns(uint256) {
        require((collectibleId & 0xffffffff) == 0, "Beasy: Malformed collectible ID");
        require(bytes(_collectibleCID[collectibleId]).length != 0, "Beasy: Collectible does not exist");
        require(_collectibleTokens[collectibleId].length == 0, "Beasy: Cant delete collectibles which have been minted to users");

        _collectibleCID[collectibleId] = "";
        emit collectibleDeleted(collectibleId, CID);
        return collectibleId;
    }
    

    /**
     * @dev Returns total number of tokens of particular collecible
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @return uint256 number of tokens
     */
    function tokensOfCollectible(uint256 collectibleId) virtual public view returns(uint256) {
        return _collectibleTokens[collectibleId].length;
    }
    
    /**
     * @dev Returns ID of a token by index
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @param index uint256 token index
     * @return uint256 token ID
     */
    function tokenOfCollectibleByIndex(uint256 collectibleId, uint256 index) virtual public view returns(uint256) {
        return _collectibleTokens[collectibleId][index];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function collectibleURI(uint256 collectibleId) public view virtual returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _collectibleCID[collectibleId])) : "";
    }
    
    /**
     * @dev Changes CID of an existing collectible
     * @param collectibleId uint256 ID of the collectible (only 224 most significat bits are used)
     * @param CID string IPFS CID for collectible metadata
     */
    function updateCID(uint256 collectibleId, string memory CID) public virtual onlyOperatorOrOwner {
        require((collectibleId & 0xffffffff) == 0, "Beasy: Malformed collectible ID");
        require(bytes(_collectibleCID[collectibleId]).length != 0, "Beasy: Collectible not yet exist");
        require(bytes(CID).length != 0, "Beasy: Empty CID is not allowed");
        _collectibleCID[collectibleId] = CID;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./lib/ERC780.sol";

/**
 * @title EthereumClaimRegistry
 * @dev This contract implements a generic registry for claims on Ethereum addresses.
 */
contract EthereumClaimRegistry is ERC780 {}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title RoyaltyDistributor
* @dev This contract is used to distribute royalties to the creators of the NFTs.
* It allows the owner to set the royalties and the beneficiaries, this contract receives all the payments and distributes them to the beneficiaries
*/
contract RoyaltyDistributor is Initializable {
    
    struct Holder {
        address holderAddr;
        uint32 percentage;
    }
    
    // Royalty holders with percent
    Holder[] private _holders;

    // Collectible ID
    address private _collectionAddress;

    // Total percentage of royalties
    uint32 private _totalPercent;

    event RoyaltyDistributorInit(address indexed collectionAddress);
    event RoyaltyDistributorWithdraw(address indexed collectionAddress, address indexed holder, uint256 amount);

    /**
     * @dev Constructor replacement
     * @param collectionAddress address address of the collection
     * @param holders address[] array of holder addresses
     * @param percentages uint32[] array of percentages for each address
     */
    function initialize(address collectionAddress, address[] memory holders, uint32[] memory percentages) public initializer {
        require(holders.length==percentages.length, "RoyaltyDistributor: number of holders must match the number of percentages");
        _collectionAddress = collectionAddress;
        for (uint i = 0; i < holders.length; i++) {
            _holders.push(Holder(holders[i], percentages[i]));
            _totalPercent = _totalPercent + percentages[i];
        }
        emit RoyaltyDistributorInit(collectionAddress);
    }

    /**
     * @dev Distribute and withdraw all funds of native crypto to the holders
     */
    function withdraw() public {
        uint256 balance = address(this).balance;
        uint256 totalAmount = balance * (100 / _totalPercent);
        for (uint i = 0; i < _holders.length; i++) {
            address holder = _holders[i].holderAddr;
            uint32 percent = _holders[i].percentage;
            uint256 amount = (totalAmount / 100) * percent;
            payable (holder).transfer(amount);
            emit RoyaltyDistributorWithdraw(_collectionAddress, holder, amount);
        }
    }

    /**
     * @dev Distribute and withdraw all funds of provided token to the holders
     * @param tokenAddress address address of the token to be withdrawn
     */
    function withdrawToken(address tokenAddress) public {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 totalAmount = balance * (100 / _totalPercent);
        for (uint i = 0; i < _holders.length; i++) {
            address holder = _holders[i].holderAddr;
            uint32 percent = _holders[i].percentage;
            uint256 amount = (totalAmount / 100) * percent;
            token.transfer(holder, amount);
            emit RoyaltyDistributorWithdraw(_collectionAddress, holder, amount);
        }
    }


    /**
     * @dev gets funds of native crypto in this contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
        
    /**
     * @dev gets funds of native crypto in this contract
     * @param tokenAddress address address of the token to be withdrawn
     */
    function getBalanceToken(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    /**
     * @dev gets contract where royalties are from
     */
    function getCollectionAddress() public view returns (address) {
        return _collectionAddress;
    }

    /**
     * @dev gets total royalties of contract
     */
    function getTotalRoyalties() public view returns (uint32) {
        return _totalPercent;
    }
    

    /**
     * @dev gets total royalties of contract
     * @param index uint256 index in the structure containing a holder's data
     */
    function getHolderData(uint256 index) public view returns (Holder memory) {
        return _holders[index];
    }

    /**
     * @dev Received funds and made withdraw to holders
     */
    receive() external payable {
        //withdraw(); This doesn't work gas limit check out at https://docs.soliditylang.org/en/v0.8.12/contracts.html#receive-ether-function
    }
}

// SPDX-License-Identifier: MIT
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