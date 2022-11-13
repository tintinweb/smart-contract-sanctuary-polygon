// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

import "../AccountEnums.sol";
import "./ICryptopiaAccountRegister.sol";
import "../CryptopiaAccount/CryptopiaAccount.sol";

/// @title Cryptopia Account Register
/// @notice Creates and registers accountDatas
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaAccountRegister is ICryptopiaAccountRegister {

    struct AccountData
    {
        // Unique and validated username
        bytes32 username;

        // Optional sex {Undefined, Male, Female}
        AccountEnums.Sex sex;

        mapping (address => AccountEnums.Relationship) friends;
        address[] friendsIndex;

        mapping (address => AccountEnums.Relationship) friendRequests;
    }

    struct AvatarData
    {
        // Required {Male, Female}
        AccountEnums.Gender gender;

        uint8 bodyWeight;
        uint8 bodyShape;

        uint8 hairStyleIndex;
        uint8 eyeColorIndex;
        uint8 skinColorIndex;

        uint8 defaultHatIndex;
        uint8 defaultShirtIndex;
        uint8 defaultPantsIndex;
        uint8 defaultShoesIndex;
    }


    /**
     * Storage
     */
    uint constant USERNAME_MIN_LENGTH = 3;

    mapping(bytes32 => address) public usernameToAccount;
    mapping (address => AccountData) public accountDatas;


    /**
     * Events
     */
    /// @dev Emited when an account is created
    /// @param sender The addres that created the account (tx.origin)
    /// @param account The address of the newly created account (smart-contract)
    /// @param username The unique username of the newly created account (smart-contract)
    /// @param sex {Undefined, Male, Female}
    event CreateAccount(address indexed sender, address indexed account, bytes32 indexed username, AccountEnums.Sex sex);

    /// @dev Emited when a friend request is added
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requests to be friends with
    /// @param relationship The type of friendship
    event AddFriendRequest(address indexed sender, address indexed receiver, AccountEnums.Relationship indexed relationship);

    /// @dev Emited when a friend request is removed
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requested to be friends with
    /// @param relationship The type of friendship
    event RemoveFriendRequest(address indexed sender, address indexed receiver, AccountEnums.Relationship indexed relationship);

    /// @dev Emited when a friend request is accepted
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requested to be friends with
    /// @param relationship The type of friendship
    event AcceptFriendRequest(address indexed sender, address indexed receiver, AccountEnums.Relationship indexed relationship);


    /**
     * Modifiers
     */
    /// @dev Only allow if `account` is registered
    /// @param account The account to check
    modifier onlyRegistered(address account) {
        require(_isRegistered(account), " CryptopiaAccountRegister: Not registered");
        _;
    }


    /// @dev Only allow validated username
    /// @param username The username to check 
    modifier onlyValidUsername(bytes32 username) {
        (bool isValid, string memory reason) = _validateUsername(username);
        require(isValid, string.concat(" CryptopiaAccountRegister: Invalid Username; Reason: ", reason));
        require(usernameToAccount[username] == address(0), " CryptopiaAccountRegister: Duplicate Username");
        _;
    }


    /** 
     * Public functions
     */
    /// @dev Allows verified creation of a Cryptopia account. Use of create2 allows identical addresses across networks
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, AccountEnums.Sex sex)
        public virtual override 
        onlyValidUsername(username)
        returns (address payable account)
    {
        account = payable(Create2Upgradeable.deploy(
            0, username, type(CryptopiaAccount).creationCode));

        CryptopiaAccount(account).initialize(
            owners, required, dailyLimit, username);

        _register(account, username, sex);
    }


    /// @dev Check if an account was created and registered 
    /// @param account Account address
    /// @return true if account is registered
    function isRegistered(address account)
        public virtual override view 
        returns (bool)
    {
        return _isRegistered(account);
    }


    /// @dev Retrieve account info 
    /// @param account The account to retrieve info for
    /// @return username Account username
    /// @return sex {Undefined, Male, Female}
    function getAccountData(address account) 
        public virtual override view 
        returns (
            bytes32 username,
            AccountEnums.Sex sex
        )
    {
        username = accountDatas[account].username;
        sex = accountDatas[account].sex;
    }


    /// @dev Retrieve account info for a range of accounts
    /// @param accounts contract adresses
    /// @return username Account usernames
    /// @return sex {Undefined, Male, Female}
    function getAccountDatas(address payable[] memory accounts) 
        public virtual override view  
        returns (
            bytes32[] memory username,
            AccountEnums.Sex[] memory sex
        )
    {
        username = new bytes32[](accounts.length);
        sex = new AccountEnums.Sex[](accounts.length);
        for (uint i = 0; i < accounts.length; i++)
        {
            if (_isRegistered(accounts[i]))
            {
                username[i] = accountDatas[accounts[i]].username;
                sex[i] = accountDatas[accounts[i]].sex;
            }
            else 
            {
                username[i] = 0;
                sex[i] = AccountEnums.Sex.Undefined;
            }
        }
    }


    /// @dev Returns the amount of friends for `account`
    /// @param account The account to query 
    /// @return uint number of friends
    function getFriendCount(address account) 
        public override view 
        returns (uint)
    {
        return accountDatas[account].friendsIndex.length;
    }


    /// @dev Returns the `friend_account` and `friend_username` of the friend at `index` for `account`
    /// @param account The account to retrieve the friend for (subject)
    /// @param index The index of the friend to retrieve
    /// @return friend_account The address of the friend
    /// @return friend_username The unique username of the friend
    /// @return friend_relationship The type of relationship `account` has with the friend
    function getFriendAt(address account, uint index) 
        public override view 
        returns (
            address friend_account, 
            bytes32 friend_username,
            AccountEnums.Relationship friend_relationship
        )
    {
        friend_account = accountDatas[account].friendsIndex[index];
        friend_username = accountDatas[friend_account].username;
        friend_relationship = accountDatas[account].friends[friend_account];
    }


    /// @dev Returns an array of friends for `account`
    /// @param account The account to retrieve the friends for (subject)
    /// @param skip Location where the cursor will start in the array
    /// @param take The amount of friends to return
    /// @return friend_accounts The addresses of the friends
    /// @return friend_usernames The unique usernames of the friends
    /// @return friend_relationships The type of relationship `account` has with the friends
    function getFriends(address account, uint skip, uint take) 
        public override view 
        returns (
            address[] memory friend_accounts, 
            bytes32[] memory friend_usernames,
            AccountEnums.Relationship[] memory friend_relationships
        )
    {
        friend_accounts = new address[](take);
        friend_usernames = new bytes32[](take);
        friend_relationships = new AccountEnums.Relationship[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            friend_accounts[i] = accountDatas[account].friendsIndex[index];
            friend_usernames[i] = accountDatas[friend_accounts[i]].username;
            friend_relationships[i] = accountDatas[account].friends[friend_accounts[i]];
            index++;
        }
    }


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function isFriend(address account, address other) 
        public override view
        returns (bool)
    {
        return _isFriend(account, other);
    }


    /// @dev Returns true if `account` and `other` have 'relationship'
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @param relationship The type of relationship to test
    /// @return bool True if `account` and `other` have 'relationship'
    function hasRelationsip(address account, address other, AccountEnums.Relationship relationship) 
        public override view
        returns (bool)
    {
        return accountDatas[account].friends[other] == relationship;
    }


    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function hasPendingFriendRequest(address account, address other) 
        public override view
        returns (bool)
    {
        return _hasPendingFriendRequest(account, other);
    }


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function addFriendRequest(address friend_account, AccountEnums.Relationship friend_relationship) 
        public override 
    {
        _addFriendRequest(friend_account, friend_relationship);
    }


    /// @dev Request friendship with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to add the friend requests for
    /// @param friend_relationships The type of relationships that are requested
    function addFriendRequests(address[] memory friend_accounts, AccountEnums.Relationship[] memory friend_relationships) 
       public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _addFriendRequest(friend_accounts[i], friend_relationships[i]);
        }
    }


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function removeFriendRequest(address friend_account) 
        public override 
    {
        _removeFriendRequest(friend_account);
    }


    /// @dev Removes the friend requests with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to remove the friend requests for
    function removeFriendRequests(address[] memory friend_accounts) 
        public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _removeFriendRequest(friend_accounts[i]);
        }
    }

    
    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function acceptFriendRequest(address friend_account) 
        public override 
    {
        _acceptFriendRequest(friend_account);
    }


    /// @dev Accept friendships with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to accept the friend requests for
    function acceptFriendRequests(address[] memory friend_accounts) 
        public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _acceptFriendRequest(friend_accounts[i]);
        }
    }


    /**
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param account Address of account contract instantiation
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    function _register(address account, bytes32 username, AccountEnums.Sex sex) 
        internal 
    {
        // Register
        usernameToAccount[username] = account;
        accountDatas[account].username = username;
        accountDatas[account].sex = sex;

        // Emit
        emit CreateAccount(tx.origin, account, username, sex);
    }


    /// @dev Check if `account` is registered
    /// @param account The account to check
    /// @return bool True if  `account` is a registered account
    function _isRegistered(address account) 
        internal view 
        returns (bool)
    {
        return accountDatas[account].username != bytes32(0);
    }


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function _isFriend(address account, address other) 
        internal view
        returns (bool)
    {
        return accountDatas[account].friends[other] != AccountEnums.Relationship.None;
    }


    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function _hasPendingFriendRequest(address account, address other) 
        internal view
        returns (bool)
    {
        return accountDatas[account].friendRequests[other] != AccountEnums.Relationship.None && 
               accountDatas[other].friendRequests[account] != AccountEnums.Relationship.None;
    }


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function _addFriendRequest(address friend_account, AccountEnums.Relationship friend_relationship) 
        internal 
        onlyRegistered(msg.sender) 
    {
        require(_validateRelationship(friend_relationship), " CryptopiaAccountRegister: Invalid relationship");
        require(_isRegistered(friend_account), " CryptopiaAccountRegister: Friend is not a registred account");
        require(!_isFriend(msg.sender, friend_account), " CryptopiaAccountRegister: Already friends");
        require(!_hasPendingFriendRequest(msg.sender, friend_account), " CryptopiaAccountRegister: Pending friend request exists");

        // Add 
        accountDatas[msg.sender].friendRequests[friend_account] = friend_relationship;

        // Emit
        emit AddFriendRequest(msg.sender, friend_account, friend_relationship);
    } 


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function _removeFriendRequest(address friend_account) 
        internal 
    {
        require(_hasPendingFriendRequest(msg.sender, friend_account), " CryptopiaAccountRegister: Pending friend request does not exists");

        // Remove 
        AccountEnums.Relationship relationship = accountDatas[msg.sender].friendRequests[friend_account];
        accountDatas[msg.sender].friendRequests[friend_account] = AccountEnums.Relationship.None;

        // Emit
        emit RemoveFriendRequest(msg.sender, friend_account, relationship);
    }


    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function _acceptFriendRequest(address friend_account) 
        internal 
    {
        require(_hasPendingFriendRequest(friend_account, msg.sender), "");

        // Remove friend request
        AccountEnums.Relationship relationship = accountDatas[friend_account].friendRequests[msg.sender];
        accountDatas[friend_account].friendRequests[msg.sender] = AccountEnums.Relationship.None;

        // Add friendship
        accountDatas[msg.sender].friends[friend_account] = relationship;
        accountDatas[friend_account].friends[msg.sender] = relationship;

        // Emit
        emit AcceptFriendRequest(friend_account, msg.sender, relationship);
    }


    /// @dev Validate `username`
    /// @param username The username value to test
    /// @return isValid True if `username` is valid
    /// @return reason The reason why the username is not valid
    function _validateUsername(bytes32 username)
        internal pure 
        returns (bool isValid, string memory reason)
    {
        bool foundEnd = false;
        for(uint i = 0; i < username.length; i++)
        {
            bytes1 char = username[i];
            if (char == 0x00)
            {
                if (!foundEnd)
                {
                    if (i < USERNAME_MIN_LENGTH)
                    {
                        return (false, "Too short");
                    }

                    foundEnd = true;
                }
                
                continue;
            }
            else if (foundEnd)
            {
                return (false, "Expected end");
            }

            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z)
                !(char == 0x5F)) // _
            {
                return (false, "Invalid char");
            }
        }

        return (true, "");
    }


    /// @dev Validate `relationship`
    /// @param relationship The relationship value to test
    /// @return bool True if `relationship` is valid
    function _validateRelationship(AccountEnums.Relationship relationship)
        internal pure 
        returns (bool)
    {
        return relationship > AccountEnums.Relationship.None && relationship <= AccountEnums.Relationship.Spouse;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMultiSigWallet.sol";

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]> (modified by Frank Bonnet <[email protected]>)
contract MultiSigWallet is IMultiSigWallet, Initializable {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event DailyLimitChange(uint dailyLimit);


    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;


    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }


    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }


    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }


    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }


    modifier transactionConfirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }


    modifier transactionNotConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }


    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }


    modifier notNull(address account) {
        require(account != address(0));
        _;
    }


    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }


    /// @dev Fallback function allows to deposit ether.
    receive() 
        external payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }


    /// @dev Fallback function allows to deposit ether.
    fallback() 
        external payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }


    /*
     * Public functions
     */
    /// @dev Contract initializer sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    function __Multisig_init(address[] memory _owners, uint _required, uint _dailyLimit) 
        internal onlyInitializing
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        dailyLimit = _dailyLimit;
    }


    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public virtual override 
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }


    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public virtual override
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }


    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public virtual override
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }


    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public virtual override
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }


    /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    /// @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        public virtual override
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }


    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data)
        public virtual override
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }


    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        transactionNotConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }


    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }


    /// @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) 
        {
            txn.executed = true;
            if (!_confirmed)
            {
                spentToday += txn.value;
            }

            if (external_call(txn.destination, txn.value, txn.data.length, txn.data)) 
            {
                emit Execution(transactionId);
            }
            else 
            {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
                if (!_confirmed)
                    spentToday -= txn.value;
            }
        }
    }


    /**
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
       public virtual override view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }


    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
       public virtual override view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }


    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public virtual override view
        returns (address[] memory)
    {
        return owners;
    }


    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public virtual override view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }


    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public virtual override view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }


    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        public 
        virtual 
        override 
        view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }


    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return confirmed Confirmation status.
    function isConfirmed(uint transactionId)
        public 
        virtual 
        override 
        view
        returns (bool confirmed)
    {
        confirmed = false;
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                confirmed = true;
        }
    }


    /*
     * Internal functions
     */
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) 
        internal 
        returns (bool result) 
    {
        assembly {
            let output := mload(0x40)
            result := call(
                sub(gas(), 34710),  // 34710 is the value that solidity is currently emitting
                                    // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                    // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                add(data, 32),      // First 32 bytes are the padded length of data, so exclude that
                dataLength,         // Size of the input (in bytes) - this is what fixes the padding problem
                output,
                0                   // Output is ignored, therefore the output size is zero
            )

            // Only for debug
            // switch result
            //     case 0 {
            //         let size := returndatasize()
            //         returndatacopy(output, 0, size)
            //         revert(output, size)
            //     }
        }
    }


    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        return true;
    }


    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]> (modified by Frank Bonnet <[email protected]>)
interface IMultiSigWallet {

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner) 
        external;


    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        external;


    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        external;


    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        external;


    /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    /// @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        external;


    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data)
        external 
        returns (uint transactionId);


    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        external;


    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        external;


    /// @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        external;


    /*
     * Web3 call functions
     */
    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        external view
        returns (uint);


    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        external view
        returns (bool);


    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
        external view
        returns (uint count);


    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        external view
        returns (uint count);


    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        external view
        returns (address[] memory);


    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        external view
        returns (address[] memory _confirmations);


    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        external view
        returns (uint[] memory _transactionIds);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../AccountEnums.sol";

/// @title Cryptopia Account Register
/// @notice Creates and registers accounts
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAccountRegister {

    /// @dev Allows verified creation of a Cryptopia account. Use of create2 allows identical addresses across networks
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, AccountEnums.Sex sex) 
        external 
        returns (address payable account);


    /// @dev Check if an account was created and registered 
    /// @param account Account address.
    /// @return true if account is registered.
    function isRegistered(address account) 
        external view 
        returns (bool);


    /// @dev Retrieve account info 
    /// @param account The account to retrieve info for
    /// @return username Account username
    /// @return sex {Undefined, Male, Female}
    function getAccountData(address account) 
        external view 
        returns (
            bytes32 username,
            AccountEnums.Sex sex
        );


    /// @dev Retrieve account info for a range of addresses
    /// @param addresses contract adresses
    /// @return username Account usernames
    /// @return sex {Undefined, Male, Female}
    function getAccountDatas(address payable[] memory addresses) 
        external view 
        returns (
            bytes32[] memory username,
            AccountEnums.Sex[] memory sex
        );

    
    /// @dev Returns the amount of friends for `account`
    /// @param account The account to query 
    /// @return uint number of friends
    function getFriendCount(address account) 
        external view 
        returns (uint);


    /// @dev Returns the `friend_account` and `friend_username` of the friend at `index` for `account`
    /// @param account The account to retrieve the friend for (subject)
    /// @param index The index of the friend to retrieve
    /// @return friend_account The address of the friend
    /// @return friend_username The unique username of the friend
    /// @return friend_relationship The type of relationship `account` has with the friend
    function getFriendAt(address account, uint index) 
        external view 
        returns (
            address friend_account, 
            bytes32 friend_username,
            AccountEnums.Relationship friend_relationship
        );


    /// @dev Returns an array of friends for `account`
    /// @param account The account to retrieve the friends for (subject)
    /// @param skip Location where the cursor will start in the array
    /// @param take The amount of friends to return
    /// @return friend_accounts The addresses of the friends
    /// @return friend_usernames The unique usernames of the friends
    /// @return friend_relationships The type of relationship `account` has with the friends
    function getFriends(address account, uint skip, uint take) 
        external view 
        returns (
            address[] memory friend_accounts, 
            bytes32[] memory friend_usernames,
            AccountEnums.Relationship[] memory friend_relationships
        );


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function isFriend(address account, address other) 
        external view
        returns (bool);

    
    /// @dev Returns true if `account` and `other` have 'relationship'
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @param relationship The type of relationship to test
    /// @return bool True if `account` and `other` have 'relationship'
    function hasRelationsip(address account, address other, AccountEnums.Relationship relationship) 
        external view
        returns (bool);

    
    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function hasPendingFriendRequest(address account, address other) 
        external view
        returns (bool);


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function addFriendRequest(address friend_account, AccountEnums.Relationship friend_relationship) 
        external;


    /// @dev Request friendship with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to add the friend requests for
    /// @param friend_relationships The type of relationships that are requested
    function addFriendRequests(address[] memory friend_accounts, AccountEnums.Relationship[] memory friend_relationships) 
        external;


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function removeFriendRequest(address friend_account) 
        external;


    /// @dev Removes the friend requests with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to remove the friend requests for
    function removeFriendRequests(address[] memory friend_accounts) 
        external;

    
    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function acceptFriendRequest(address friend_account) 
        external;


    /// @dev Accept friendships with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to accept the friend requests for
    function acceptFriendRequests(address[] memory friend_accounts) 
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Account
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAccount {

}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1820RegistryUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../MultisigWallet/MultiSigWallet.sol";
import "./ICryptopiaAccount.sol";

/// @title Cryptopia Account
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaAccount is ICryptopiaAccount, Initializable, MultiSigWallet, IERC777RecipientUpgradeable, IERC721ReceiverUpgradeable {

    /**
     * Storage
     */
    address constant private ERC1820_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    bytes32 constant private ERC777_RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");

    bytes32 public username;

    /** 
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations, daily withdraw limit and unique username.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    /// @param _username Unique username
    function initialize(address[] memory _owners, uint _required, uint _dailyLimit, bytes32 _username) 
        public initializer 
    {
        __Multisig_init(_owners, _required, _dailyLimit);

        // Register as ERC777 recipient
        IERC1820RegistryUpgradeable(ERC1820_ADDRESS).setInterfaceImplementer(
            address(this), ERC777_RECIPIENT_INTERFACE, address(this));

        username = _username;
    }


    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) public virtual override 
    {
        // Nothing for now
    }


    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) 
        public virtual override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Account enums
/// @author Frank Bonnet - <[email protected]>
contract AccountEnums {

    enum Sex 
    {
        Undefined,
        Male,
        Female
    }

    enum Gender 
    {
        Male,
        Female
    }

    enum Relationship
    {
        None,
        Friend,
        Family,
        Spouse
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777RecipientUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1820Registry.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC1820RegistryUpgradeable.sol";