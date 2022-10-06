// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Ownable.sol";
import "./IValist.sol";

contract m3taDao is
    Ownable
{


                        //   @@@@@  @@@@@    @@@@@@@  @@@@@@@   @@@@@@   @@@@@@@      @@@@@@     @@@@@@@    \\
                        //  @@@@@@@@@@@@@@   @@@@@@@  @@@@@@@  @@@@@@@@  @@@@@@@@    @@@@@@@@   @@@@@@@@@   \\
                        //  @@!  @@@@  @@@       [email protected]    @@@    @@!  @@@  @@    @@@   @@!  @@@  @@@     @@@  \\
                        //  [email protected]!  [email protected][email protected]  @[email protected] [email protected]    @@@    [email protected]!  @[email protected]  @@     @@@  [email protected]!  @[email protected] [email protected]!     @[email protected]  \\
                        //  [email protected]!  @[email protected]!  [email protected]!   @@@@[email protected]    @@@    @[email protected][email protected][email protected]!  @@     @@@  @[email protected][email protected][email protected]!  @[email protected] [email protected]!  \\
                        //  !!!  !!!!  !!!   @@@@[email protected]    @@@    [email protected]!!!!  @@     @@@  [email protected]!!!!  !!!     !!!  \\
                        //  !!:  !!!!  !!!       [email protected]    @[email protected]    !!:  !!!  @@     @@@  !!:  !!!  !!:     !!!  \\
                        //  :!:  :!:!  !:!       [email protected]    @@@    :!:  !:!  @@    @@@   :!:  !:!  :!:     !:!  \\  
                        //  :::  ::::  :::   @@@@@@@    @@@    ::   :::  @@   @@@    :::  :::  @@@@@@@@@@   \\
                        //  :::  ::::  :::   @@@@@@@    @@@    ::   :::  @@@@@@@     :::  : :    @@@@@@@    \\

                                    //  @@@  @@@   @@@@@@   @@@       @@@   @@@@@@   @@@@@@@  \\
                                    //  @@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@   @@@@@@@  \\
                                    //  @@!  @@@  @@!  @@@  @@!       @@!  [email protected]@         @@!    \\
                                    //  [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]!  [email protected]!         [email protected]!    \\
                                    //  @[email protected] [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected] [email protected]@!!      @!!    \\
                                    //  [email protected]!  !!!  [email protected]!!!!  !!!       !!!   [email protected]!!!     !!!    \\
                                    //  :!:  !!:  !!:  !!!  !!:       !!:       !:!    !!:    \\
                                    //   ::!!:!   :!:  !:!   :!:      :!:      !:!     :!:    \\
                                    //    ::::    ::   :::   :: ::::  :::  :::: ::      ::    \\
                                    //     :       :   : :  : :: : :  :::  :: : :       :     \\
    
    using Counters for Counters.Counter;

    mapping(address => bool) private profileExists;
    mapping(uint => bool) private accountExists;

    Counters.Counter private profileID;
    Counters.Counter private ValistID;
    IValist          private valistRegistryContract;
    ITablelandTables private tablelandContract;
    string  private _chainID;
    uint256    private _chainId;
    string  private _baseURIString;

    string  private _AccountTable;
    string  private _AccountTablePrefix;
    uint256 private _AccountTableId;

    string  private _UserTable;
    string  private _UserTablePrefix;
    uint256 private _UserTableId;

// 0xD504d012D78B81fA27288628f3fC89B0e2f56e24
    constructor(IValist ValistRegistryContract )
    {
        //@dev setting the external valist contract
        valistRegistryContract = ValistRegistryContract;
        _chainId = 80001;
        _chainID = Strings.toString(_chainId);
        // Creating the M3taDao Tableland Tables on the constructor
        _baseURIString = "https://testnet.tableland.network/query?s=";
        _AccountTablePrefix = "M3taAccount";
        _UserTablePrefix = "M3taUser";
        tablelandContract = TablelandDeployments.get();

        _AccountTableId = tablelandContract.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                _AccountTablePrefix,
                "_",
                _chainID,
                " (founderAddress text, identifier text, accountID text, groupID text, accountHex text, accountName text, imageURI text, description text);"
            )
        );

        _AccountTable = string.concat(
            _AccountTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_AccountTableId)
        );

        _UserTableId = tablelandContract.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                _UserTablePrefix,
                "_",
                _chainID,
                " (userAddress text, identifier text, userDID text, groupID text, userName text, imageURI text, description text);"
            )
        );

        _UserTable = string.concat(
            _UserTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_UserTableId)
        );


    }

        // Function for creating posts for an Organization 
    function indexProfile(string memory profiledid , string memory groupID , string memory userName , string memory imageURI , string memory description) public {
        // only one profile per address
        require(profileExists[msg.sender] == false , "only one profile per address");

        profileExists[msg.sender] = true;

        profileID.increment();

        string memory statement = string.concat(
                "INSERT INTO ",
                _AccountTable,
                " (userAddress, identifier, userDID, groupID, userName, imageURI, description) VALUES ("
                ," '"
                ,Strings.toHexString(uint160(msg.sender), 20)
                ,"', "
                ,Strings.toString(profileID.current())
                ,", '"
                ,profiledid
                ,"', '"
                ,groupID
                ,"', '"
                ,userName
                ,"', '"
                ,imageURI
                ,"', '"
                ,description
                ,"')");
        runSQL(_UserTableId,statement);      
    }       
        
    

    // Creating a Valist Account/Organization
    function indexProjectAccount(uint accountID, string memory groupID, string memory accountName , string memory imageURI , string memory description)
        public  
    {
        require(isAccountMember(accountID,msg.sender) && accountExists[accountID] == false);

        string memory accountHex = Strings.toHexString(accountID);

        ValistID.increment();

        string memory statement = string.concat(
                "INSERT INTO ",
                _AccountTable,
                " (founderAddress, identifier, accountID, groupID, accountHex, accountName, imageURI, description) VALUES ("
                ," '"
                ,Strings.toHexString(uint160(msg.sender), 20)
                ,"', "
                ,Strings.toString(ValistID.current())
                ,", '"
                ,Strings.toString(accountID)
                ,"', '"
                ,groupID
                ,"', '"
                ,accountHex
                ,"', '"
                ,accountName
                ,"', '"
                ,imageURI
                ,"', '"
                ,description
                ,"')");
        runSQL(_AccountTableId,statement);      
    }

    // Function to make Insertions , Updates and Deletions to our Tableland Tables 
    function runSQL(uint256 tableID, string memory statement) private{
         tablelandContract.runSQL(
            address(this),
            tableID,
            statement        
        );
    }


    function ValistAccountTableURI() 
    public view returns (string memory) {
        return string.concat(
            _baseURI(), 
            "SELECT%20*%20FROM%20",
            _AccountTable
        );
    }

    function _baseURI() internal view returns (string memory) {
        return _baseURIString;
    }
    // Setting tableland BaseUri for future updates!!!
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIString = baseURI;
    }


    function isAccountMember(uint _accountID,address member) public view returns (bool) {
       return  valistRegistryContract.isAccountMember(_accountID,member);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITablelandController.sol";

/**
 * @dev Interface of a TablelandTables compliant contract.
 */
interface ITablelandTables {
    /**
     * The caller is not authorized.
     */
    error Unauthorized();

    /**
     * RunSQL was called with a query length greater than maximum allowed.
     */
    error MaxQuerySizeExceeded(uint256 querySize, uint256 maxQuerySize);

    /**
     * @dev Emitted when `owner` creates a new table.
     *
     * owner - the to-be owner of the table
     * tableId - the table id of the new table
     * statement - the SQL statement used to create the table
     */
    event CreateTable(address owner, uint256 tableId, string statement);

    /**
     * @dev Emitted when a table is transferred from `from` to `to`.
     *
     * Not emmitted when a table is created.
     * Also emitted after a table has been burned.
     *
     * from - the address that transfered the table
     * to - the address that received the table
     * tableId - the table id that was transferred
     */
    event TransferTable(address from, address to, uint256 tableId);

    /**
     * @dev Emitted when `caller` runs a SQL statement.
     *
     * caller - the address that is running the SQL statement
     * isOwner - whether or not the caller is the table owner
     * tableId - the id of the target table
     * statement - the SQL statement to run
     * policy - an object describing how `caller` can interact with the table (see {ITablelandController.Policy})
     */
    event RunSQL(
        address caller,
        bool isOwner,
        uint256 tableId,
        string statement,
        ITablelandController.Policy policy
    );

    /**
     * @dev Emitted when a table's controller is set.
     *
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     */
    event SetController(uint256 tableId, address controller);

    /**
     * @dev Creates a new table owned by `owner` using `statement` and returns its `tableId`.
     *
     * owner - the to-be owner of the new table
     * statement - the SQL statement used to create the table
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function createTable(address owner, string memory statement)
        external
        payable
        returns (uint256);

    /**
     * @dev Runs a SQL statement for `caller` using `statement`.
     *
     * caller - the address that is running the SQL statement
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` or contract owner
     * - `tableId` must exist
     * - `caller` must be authorized by the table controller
     * - `statement` must be less than or equal to 35000 bytes
     */
    function runSQL(
        address caller,
        uint256 tableId,
        string memory statement
    ) external payable;

    /**
     * @dev Sets the controller for a table. Controller can be an EOA or contract address.
     *
     * When a table is created, it's controller is set to the zero address, which means that the
     * contract will not enforce write access control. In this situation, validators will not accept
     * transactions from non-owners unless explicitly granted access with "GRANT" SQL statements.
     *
     * When a controller address is set for a table, validators assume write access control is
     * handled at the contract level, and will accept all transactions.
     *
     * You can unset a controller address for a table by setting it back to the zero address.
     * This will cause validators to revert back to honoring owner and GRANT bases write access control.
     *
     * caller - the address that is setting the controller
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external;

    /**
     * @dev Returns the controller for a table.
     *
     * tableId - the id of the target table
     */
    function getController(uint256 tableId) external returns (address);

    /**
     * @dev Locks the controller for a table _forever_. Controller can be an EOA or contract address.
     *
     * Although not very useful, it is possible to lock a table controller that is set to the zero address.
     *
     * caller - the address that is locking the controller
     * tableId - the id of the target table
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function lockController(address caller, uint256 tableId) external;

    /**
     * @dev Sets the contract base URI.
     *
     * baseURI - the new base URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ITablelandTables.sol";

/**
 * @dev Helper library for getting an instance of ITablelandTables for the currently executing EVM chain.
 */
library TablelandDeployments {
    /**
     * Current chain does not have a TablelandTables deployment.
     */
    error ChainNotSupported(uint256 chainid);

    // TablelandTables address on Ethereum Goerli.
    address internal constant GOERLI =
        0xDA8EA22d092307874f30A1F277D1388dca0BA97a;
    // TablelandTables address on Optimism Kovan.
    address internal constant OPTIMISTIC_KOVAN =
        0xf2C9Fc73884A9c6e6Db58778176Ab67989139D06;
    // TablelandTables address on Polygon Mumbai.
    address internal constant POLYGON_MUMBAI =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;
    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 5) {
            return ITablelandTables(GOERLI);
        } else if (block.chainid == 69) {
            return ITablelandTables(OPTIMISTIC_KOVAN);
        } else if (block.chainid == 80001) {
            return ITablelandTables(POLYGON_MUMBAI);
        } else if (block.chainid == 31337) {
            return ITablelandTables(LOCAL_TABLELAND);
        } else {
            revert ChainNotSupported(block.chainid);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./utils/Context.sol";

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
pragma solidity ^0.8.12;

interface IValist {
  /// Creates an account with the given members.
  ///
  /// @param _name Unique name used to identify the account.
  /// @param _metaURI URI of the account metadata.
  /// @param _members List of members to add to the account.
  function createAccount(string calldata _name,string calldata _metaURI,address[] calldata _members  )external payable;
  
  /// Creates a new project. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account to create the project under.
  /// @param _name Unique name used to identify the project.
  /// @param _metaURI URI of the project metadata.
  /// @param _members Optional list of members to add to the project.
   function createProject(uint _accountID,string calldata _name,string calldata _metaURI,address[] calldata _members)external;
  
  /// Creates a new release. Requires the sender to be a member of the project.
  ///
  /// @param _projectID ID of the project create the release under.
  /// @param _name Unique name used to identify the release.
  /// @param _metaURI URI of the project metadata.
  function createRelease(uint _projectID,string calldata _name, string calldata _metaURI) external;
 
  /// Generates account, project, or release ID.
  ///
  /// @param _parentID ID of the parent account or project. Use `block.chainid` for accounts.
  /// @param _name Name of the account, project, or release.
  function generateID(uint _parentID, string calldata _name) external pure returns (uint);
  
  /// Sets the account metadata URI. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _metaURI Metadata URI.
  function setAccountMetaURI(uint _accountID, string calldata _metaURI) external; 

  /// Sets the project metadata URI. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _metaURI Metadata URI.
  function setProjectMetaURI(uint _projectID, string calldata _metaURI) external;
  

  function isAccountMember(uint _accountID, address _member) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of a TablelandController compliant contract.
 *
 * This interface can be implemented to enabled advanced access control for a table.
 * Call {ITablelandTables-setController} with the address of your implementation.
 *
 * See {test/TestTablelandController} for an example of token-gating table write-access.
 */
interface ITablelandController {
    /**
     * @dev Object defining how a table can be accessed.
     */
    struct Policy {
        // Whether or not the table should allow SQL INSERT statements.
        bool allowInsert;
        // Whether or not the table should allow SQL UPDATE statements.
        bool allowUpdate;
        // Whether or not the table should allow SQL DELETE statements.
        bool allowDelete;
        // A conditional clause used with SQL UPDATE and DELETE statements.
        // For example, a value of "foo > 0" will concatenate all SQL UPDATE
        // and/or DELETE statements with "WHERE foo > 0".
        // This can be useful for limiting how a table can be modified.
        // Use {Policies-joinClauses} to include more than one condition.
        string whereClause;
        // A conditional clause used with SQL INSERT statements.
        // For example, a value of "foo > 0" will concatenate all SQL INSERT
        // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
        // This can be useful for limiting how table data ban be added.
        // Use {Policies-joinClauses} to include more than one condition.
        string withCheck;
        // A list of SQL column names that can be updated.
        string[] updatableColumns;
    }

    /**
     * @dev Returns a {Policy} struct defining how a table can be accessed by `caller`.
     */
    function getPolicy(address caller) external payable returns (Policy memory);
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