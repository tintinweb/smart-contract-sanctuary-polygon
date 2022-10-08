// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.11 <0.9.0;
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/ITablelandController.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/SQLHelpers.sol";
import "./Ownable.sol";
import "./IValist.sol";

contract m3taDao is
    Ownable
{


                                    //     @@@@@  @@@@@    @@@@@@@  @@@@@@@   @@@@@@   @@@@@@@      @@@@@@     @@@@@@@    \\
                                    //    @@@@@@@@@@@@@@   @@@@@@@  @@@@@@@  @@@@@@@@  @@@@@@@@    @@@@@@@@   @@@@@@@@@   \\
                                    //    @@!  @@@@  @@@       [email protected]    @@@    @@!  @@@  @@    @@@   @@!  @@@  @@@     @@@  \\
                                    //    [email protected]!  [email protected][email protected]  @[email protected] [email protected]    @@@    [email protected]!  @[email protected]  @@     @@@  [email protected]!  @[email protected] [email protected]!     @[email protected]  \\
                                    //    [email protected]!  @[email protected]!  [email protected]!   @@@@[email protected]    @@@    @[email protected][email protected][email protected]!  @@     @@@  @[email protected][email protected][email protected]!  @[email protected] [email protected]!  \\
                                    //    !!!  !!!!  !!!   @@@@[email protected]    @@@    [email protected]!!!!  @@     @@@  [email protected]!!!!  !!!     !!!  \\
                                    //    !!:  !!!!  !!!       [email protected]    @[email protected]    !!:  !!!  @@     @@@  !!:  !!!  !!:     !!!  \\
                                    //    :!:  :!:!  !:!       [email protected]    @@@    :!:  !:!  @@    @@@   :!:  !:!  :!:     !:!  \\  
                                    //    :::  ::::  :::   @@@@@@@    @@@    ::   :::  @@   @@@    :::  :::  @@@@@@@@@@   \\
                                    //    :::  ::::  :::   @@@@@@@    @@@    ::   :::  @@@@@@@     :::  : :    @@@@@@@    \\

//  @@@  @@@   @@@@@@   @@@       @@@   @@@@@@   @@@@@@@    @@       @@   @@@@@@@   @@@@@@   @@@@@@@   @@@      @@@ ::::  @@@       @@@@@@   @@@       @@@  @@@@@@@     \\
//  @@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@   @@@@@@@     @@     @@    @@@@@@@  @@@@@@@@  @@@@@@@@  @@@      @@@ ::::  @@@      @@@@@@@@  @@@::     @@@  @@@@@@@@    \\
//  @@!  @@@  @@!  @@@  @@!       @@!  [email protected]@         @@!        @@   @@       @@@    @@!  @@@  @@@   @@  @@!      @@!       @@@      @@!  @@@  @@! ::    @@!  @@    @@@   \\
//  [email protected]!  @[email protected] [email protected]!  @[email protected] [email protected]!       [email protected]!  [email protected]!         [email protected]!         @@ @@        @@@    [email protected]!  @[email protected]  @@@   @@  [email protected]!      [email protected]!       @@@      [email protected]!  @[email protected] [email protected]!  ::   [email protected]!  @@     @@@  \\
//  @[email protected] [email protected]!  @[email protected][email protected][email protected]!  @!!       [email protected] [email protected]@!!      @!!         @@@@         @@@    @[email protected][email protected][email protected]!  @@@@@@@@  @!!      @!! ::::  @@@      @[email protected][email protected][email protected]!  @!!   ::  @!!  @@     @@@  \\
//  [email protected]!  !!!  [email protected]!!!!  !!!       !!!   [email protected]!!!     !!!         @@@@         @@@    [email protected]!!!!  @@@@@@@@  !!!      !!! ::::  @@@      [email protected]!!!!  !!!    :: !!!  @@     @@@  \\
//  :!:  !!:  !!:  !!!  !!:       !!:       !:!    !!:        @@  @@        @[email protected]    !!:  !!!  @@@   @@  !!:      !!:       @@@      !!:  !!!  !!:     ::!!:  @@     @@@  \\
//   ::!!:!   :!:  !:!   :!:      :!:      !:!     :!:       @@    @@       @@@    :!:  !:!  @@@   @@  :!:      :!:       @@@      :!:  !:!  :!:      :::!  @@    @@@   \\
//    ::::    ::   :::   :: ::::  :::  :::: ::      ::      @@      @@      @@@    ::   :::  @@@@@@@@  :: ::::  ::: ::::  @@@@@@@  ::   :::  ::        :::  @@   @@@    \\
//     :       :   : :  : :: : :  :::  :: : :       :      @@        @@     @@@    ::   :::  @@@@@@@   :: ::::  ::: ::::  @@@@@@@   :   : :  ::         ::  @@@@@@@     \\
    
    using Counters for Counters.Counter;

    mapping(address => bool) private profileExists;
    mapping(uint => bool) private OrganizationExists;

    Counters.Counter private profileID;
    Counters.Counter private ValistID;
    Counters.Counter private hireID;
    Counters.Counter private proposalID;
    IValist          private valistRegistryContract;
    ITablelandTables private tablelandContract;

    string  private _baseURIString;

    string  private _OrganizationTable;
    uint256 private _OrganizationTableId;
    string private constant M3TADAO_ORGANIZATION_PREFIX = "organization";
    string private constant ORGANIZATION_SCHEMA = "founderAddress text, identifier text, OrganizationID text, groupID text, OrganizationHex text, OrganizationName text, imageURI text, description text";

    string  private _UserTable;
    uint256 private _UserTableId;
    string private constant M3TADAO_PROFILE_PREFIX = "profile";
    string private constant USER_SCHEMA = "userName text, userAddress text, identifier text, userDID text, userName text, imageURI text, description text" ;

    string  private _ProposalTable;
    uint256 private _proposalTableID;
    string private constant QUESTIONS_PREFIX = "proposal";
    string private constant QUESTIONS_SCHEMA = "proposalid text, accountid text, proposer text, body text";

    string  private _VotingTable;
    uint256 private _votingTableID;
    string private constant VOTES_PREFIX = "vote";
    string private constant ANSWERS_SCHEMA = "proposalid text, accountid text, respondent text, vote int, unique(proposalid, respondent)";
        // Tableland Hiring table variables

    string  private _hireTable;
    uint256 private _hiringTableId;
    string private constant HIRE_PREFIX = "hire";
    string private constant HIRE_SCHEMA ="hireID text, profAddress text, accountid text, hireTitle text, hireDescription text, unique(profAddress, accountid)";

    string[] private tableNames;

    address private constant valistLicenceNFTs = 0x3cE643dc61bb40bB0557316539f4A93016051b81;

// 0xD504d012D78B81fA27288628f3fC89B0e2f56e24
    constructor(IValist ValistRegistryContract )
    {
        //@dev setting the external valist contract
        valistRegistryContract = ValistRegistryContract;

        // Creating the M3taDao Tableland Tables on the constructor
        _baseURIString = "https://testnet.tableland.network/query?s=";

        tablelandContract = TablelandDeployments.get();

        // Create m3tadao organizations table.
        _OrganizationTableId = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(ORGANIZATION_SCHEMA, M3TADAO_ORGANIZATION_PREFIX)
        );

        _OrganizationTable = SQLHelpers.toNameFromId(M3TADAO_ORGANIZATION_PREFIX, _OrganizationTableId);
        // Create m3tadao users profile table.
        _UserTableId = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(USER_SCHEMA , M3TADAO_PROFILE_PREFIX)
        );

        _UserTable = SQLHelpers.toNameFromId(M3TADAO_PROFILE_PREFIX, _UserTableId);

        // Create proposals table for organizations.
        _proposalTableID = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(QUESTIONS_SCHEMA, QUESTIONS_PREFIX)
        );

        _ProposalTable = SQLHelpers.toNameFromId(QUESTIONS_PREFIX, _proposalTableID);

        // Create voting table on top of proposals.
        _votingTableID = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(ANSWERS_SCHEMA, VOTES_PREFIX)
        );

        _VotingTable = SQLHelpers.toNameFromId(QUESTIONS_PREFIX, _votingTableID);

        // Create hiring table for users to join organizations.
        _hiringTableId = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(HIRE_SCHEMA, HIRE_PREFIX)
           
        );

        _hireTable = SQLHelpers.toNameFromId(HIRE_PREFIX, _hiringTableId);


    }

        // Function for creating posts for an Organization 
    function indexProfile(string memory profiledid , string memory userName , string memory imageURI , string memory description) public {
        // only one profile per address
        require(profileExists[msg.sender] == false , "only one profile per address");

        profileExists[msg.sender] = true;

        profileID.increment();

        string memory statement =
        SQLHelpers.toInsert(
                M3TADAO_PROFILE_PREFIX,
                _UserTableId,
                "userAddress, identifier, userDID, userName, imageURI, description",
                string.concat(
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote(Strings.toString(profileID.current())),
                    ",",
                    SQLHelpers.quote(profiledid),
                    ",",
                    SQLHelpers.quote(userName),
                    ",",
                    SQLHelpers.quote(imageURI),
                    ",",
                    SQLHelpers.quote(description)
                )
            );
        runSQL(_UserTableId,statement);      
    }       
        
    

    // Creating a Valist Organization/Organization
    function indexProjectOrganization(uint OrganizationID, string memory groupID, string memory OrganizationName , string memory imageURI , string memory description)
        public  
    {
        // require(isOrganizationMember(OrganizationID,msg.sender) && OrganizationExists[OrganizationID] == false);

        string memory OrganizationHex = Strings.toHexString(OrganizationID);

        ValistID.increment();

        string memory statement =
        SQLHelpers.toInsert(
                M3TADAO_ORGANIZATION_PREFIX,
                _OrganizationTableId,
                "founderAddress, identifier, OrganizationID, groupID, OrganizationHex, OrganizationName, imageURI, description",
                string.concat(
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote(Strings.toString(ValistID.current())),
                    ",",
                    SQLHelpers.quote(Strings.toString(OrganizationID)),
                    ",",
                    SQLHelpers.quote(groupID),
                    ",",
                    SQLHelpers.quote(OrganizationHex),
                    ",",
                    SQLHelpers.quote(OrganizationName),
                    ",",
                    SQLHelpers.quote(imageURI),
                    ",",
                    SQLHelpers.quote(description)
                )
            );
        runSQL(_OrganizationTableId,statement);      
    }

    function Proposal(
            uint256 accountID,
            string memory proposal_CID
        ) external {

            // require(
            //     IERC1155(valistLicenceNFTs).balanceOf(msg.sender,accountID) > 0 || isOrganizationMember(accountID,msg.sender),
            //     "sender is not token owner OR organization Member"
            // );
            proposalID.increment();
            string memory statement =
                SQLHelpers.toInsert(
                    VOTES_PREFIX,
                    _votingTableID,
                    "proposalid, accountid, proposer, body",
                    string.concat(
                        SQLHelpers.quote(Strings.toString(proposalID.current())),
                        ",",
                        SQLHelpers.quote(Strings.toString(accountID)),
                        ",",
                        SQLHelpers.quote(Strings.toHexString(msg.sender)),
                        ",",
                        SQLHelpers.quote(proposal_CID)
                    )
                );
                runSQL(_votingTableID,statement);      

            
    }

    function Vote(
        uint256 qid,
        uint256 accountID,
        bool vote
    ) external {

        // require(
        //     IERC1155(valistLicenceNFTs).balanceOf(msg.sender,accountID) > 0,
        //     "sender is not token owner"
        // );
        string memory statement =
            SQLHelpers.toInsert(
                VOTES_PREFIX,
                _votingTableID,
                "qid,accountid,respondent,vote",
                string.concat(
                    SQLHelpers.quote(Strings.toString(qid)),
                    ",",
                    SQLHelpers.quote(Strings.toString(accountID)),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    vote ? "1" : "0"
                )
            );
            runSQL(_votingTableID,statement);      

        
    }

     function createHiringRequest(uint accountID , string memory hireTitle , string memory hireDescription) public  {

        // Only M3taDao Users can make a Hire request to an Organization
        require(
            profileExists[msg.sender] == true,
            "only m3taDao users can create a Hiring Request"
        );

        hireID.increment();

        string memory statement =
            SQLHelpers.toInsert(
                HIRE_PREFIX,
                _hiringTableId,
                "hireID, profAddress, accountid, hireTitle, hireDescription",
                string.concat(
                    SQLHelpers.quote(Strings.toString(hireID.current())),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(msg.sender)),
                    ",",
                    SQLHelpers.quote(Strings.toString(accountID)),
                    ",",
                    SQLHelpers.quote(hireTitle),
                    ",",
                    SQLHelpers.quote(hireDescription)
                )
            );
            runSQL(_votingTableID,statement); 

    }

    function rejectHiringRequest( uint256 hireId) public {
        // require(isOrganizationMember(accountID,msg.sender) , "Only post creators and account members can Reject a Hiring Request");

        string memory filter = string.concat("hireID=",Strings.toString(hireId));

        string memory statement = SQLHelpers.toDelete(HIRE_PREFIX, _hiringTableId, filter);

         runSQL(_hiringTableId,statement);
        
    }

    // Function to make Insertions , Updates and Deletions to our Tableland Tables 
    function runSQL(uint256 tableID, string memory statement) private{
         tablelandContract.runSQL(
            address(this),
            tableID,
            statement        
        );
    }


    function m3tadaoTableNames() 
    public view returns (string[] memory) {
        return tableNames;
    }

    function TableURI(string memory tableName) 
    public view returns (string memory) {
        return string.concat(
            _baseURI(), 
            "SELECT%20*%20FROM%20",
            tableName
        );
    }

    function getQuestionsTable() public view returns (string memory) {
        return SQLHelpers.toNameFromId(QUESTIONS_PREFIX, _proposalTableID);
    }

    // Return the answers table name
    function getAnswersTable() public view returns (string memory) {
        return SQLHelpers.toNameFromId(VOTES_PREFIX, _votingTableID);
    }

    function _baseURI() internal view returns (string memory) {
        return _baseURIString;
    }
    // Setting tableland BaseUri for future updates!!!
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIString = baseURI;
    }


    function isOrganizationMember(uint _OrganizationID,address member) internal view returns (bool) {
       return  valistRegistryContract.isAccountMember(_OrganizationID,member);
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

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Library of helpers for generating SQL statements from common parameters.
 */
library SQLHelpers {
    /**
     * @dev Generates a properly formatted table name from a prefix and table id.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toNameFromId(string memory prefix, uint256 tableId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "_",
                    Strings.toString(tableId)
                )
            );
    }

    /**
     * @dev Generates a CREATE statement based on a desired schema and table prefix.
     *
     * schema - a comma seperated string indicating the desired prefix. Example: "int id, text name"
     * prefix - the user generated table prefix as a string
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toCreateFromSchema(string memory schema, string memory prefix)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "CREATE TABLE ",
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "(",
                    schema,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - a string encoded ordered list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    "(",
                    columns,
                    ")VALUES(",
                    values,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - an array where each item is a string encoded ordered list of values.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toBatchInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string[] memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory insert = string(
            abi.encodePacked("INSERT INTO ", name, "(", columns, ")VALUES")
        );
        for (uint256 i = 0; i < values.length; i++) {
            if (i == 0) {
                insert = string(abi.encodePacked(insert, "(", values[i], ")"));
            } else {
                insert = string(abi.encodePacked(insert, ",(", values[i], ")"));
            }
        }
        return insert;
    }

    /**
     * @dev Generates an Update statement based on table prefix, tableId, setters, and filters.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     * setters - a string encoded set of updates. Example: "name='tom', age=26"
     * filters - a string encoded list of filters or "" for no filters. Example: "id<2 and name!='jerry'"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toUpdate(
        string memory prefix,
        uint256 tableId,
        string memory setters,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory filter = "";
        if (bytes(filters).length > 0) {
            filter = string(abi.encodePacked(" WHERE ", filters));
        }
        return
            string(abi.encodePacked("UPDATE ", name, " SET ", setters, filter));
    }

    /**
     * @dev Generates a Delete statement based on table prefix, tableId, and filters.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * filters - a string encoded list of filters. Example: "id<2 and name!='jerry'".
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toDelete(
        string memory prefix,
        uint256 tableId,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }

    /**
     * @dev Add single quotes around a string value
     *
     * input - any input value.
     *
     */
    function quote(string memory input) internal pure returns (string memory) {
        return string(abi.encodePacked("'", input, "'"));
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
     * - `msg.sender` must be `caller` or contract owner and owner of `tableId`
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
     * - `msg.sender` must be `caller` or contract owner and owner of `tableId`
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

    // TablelandTables address on Ethereum.
    address internal constant MAINNET =
        0x012969f7e3439a9B04025b5a049EB9BAD82A8C12;
    // TablelandTables address on Optimism.
    address internal constant OPTIMISTIC_ETHEREUM =
        0xfad44BF5B843dE943a09D4f3E84949A11d3aa3e6;
    // TablelandTables address on Polygon.
    address internal constant POLYGON =
        0x5c4e6A9e5C1e1BF445A062006faF19EA6c49aFeA;

    // TablelandTables address on Ethereum Goerli.
    address internal constant GOERLI =
        0xDA8EA22d092307874f30A1F277D1388dca0BA97a;
    // TablelandTables address on Optimism Kovan.
    address internal constant OPTIMISTIC_KOVAN =
        0xf2C9Fc73884A9c6e6Db58778176Ab67989139D06;
    // TablelandTables address on Optimism Goerli.
    address internal constant OPTIMISTIC_GOERLI =
        0xC72E8a7Be04f2469f8C2dB3F1BdF69A7D516aBbA;
    // TablelandTables address on Arbitrum Goerli.
    address internal constant ARBITRUM_GOERLI =
        0x033f69e8d119205089Ab15D340F5b797732f646b;
    // TablelandTables address on Polygon Mumbai.
    address internal constant POLYGON_MUMBAI =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;

    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * The selection order is meant to reduce gas on more expensive chains.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 1) {
            return ITablelandTables(MAINNET);
        } else if (block.chainid == 10) {
            return ITablelandTables(OPTIMISTIC_ETHEREUM);
        } else if (block.chainid == 137) {
            return ITablelandTables(POLYGON);
        } else if (block.chainid == 5) {
            return ITablelandTables(GOERLI);
        } else if (block.chainid == 69) {
            return ITablelandTables(OPTIMISTIC_KOVAN);
        } else if (block.chainid == 420) {
            return ITablelandTables(OPTIMISTIC_GOERLI);
        } else if (block.chainid == 421613) {
            return ITablelandTables(ARBITRUM_GOERLI);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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