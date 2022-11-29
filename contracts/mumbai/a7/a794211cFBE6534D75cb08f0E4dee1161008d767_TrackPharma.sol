// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Types.sol";

/**
 * @title Accounts
 * @author TEAM201
 * @dev This program is the library manages addresses and roles played by each account
 */

contract Accounts {
   
    // MAPPINGS
    mapping(address => Types.AccountDetails) internal accounts;
    mapping(address => Types.AccountDetails[])
        internal manufacturerDistributorsList;
    mapping(address => Types.AccountDetails[])
        internal distributorRetailersList;
    mapping(address => Types.AccountDetails[]) internal retailerCustomersList;

    // EVENTS
    event NewAccount(string name, string email, Types.AccountRole role);
    event LostAccount(string name, string email, Types.AccountRole role);

    // MODIFIERS

    // check if the account role is a manufacturer
    modifier onlyManufacturer() {
        require(msg.sender != address(0), "Sender's address is Empty");
        require(
            accounts[msg.sender].accountId != address(0),
            "account's address is Empty"
        );
        require(
            Types.AccountRole(accounts[msg.sender].role) ==
                Types.AccountRole.Manufacturer,
            "Only manufacturer can add"
        );
        _;
    }

    modifier notAccountZero() {
        require(msg.sender != address(0), "Sender's address is Empty");
        _;
    }

    // SPECIAL FUNCTIONS

    //  this function checks if account has the role
    function has(Types.AccountRole role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return (accounts[account].accountId != address(0) &&
            accounts[account].role == role);
    }

    // create account and assign users a role
    function add(Types.AccountDetails memory account) internal {
        require(
            account.accountId != address(0),
            "Account should not be account 0"
        );
        require(
            !has(account.role, account.accountId),
            "cannot have same account with the same role"
        );
        accounts[account.accountId] = account;
        emit NewAccount(account.name, account.email, account.role);
    }

    // get account details from their address
    function get(address account)
        internal
        view
        returns (Types.AccountDetails memory)
    {
        require(account != address(0));
        return accounts[account];
    }


    // Remove account from a role
    function remove(Types.AccountRole role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        string memory name_ = accounts[account].name;
        string memory email_ = accounts[account].email;
        delete accounts[account];
        emit LostAccount(name_, email_, role);
    }  


// check if the account exists or not
  function isPartyExists(address account) internal view returns (bool) {
        bool existing_;
        if (account == address(0)) return existing_;
        if (accounts[account].accountId != address(0)) existing_ = true;
        return existing_;
    }


// OTHER FUNCTIONS 

//  add account to current correspondence list
    function addparty(Types.AccountDetails memory account, address myAccount)
        internal
    {
        require(myAccount != address(0));
        require(account.accountId != address(0));

        if (
            get(myAccount).role == Types.AccountRole.Manufacturer &&
            account.role == Types.AccountRole.Distributor
        ) {
            // Only manufacturers are allowed to add distributors
            manufacturerDistributorsList[myAccount].push(account);
            add(account); // To add user to global list
        } else if (
            get(myAccount).role == Types.AccountRole.Distributor &&
            account.role == Types.AccountRole.Retailer
        ) {
            // Only distributors are allowed to add retailers
            distributorRetailersList[myAccount].push(account);
            add(account); // To add user to global list
        } else if (
            get(myAccount).role == Types.AccountRole.Retailer &&
            account.role == Types.AccountRole.Customer
        ) {
            // Only retailers are allowed to add customers
            retailerCustomersList[myAccount].push(account);
            add(account); // To add user to global list
        } else {
            revert("Not valid operation");
        }
    }

//    get list of all the account added by current account
    function getMyPartyList(address user_id)
        internal
        view
        returns (Types.AccountDetails[] memory accountsList_)
    {
        require(user_id != address(0), "user_id is empty");
        if (get(user_id).role == Types.AccountRole.Manufacturer) {
            accountsList_ = manufacturerDistributorsList[user_id];
        } else if (get(user_id).role == Types.AccountRole.Distributor) {
            accountsList_ = distributorRetailersList[user_id];
        } else if (get(user_id).role == Types.AccountRole.Retailer) {
            accountsList_ = retailerCustomersList[user_id];
        } else {
            // Customer flow is not supported yet
            revert("Not valid operation");
        }
    }

    //  get account details
    function getPartyDetails(address user_id)
        internal
        view
        returns (Types.AccountDetails memory)
    {
        require(user_id != address(0));
        require(get(user_id).accountId != address(0));
        return get(user_id);
    }


} // END OF CONTRACT

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Types.sol";

/**
 * @title Items
 * @author TEAM201
 * @dev A Library for items management
 */

contract Items {
    Types.Item[] internal items;
    mapping(string => Types.Item) internal item;
    mapping(address => string[]) internal accountLinkedItems;
    mapping(string => Types.ItemHistory) internal itemHistory;

    // The Events

    event NewItem(
        string name,
        string manufacturerName,
        string barcodeId,
        uint256 manufacturedDate,
        uint256 expiringDate
    );
    event ItemOwnershipTransfer(
        string name,
        string manufacturerName,
        string barcodeId,
        string buyerName,
        string buyerEmail
    );

    // MODIFIERS

    // Check if item already exists
    modifier itemExists(string memory Id) {
        require(!compareStrings(item[Id].barcodeId, ""));
        _;
    }

    // Check if item does not exists
    modifier itemNotExists(string memory Id) {
        require(compareStrings(item[Id].barcodeId, ""));
        _;
    }

    // SPECIAL FUNCTIONS

    // compare string operatins, this function is a little expensive to run
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // remove item from current list one sold i.e transferring the ownership
    function transferOwnership(
        address sellerId,
        address buyerId,
        string memory itemId
    ) internal {
        accountLinkedItems[buyerId].push(itemId);
        string[] memory sellerItems_ = accountLinkedItems[sellerId];
        uint256 matchIndex_ = (sellerItems_.length + 1);
        for (uint256 i = 0; i < sellerItems_.length; i++) {
            if (compareStrings(sellerItems_[i], itemId)) {
                matchIndex_ = i;
                break;
            }
        }
        assert(matchIndex_ < sellerItems_.length); // Match found
        if (sellerItems_.length == 1) {
            delete accountLinkedItems[sellerId];
        } else {
            accountLinkedItems[sellerId][matchIndex_] = accountLinkedItems[
                sellerId
            ][sellerItems_.length - 1];
            delete accountLinkedItems[sellerId][sellerItems_.length - 1];
            accountLinkedItems[sellerId].pop();
        }
    }

    // OTHER FUNCTIONS

    // get all item list linked to an account
    function getAccountItems() internal view returns (Types.Item[] memory) {
        string[] memory _id = accountLinkedItems[msg.sender];
        Types.Item[] memory _item = new Types.Item[](_id.length);
        for (uint256 i = 0; i < _id.length; i++) {
            _item[i] = item[_id[i]];
        }
        return _item;
    }

    // get specific item linked to an account
    function getSpecificItem(string memory barcodeId)
        internal
        view
        returns (Types.Item memory, Types.ItemHistory memory)
    {
        return (item[barcodeId], itemHistory[barcodeId]);
    }

    // Add new item to the item list
    function addItem(Types.Item memory _item, uint256 currentTime_)
        internal
        itemNotExists(_item.barcodeId)
    {
        require(_item.manufacturer == msg.sender, "Only manufacturer can add");
        items.push(_item);
        item[_item.barcodeId] = _item;
        itemHistory[_item.barcodeId].manufacturer = Types.AccountTransactions({
            transactionAddress: msg.sender,
            timestamp: currentTime_
        });
        accountLinkedItems[msg.sender].push(_item.barcodeId);
        emit NewItem(
            _item.name,
            _item.manufacturerName,
            _item.barcodeId,
            _item.manufacturedDate,
            _item.expiringDate
        );
    }

    // Sell item i.e transfer the ownership to another user/account
    function sell(
        address partyId,
        string memory barcodeId,
        Types.AccountDetails memory _party,
        uint256 currentTime_
    ) internal itemExists(barcodeId) {
        Types.Item memory _item = item[barcodeId];

        // Update to history of an item
        Types.AccountTransactions memory AccountTransactions_ = Types
            .AccountTransactions({
                transactionAddress: _party.accountId,
                timestamp: currentTime_
            });
        if (Types.AccountRole(_party.role) == Types.AccountRole.Distributor) {
            itemHistory[barcodeId].distributor = AccountTransactions_;
        } else if (
            Types.AccountRole(_party.role) == Types.AccountRole.Retailer
        ) {
            itemHistory[barcodeId].retailer = AccountTransactions_;
        } else if (
            Types.AccountRole(_party.role) == Types.AccountRole.Customer
        ) {
            itemHistory[barcodeId].customers.push(AccountTransactions_);
        } else {
            // Outside the scope of this work
            revert("Not valid operation");
        }
        transferOwnership(msg.sender, partyId, barcodeId); // Transfer of ownership between accounts 

        // Emit event
        emit ItemOwnershipTransfer(
            _item.name,
            _item.manufacturerName,
            _item.barcodeId,
            _party.name,
            _party.email
        );
    }
} // END OF CONTRACT

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



import "./Items.sol";
import "./Accounts.sol";

/**
 * @title TrackPharma
  * @author TEAM201
  * @dev Transparently track the path of items along the supply chain
 */

contract TrackPharma is Accounts, Items {
   

//  create new account on creation and set role to Manufacturer
    constructor(string memory _name, string memory _email) {
        Types.AccountDetails memory _acctDetails = Types.AccountDetails({
            role: Types.AccountRole.Manufacturer,
            accountId: msg.sender,
            name: _name,
            email: _email
        });
        add(_acctDetails);
    }

// get list of all the items added per account
 function getAllItems() public view returns (Types.Item[] memory) {
        return items;
    }

// get account items 
function getMyItems() public view returns (Types.Item[] memory) {
        return getAccountItems();
    }


// Get single item from the list
function getSingleItem(string memory barcodeId)
        public
        view
        returns (Types.Item memory, Types.ItemHistory memory)
    {
        return getSpecificItem(barcodeId);
    }

function addNewItem(Types.Item memory _item, uint256 currentTime_)
        public
        onlyManufacturer
    {
        addItem(_item, currentTime_);
    }

// sell item i.e transfer ownership to another user 
 function sellItem(
        address partyId,
        string memory barcodeId,
        uint256 currentTime_
    ) public {
        require(isPartyExists(partyId), "Party not found");
        Types.AccountDetails memory party_ = accounts[partyId];
        sell(partyId, barcodeId, party_, currentTime_);
    }


    // add user to my account which can be used in the future
     function addParty(Types.AccountDetails memory account_) public {
        addparty(account_, msg.sender);
    }

    // get details of the user
     function getAccountDetails(address Id)
        public
        view
        returns (Types.AccountDetails memory)
    {
        return getPartyDetails(Id);
    }

// get details of currently signed in account  
 function getMyDetails() public view returns (Types.AccountDetails memory) {
        return getPartyDetails(msg.sender);
    }

    // get list of all account added by currently operating account
    function getMyAccountsList()
        public
        view
        returns (Types.AccountDetails[] memory accountsList_)
    {
        return getMyPartyList(msg.sender);
    }






} //END OF CONTRACT

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Types
 * @author TEAM201
 * @dev The Program's Custom types
 */

library Types {
    // ENUMS

    // These are the roles available for the users of the platform

    enum AccountRole {
        Manufacturer,
        Distributor,
        Retailer,
        Customer
    }


    // Groups of items supplied by a manufacturer

    enum ItemType {
        Antibiotics, 
        Antimalaria,
        Analgestics,
        Supplements,
        Steroids

    }
    

    // STRUCT

    // this contains account details of the users of the platform  
    struct AccountDetails {
        AccountRole role;
        address accountId;
        string name;
        string email;
    } 

    // this contains the transcation details of the user
    struct AccountTransactions {
        address transactionAddress; // account Address of the user
        uint timestamp; // time of purchase
    }

    struct ItemHistory {
        AccountTransactions manufacturer;
        AccountTransactions distributor;
        AccountTransactions retailer;
        AccountTransactions[] customers; //Array of customers transaction
     
    }

    struct Item {
        string name;
        string manufacturerName;
        address manufacturer;
        uint256 manufacturedDate;
        uint256 expiringDate;
        bool isInBatch; // this is true if the items is sold in batches
        uint256 batchCount; // Items that were packed in single batch
        string barcodeId;
        string itemImage;
        ItemType itemType;
        string usage;
        string[] others; // Other information to share
    }
}