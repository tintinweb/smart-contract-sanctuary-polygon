// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "./Ownable.sol";
import "./Im3taQuery.sol";
import "./IValist.sol";
import "./Im3taUser.sol";

contract m3taDao is Ownable
{


                        //   @@@@@  @@@@@   :::: @@@  @@@@@@@   @@@@@@   @@@@@@@      @@@@@@    @@@@@@     \\
                        //  @@@@@@@@@@@@@@  :::: @@@  @@@@@@@  @@@@@@@@  @@@@@@@@    @@@@@@@@  @@@@@@@@    \\
                        //  @@!  @@@@  @@@       @@!    @@!    @@!  @@@  @@!   @@@   @@!  @@@  @@!   @@@   \\
                        //  [email protected]!  [email protected][email protected]  @[email protected] [email protected]!    [email protected]!    [email protected]!  @[email protected] [email protected]!    @@@  [email protected]!  @[email protected] [email protected]!   @[email protected]   \\
                        //  @[email protected]  @[email protected]!  [email protected]!  :::: @!!    @!!    @[email protected][email protected][email protected]!  @[email protected]    @@@  @[email protected][email protected][email protected]!  @[email protected] [email protected]!   \\
                        //  !!!  !!!!  !!!  :::: !!!    !!!    [email protected]!!!!  !!!    @@@  [email protected]!!!!  !!!   !!!   \\
                        //  !!:  !!!!  !!!       !!:    !!:    !!:  !!!  !!:    @@@  !!:  !!!  !!:   !!!   \\
                        //  :!:  :!:!  !:!       :!:    :!:    :!:  !:!  :!:   @@@   :!:  !:!  :!:   !:!   \\  
                        //  ::   ::::  :::  :::: :::     ::    ::   :::  :!   @@@    ::   :::  @@@   @@@   \\
                        //   :   :: :  : :  :::: :::     :      :   : :  [email protected]@@@      :   : :   @@@@@@@    \\

//  @@@  @@@   @@@@@@   @@@       @@@   @@@@@@   @@@@@@@      ::       ::      @@@      @@@ ::::  @@@       @@@   @@@@@@   \\
//  @@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@   @@@@@@@       ::     ::       @@@      @@@ ::::  @@@::     @@@  @@@@@@@   \\
//  @@!  @@@  @@!  @@@  @@!       @@!  [email protected]@         @@!          ::   ::        @@!      @@!       @@! ::    @@!  [email protected]@       \\
//  [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]!  [email protected]!         [email protected]!           :: ::         [email protected]!      [email protected]!       [email protected]!  ::   [email protected]!  [email protected]!       \\
//  @[email protected] [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected] [email protected]@!!      @!!            :::          @!!      @!! ::::  @!!   ::  @!!  [email protected]@!!    \\
//  [email protected]!  !!!  [email protected]!!!!  !!!       !!!   [email protected]!!!     !!!           ::::          !!!      !!! ::::  !!!    :: !!!   [email protected]!!!   \\
//  :!:  !!:  !!:  !!!  !!:       !!:       !:!    !!:          ::  ::         !!:      !!:       !!:     ::!!:       !:!  \\
//   ::!!:!   :!:  !:!   :!:      :!:      !:!     :!:         ::    ::        :!:      :!:       :!:      :::!      !:!   \\
//    ::::    ::   :::   :: ::::  :::  :::: ::      ::        ::      ::       :: ::::  ::: ::::  ::        :::  :::: ::   \\
//     :       :   : :  : :: : :  :::  :: : :       :        ::        ::      :: ::::  ::: ::::  ::         ::  :: : :    \\


    mapping(uint256 => address) postsMapping;
    mapping(uint => uint256) valistMapping;
    using Counters for Counters.Counter;
    Counters.Counter private postIDs;
    Counters.Counter private ValistIDs;
    ITablelandTables private tablelandContract;
    Im3taQuery       private queryContract;
    IValist          private valistRegistryContract;
    Im3taUser        private m3taUserContract;
    string  private _chainID;
    uint256    private _chainId;
    string  private _baseURIString;
    string  private _metadataTable;
    // Tableland Account-Project table variables
    string  private _projectTable;
    string  private _projectTablePrefix;
    uint256 private _projectTableId;
    // Tableland SubProject table variables
    string  private _subProjectTable;
    string  private _subProjectTablePrefix;
    uint256 private _subProjectTableId;
    // Tableland Release table variables
    string  private _releaseTable;
    string  private _releaseTablePrefix;
    uint256 private _releaseTableId;
    // Tableland Post Tables for Organizations
    string  private _postTable;
    string  private _postTablePrefix;
    uint256 private _postTableId;


    constructor(Im3taQuery initQueryContract,Im3taUser intitM3taUserContract)
    {
        //@dev setting the external contracts
        m3taUserContract = intitM3taUserContract;
        queryContract = initQueryContract;
        valistRegistryContract = IValist(0xD504d012D78B81fA27288628f3fC89B0e2f56e24);

        // Tableland Table Properties and Creation 
        _baseURIString = "https://testnet.tableland.network/query?s=";
        _projectTablePrefix = "M3taAccount";
        _subProjectTablePrefix = "M3taProject";
        _releaseTablePrefix = "M3taRelease";
        _postTablePrefix = "M3taPost";
        tablelandContract = TablelandDeployments.get();
        _chainId = 80001;
        _chainID = Strings.toString(_chainId);
        // Creating the M3taDao Tableland Tables on the constructor
        _projectTableId = tablelandContract.createTable(
            address(this),
            queryContract.getCreateValistAccountTableStatement(
                _projectTablePrefix,
                _chainID
            )
        );

        _projectTable = string.concat(
            _projectTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_projectTableId)
        );
        _subProjectTableId = tablelandContract.createTable(
            address(this),
            queryContract.getCreateValistSubProjectTableStatement(
                _subProjectTablePrefix,
                _chainID
            )
        );

        _subProjectTable = string.concat(
            _subProjectTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_subProjectTableId)
        );

        _releaseTableId = tablelandContract.createTable(
            address(this),
            queryContract.getCreateValistReleaseTableStatement(
                _releaseTablePrefix,
                _chainID
            )
        );

        _releaseTable = string.concat(
            _releaseTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_releaseTableId)
        );

        _postTableId = tablelandContract.createTable(
            address(this),
            queryContract.getCreatePostTableStatement(
                _postTablePrefix,
                _chainID
            )
        );

        _postTable = string.concat(
            _postTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_postTableId)
        );
    }
    // Creating a Lens protocol Profile
    function createLensProfile(DataTypes.ProfileTableStruct memory vars) public {
        vars.profile.to = msg.sender;
        m3taUserContract.createProfile(vars);
    }

    // Creating a Valist Account/Organization
    function createProjectAccount(DataTypes.AccountStruct memory vars)
        public
        payable
    {
        vars.founderAddress = msg.sender;

        require(
            m3taUserContract.getProfIdByAddress(vars.founderAddress) > 0,
            "only m3taDao users can create an Account"
        );

        vars.metadataTable = _projectTable;

        vars.accountID = valistRegistryContract.generateID(_chainId, vars.accountName);

        vars.accountHex = Strings.toHexString(vars.accountID);

        ValistIDs.increment();

        valistMapping[vars.accountID] = ValistIDs.current();

        vars.id = ValistIDs.current();

        valistRegistryContract.createAccount(
            vars.accountName,
            vars.metaURI,
            vars.members
        );
        string memory statement = queryContract.getAccountInsertStatement(vars);
        runSQL(_projectTableId,statement);
    }

    //  Creating a Project inside a Valist Account/Organization 
    function createSubProject(DataTypes.ProjectStruct memory vars)
        public
        payable
    {
        vars.sender = msg.sender;
        require(
            m3taUserContract.getProfIdByAddress(vars.sender) > 0,
            "only m3taDao users can create a Project"
        );

        vars.metadataTable = _subProjectTable;

        vars.projectID = valistRegistryContract.generateID(_chainId, vars.projectName);

        vars.projectHex = Strings.toHexString(vars.projectID);

        ValistIDs.increment();

        valistMapping[vars.projectID] = ValistIDs.current();

        vars.id = ValistIDs.current();

        valistRegistryContract.createProject(
            vars.accountID,
            vars.projectName,
            vars.metaURI,
            vars.members
        );
        string memory statement = queryContract.getSubProjectInsertStatement(vars);
        runSQL(_subProjectTableId,statement);
    }

    // Creating a Release version inside a Valist Project 
    function createRelease(DataTypes.ReleaseStruct memory vars) public payable {

        vars.sender = msg.sender;

        require(
            m3taUserContract.getProfIdByAddress(vars.sender) > 0,
            "only m3taDao users can create a Release"
        );

        vars.metadataTable = _releaseTable;

        vars.releaseID = valistRegistryContract.generateID(_chainId, vars.releaseName);

        vars.releaseHex = Strings.toHexString(vars.releaseID);

        valistRegistryContract.createRelease(
            vars.projectID,
            vars.releaseName,
            vars.metaURI
        );
        string memory statement = queryContract.getReleaseInsertStatement(vars);
        runSQL(_releaseTableId,statement);
    }

    // Function for creating posts for an Organization 
    function createPost(DataTypes.PostStruct memory vars) public {
        vars.posterAddress = msg.sender;
        require(
            m3taUserContract.getProfIdByAddress(vars.posterAddress) > 0, "Only m3taDao Users can post into Organization/Team Accounts"
        );
        postIDs.increment();
        vars.postID = postIDs.current();
        postsMapping[vars.postID] = vars.posterAddress;
        vars.metadataTable = _postTable;
        string memory statement = queryContract.getPostInsertStatement(vars);
        runSQL(_postTableId,statement);
    }

    // Deleting a post only post owner or Organization members
    function deletePost(uint256 accountID , uint256 postID) public {
        require(postsMapping[postID] == msg.sender || isAccountMember(accountID,msg.sender) , "Only post creators and account members can delete a post");
        string memory statement = queryContract.getDeletePostStatement(_postTable,postID);
         runSQL(_postTableId,statement);
        postsMapping[postID] = address(0);
    }

    // Update metadata for a Valist Account/Organization/Team
    function updateAccountMetadata( uint accountID,  string memory imageURL, string memory bannerURI, string calldata metaURI, string memory description ,string memory requirements)
        public
    {
        require(
            isAccountMember(accountID, msg.sender),
            "only accountMembers can update the Account metadata"
        );

        valistRegistryContract.setAccountMetaURI(accountID, metaURI);
        uint256 id = valistMapping[accountID]; 
        string memory uri = metaURI;
        string memory statement = queryContract.getUpdateAccountStatement(_projectTable,id,imageURL,bannerURI,uri,description,requirements);
        runSQL(_projectTableId,statement);

    }
 
    // Update metadata for a Valist Project
    function updateProjectMetadata(uint projectID,  string memory imageURI,string calldata metaURI, string memory description)
    public
    {
        require(
            isAccountMember(projectID, msg.sender),
            "only accountMembers can update the project metadata"
        );
        valistRegistryContract.setProjectMetaURI(projectID, metaURI);
        uint256 id = valistMapping[projectID];
        string memory uri = metaURI;
        string memory statement = queryContract.getUpdateAccountProjectStatement(_projectTable,id,imageURI,uri,description);
        runSQL(_projectTableId,statement);
        

    }

    // Update Lens Protocol Profile Data
    function updateProfileMetadata(uint256 profileId, string calldata imageURI, string memory profileURI, string memory externalURIs)
    public
    {
        m3taUserContract.updateProfile(profileId, imageURI ,profileURI, externalURIs);
    }


    // Function to make Insertions , Updates and Deletions to our Tableland Tables 
    function runSQL(uint256 tableID, string memory statement) private{
         tablelandContract.runSQL(
            address(this),
            tableID,
            statement        
        );
    }

    // Getters for Fetching our Contract Table URIs
    function getAccountTableURI() public view returns (string memory) {
        return queryContract.metadataURI(_projectTable, _baseURI());
    }
    function getProjectTableURI() public view returns (string memory) {
        return queryContract.metadataURI(_subProjectTable, _baseURI());
    }

    function getReleaseTableURI() public view returns (string memory) {
        return queryContract.metadataURI(_releaseTable, _baseURI());
    }

    function getUserTableURI() public view returns (string memory) {
        return m3taUserContract.metadataURI();
    }

    function getPostTableURI()public view returns (string memory) {
        return queryContract.metadataURI(_postTable, _baseURI());
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
import "./DataTypes.sol";

interface Im3taQuery  {

    function getSubProjectInsertStatement(DataTypes.ProjectStruct memory vars)
    external pure returns (string memory);

    function getCreateValistReleaseTableStatement(string memory _tableprefix, string memory chainid) 
    external pure returns (string memory);

    function getReleaseInsertStatement(DataTypes.ReleaseStruct memory vars)
    external pure returns (string memory);

    function getCreateLensProfileTableStatement(string memory _tableprefix, string memory chainid)
    external pure returns (string memory);

    function getProfileInsertStatement(DataTypes.ProfileTableStruct memory vars)
    external pure returns (string memory);

     function getCreateValistSubProjectTableStatement(string memory _tableprefix, string memory chainid) 
     external pure returns (string memory);

    function getAccountInsertStatement(DataTypes.AccountStruct memory vars)
    external pure returns (string memory);

    function metadataURI(string memory metadataTable, string memory base) 
    external pure returns (string memory);
    
    function getCreateValistAccountTableStatement(string memory _tableprefix, string memory chainid) 
    external pure returns (string memory);

    function getPostInsertStatement(DataTypes.PostStruct memory vars)
    external pure returns (string memory);

    function getCreatePostTableStatement(string memory _tableprefix, string memory chainid)
    external pure returns (string memory);

    function getUpdateLensProfileStatement(string memory metadataTable, uint256 profID,  string memory imageURL,string memory profileURI, string memory externalURIs)
    external pure returns (string memory);

    function getUpdateAccountProjectStatement(string memory metadataTable, uint256 projectID,  string memory imageURL,string memory metaURI, string memory description)
    external pure returns (string memory);

    function getUpdateAccountStatement(string memory metadataTable, uint256 projectID,  string memory imageURL, string memory bannerURI, string memory metaURI, string memory description ,string memory requirements)
    external pure returns (string memory);

    function getDeletePostStatement(string memory metadataTable, uint256 postID)
    external pure returns (string memory);


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
pragma solidity ^0.8.12;
import "./DataTypes.sol";

interface Im3taUser  {

 function createProfile(DataTypes.ProfileTableStruct memory vars) external;

 function updateProfile(uint256 profileId, string calldata imageURI, string memory profileURI, string memory externalURIs) external;
 
 function getProfIdByAddress(address owner) external view returns ( uint256);

 function metadataURI() external view returns (string memory);

 function createProfile1(DataTypes.ProfileTableStruct2 memory vars , uint256[8] calldata proof)  external;



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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
/**
 * @title DataTypes
 * @author M3taDao & Lens Protocol
 *
 * @notice A standard library of data types used throughout the M3TADAO Protocol Which Combines Lens - Valist - Tableland - WorldCoin Contracts.
 */
library DataTypes {   

    struct AccountStruct 
    {
        address founderAddress;
        uint256 id;
        uint    accountID;
        string  accountHex;
        string  accountName;
        string  metaURI;
        string  AccountType;
        string  requirements;
        string  imageURI;
        string  bannerURI;
        string  metadataTable;
        string  description;
        address[] members;
    }
    
    struct ProjectStruct {
        address sender;
        uint256 id;
        uint256 accountID;
        uint256 projectID;
        string  metadataTable;
        string  projectHex;
        string  projectName;
        string  metaURI;
        string  projectType;
        string  imageURI;
        string  description;
        address[] members;
    }

    struct ReleaseStruct 
    {
        address sender;
        uint256 id;
        uint256 releaseID;
        uint256 projectID;
        string metadataTable;
        string releaseHex;
        string releaseName;
        string metaURI;
        string releaseType;
        string imageURI;
        string description;
        string releaseURI;
    }

    struct PostStruct
    {
        address posterAddress;
        uint256 postID;
        string  accountID;
        string  metadataTable;
        string  postDescription;    
        string  postTitle; 
        string  postGalery;
    }


    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData 
    {
        address to;
        string handle;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    struct ProfTableStruct
    {
        string metadataTable;
        uint256 profID;
        string profHex;
        string description;
        string externalURIs;
        string profileURI;
        
    }

    struct ProfileTableStruct
    {
        CreateProfileData profile;
        ProfTableStruct tableData;
    }

    struct ProfileTableStruct2
    {
        CreateProfileData profile;
        ProfTableStruct2 tableData;
    }

    struct ProfTableStruct2{
        string metadataTable;
        uint256 profID;
        string description;
        string groupID;
        string profileURI;
        uint256 root;
        uint256 nullifierHash;
    }
}