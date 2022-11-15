// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Types.sol";

/**
 * @title Accounts
 * @author TEAM201
 * @dev This program manages addresses and roles given to users
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

/**
 * @title Types
 * @author TEAM201
 * @dev These are the custom types that are will be available in all the program

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


    // The available items the organisation supplies 

    enum ItemType {
        Yes, 
        No
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