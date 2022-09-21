/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/SQLHelpers.sol


pragma solidity ^0.8.17;


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
        public
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
     * prefix - the user generated table prefix as a string
     * schema - a comma seperated string indicating the desired prefix. Example: "int id, text name"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toCreateFromSchema(string memory prefix, string memory schema)
        public
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
                    " (",
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
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    " (",
                    columns,
                    ") VALUES (",
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
     * values - a string encoded ordered list of list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsertMultipleRows(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string memory values
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    " (",
                    columns,
                    ") VALUES ",
                    values
                )
            );
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
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
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
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @tableland/evm/contracts/ITablelandController.sol


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

// File: @tableland/evm/contracts/ITablelandTables.sol


pragma solidity ^0.8.4;


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

// File: contracts/CryptoQuestDeployer.sol


pragma solidity ^0.8.17;






contract CryptoQuestDeployer is Ownable, ERC721Holder {
    // base tables
    string mapSkinsPrefix = "mapSkins";
    uint256 mapSkinsTableId;

    string usersPrefix = "users";
    uint256 usersTableId;

    string challengesPrefix = "challenges";
    uint256 challengesTableId;

    string challengeCheckpointsPrefix = "challengeCheckpoints";
    uint256 challengeCheckpointsTableId;

    string challengeCheckpointTriggerPrefix = "challengeCheckpointTriggers";
    uint256 challengeCheckpointTriggersTableId;

    string participantsPrefix = "participants";
    uint256 participantsTableId;

    string participantProgressPrefix = "participantProgress";
    uint256 participantsProgressTableId;

    // additional tables
    mapping(string => uint256) customTables;

    // Interface to the `TablelandTables` registry contract
    ITablelandTables internal _tableland;

    constructor() {

    }

    function initializeBaseTables(address registry) public payable onlyOwner {
        _tableland = ITablelandTables(registry);
        mapSkinsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                mapSkinsPrefix,
                "(id integer primary key not null, skinName text not null, imagePreviewUrl text not null, mapUri text not null, unique(mapUri), unique(skinName))"
            )
        );

        usersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                usersPrefix,
                "(userAddress text not null primary key, nickName text not null, registeredDate integer not null, unique(userAddress, nickName))"
            )
        );

        challengesTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengesPrefix,
                "(id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer,userAddress text not null,creationTimestamp integer not null,mapSkinId integer not null, challengeStatus integer not null, unique(title))"
            )
        );

        challengeCheckpointsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointsPrefix,
                "(id integer primary key not null, challengeId integer not null, ordering integer not null, title text not null, iconUrl text unique not null, lat real not null, lng real not null, creationTimestamp integer not null)"
            )
        );

        challengeCheckpointTriggersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointTriggerPrefix,
                "(id integer primary key not null, checkpointId integer not null, title text not null, imageUrl text not null, isPhotoRequired integer null, photoDescription text null, isUserInputRequired integer not null, userInputDescription text null, userInputAnswer text null)"
            )
        );

        participantsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantsPrefix,
                "(id integer primary key not null, userAddress text not null, joinTimestamp integer not null, challengeId integer not null, unique(userAddress, challengeId)"
            )
        );

        participantsProgressTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "participant_progress",
                "(id integer primary key not null, participantId integer not null, challengeCheckpointId integer not null, visitTimestamp integer not null, unique(challenge_participant_id, challenge_location_id))"
            )
        );

        // running data seeds
        mapSkinsDataSeed();
    }

    function mapSkinsDataSeed() private onlyOwner {
        string memory multipleRowsStatement = SQLHelpers.toInsertMultipleRows(
            mapSkinsPrefix,
            mapSkinsTableId,
            "skinName, imagePreviewUrl, mapUri",
            string.concat(
                "('Standard', 'https://api.mapbox.com/styles/v1/juvie22/cjtizpqis1exb1fqunbiqcw4y/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtizpqis1exb1fqunbiqcw4y'),",
                "('Comics', 'https://api.mapbox.com/styles/v1/juvie22/cjvdxmakw0fqh1fp8z47jqge5/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvdxmakw0fqh1fp8z47jqge5'),",
                "('Neon', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9'),",
                "('Blueprint', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxaacd3ncv1cqvd6edffc2/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxaacd3ncv1cqvd6edffc2'),",
                "('Western', 'https://api.mapbox.com/styles/v1/juvie22/cjvuwejv70iaw1cqnb846caqy/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuwejv70iaw1cqnb846caqy'),",
                "('Candy', 'https://api.mapbox.com/styles/v1/juvie22/cjvuvwhv90rhn1cpbpgactgnm/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuvwhv90rhn1cpbpgactgnm'),",
                "('Noir', 'https://api.mapbox.com/styles/v1/juvie22/cjtj02zko4xbc1fpkv8dtolu3/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtj02zko4xbc1fpkv8dtolu3'),",
                "('Virus', 'https://api.mapbox.com/styles/v1/juvie22/cj7i2ftv34zpd2smtm3ik41fq/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cj7i2ftv34zpd2smtm3ik41fq')"
            )
        );

        _tableland.runSQL(
            address(this),
            mapSkinsTableId,
            multipleRowsStatement
        );
    }

    function createCustomTable(
        string memory prefix,
        string memory createStatement
    ) public payable onlyOwner returns (string memory) {
        uint256 tableId = _tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                prefix,
                "_",
                Strings.toString(block.chainid),
                " ",
                createStatement
            )
        );

        string memory tableName = string.concat(
            prefix,
            "_",
            Strings.toString(block.chainid),
            "_",
            Strings.toString(tableId)
        );

        customTables[tableName] = tableId;

        return tableName;
    }

    receive() external payable {}

    fallback() external payable {}
}

// File: contracts/CryptoQuest.sol


pragma solidity ^0.8.17;


// todo: re-entrancy attack prevention
// toDo: stop spamming STrings.bs this will cause extra gas units, just extract them to the upper lines of the function into memory vars, cheaper and cleanier

contract CryptoQuest is CryptoQuestDeployer {
    // Creation Events
    event ChallengeCreated(address indexed _userAddress, string title);
    event ParticipantJoined(address indexed _userAddress, uint256 challengeId);
    event CheckpointCreated(address indexed _userAddress, string title);

    constructor() payable {
        
    }

    /**
     * @dev Generates a checkpoint for a given challengeId
     *
     */
    function createCheckpoint(
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng
    ) public payable validChallengeId(challengeId) {

        string memory currentTimestamp = Strings.toString(block.timestamp);
        
        string memory checkPointTableName = getChallengeCheckpointsTableName();
        string memory challengeIdStr = Strings.toString(challengeId);

        string memory checkpointInsertStatement = string.concat(
            "insert into ",
            checkPointTableName,
            " (challengeId, ordering, title, iconUrl, lat, lng, creationTimestamp)",
            " select cll.id, case when c.ordering is null then column1 else null) as ordering, column2, column3, column4, column5, ", currentTimestamp,",",
            " from (values(", Strings.toString(ordering), 
            ",'", title, "','", iconUrl,"',", lat,",", lng,
            ")) v"
        );

        string memory leftJoin1 = string.concat(
            " left join ", getChallengesTableName() ," cll on cll.id = ", challengeIdStr, " and cll.userAddress = '", getUserAddressAsString(), "'" 
        );

        string memory leftJoin2 = string.concat(
            " left join ", checkPointTableName, "c on c.ordering != ", Strings.toString(ordering), " and c.challengeId = ", challengeIdStr
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            string.concat(
                checkpointInsertStatement,
                leftJoin1,
                leftJoin2
            )
        );
    }

    /**
     * @dev Removes a checkpoint
     * limits --> will not be able to throw errors since I can't make SQLite crash w/ an error :/ on deletes
     * will need to dig deeper once MVP is done
     * title - checkpointId
     *
     */
    function removeCheckpoint(uint256 checkpointId) public payable {
        string memory checkpointIdStr = Strings.toString(checkpointId);

        string memory deleteCheckpointStatement = string.concat(
            "delete from ", getChallengeCheckpointsTableName(),
            " where id =", checkpointIdStr,
            " and checkpointId = ", checkpointIdStr,
            " and challengeId in (select id from ", getChallengesTableName(), " where userAddress='", getUserAddressAsString() ,")",
            " and id not in (select id from ", getCheckpointTriggersTableName(), ", where checkpointId = ", checkpointIdStr, ")"
        );

        _tableland.runSQL(address(this), challengeCheckpointsTableId, deleteCheckpointStatement);
    }

    /**
     * @dev Generates a challenge
     *
     * title - Title of the challenge. [mandatory]
     * description - Description of the challenge. [mandatory]
     * fromTimestamp - unix epoch which indicates the start of the challenge. [mandatory]
     * toTimestamp - unix epoch which indicates when the challenge will end. [mandatory]
     * mapSkinId - skinId from skins table [mandatory]
     *
     */

    function createChallenge(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) public payable {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        // can't create things in the past lmao
        require(
            block.timestamp < fromTimestamp,
            "Cannot set a range for the past !"
        );

        // can't create a challenge with a diff < 8 h, maybe we should have it configurable from UI ?
        require(
            toTimestamp - fromTimestamp < 8 hours,
            "Can't create a challenge that'll last fewer than one hour !"
        );

        string memory insertStatement = SQLHelpers.toInsert(
            challengesPrefix,
            challengesTableId,
            'title,description,fromTimestamp,toTimestamp,userAddress,creationTimestamp,mapSkinId,challengeStatus,mapSkinId',
            string.concat(
                "'",
                title,
                "','",
                description,
                "',",
                Strings.toString(fromTimestamp),
                ",",
                Strings.toString(toTimestamp),
                ",'",
                getUserAddressAsString(),
                "',",
                Strings.toString(block.timestamp),
                "','",
                Strings.toString(mapSkinId)
            )
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ChallengeCreated(msg.sender, title);
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
    */

    function participateInChallenge(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory participantsTableName = getParticipantsTableName();

        string memory insertStatement = string.concat(
            "insert into ",
            participantsTableName,
            " (participant_address, joinTimestamp, challengeId)",
            " select case when c.userAddress == v.column1 or pa.id is not null or usr is null then null else column1 end, column2, c.id",
            " from ( values ( '", getUserAddressAsString(),
            "',",
            Strings.toString(block.timestamp),
            ", ",
            Strings.toString(challengeId),
            ") ) v",
            // we must ensure ppl don't join while thing's started lmao
            " left join ", getChallengesTableName() ," c on v.column3 = c.id and ",
            "(c.triggerTimestamp > v.column2 or c.triggerTimestamp is null)",
            " left join ", participantsTableName, " pa on column1 = pa.participant_address",
            " left join ", getUsersTableName() ," usr on usr.userAddress = pa.participant_address"
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ParticipantJoined(msg.sender, challengeId);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
    */
     function triggerChallengeStart(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory currentTimestamp = Strings.toString(block.timestamp);
        string memory filter = string.concat(
                "id=",
                Strings.toString(challengeId),
                // only the owner can do it
                " and userAddress=",
                getUserAddressAsString(),
                // cannot alter an already started challenge && cannot be out of bounds
                " and triggerTimestamp is null and fromTimestamp <=", currentTimestamp, " and toTimestamp >= ", currentTimestamp,
                // at least one POI challenge exists
                " and exists (select 'ex' from ", getChallengeCheckpointsTableName(), ", where challengeId = ", Strings.toString(challengeId), ")"
                // at least one challenger has to participate
                " and exists (select 'ex' from ", getParticipantsTableName(), " where challengeId = ", Strings.toString(challengeId),")"
            );

        string memory updateStatement = SQLHelpers.toUpdate(
            challengesPrefix,
            challengesTableId,
            string.concat(
                "triggerTimestamp= ",
                Strings.toString(block.timestamp)
            ),
            filter
        );

        _tableland.runSQL(address(this), challengesTableId,  updateStatement);
    }

    function participantProgressCheckIn(uint256 challengeCheckpointId) public payable  {
        string memory userAddress = Strings.toHexString(uint256(uint160(msg.sender)), 20);
        string memory currentTimestamp = Strings.toString(block.timestamp);

        string memory insertStatement = string.concat(
            "insert into ", getParticipantProgressTableName(),
            " (participantId, challengeCheckpointId, visitTimestamp)",
            " select c.userAddress, cc.id, column3",
            " from ( values ( '", userAddress, "',", Strings.toString(challengeCheckpointId), ", ", currentTimestamp,") ) v",
            " left join ", getChallengeCheckpointsTableName(), " cc on cc.id=v.column2",
            " left join ", getChallengesTableName(), " c on c.id = cc.challengeId",
            " left join ", getParticipantsTableName(), "p on p.challengeId = c.challengeId and p.userAddress = v.column1"
        );

        _tableland.runSQL(address(this), participantsProgressTableId, insertStatement);
    }

    function createNewUser(string memory nickName) public payable {
        string memory currentTimestamp = Strings.toString(block.timestamp);

        string memory insertStatement = 
            SQLHelpers.toInsert
                (
                    usersPrefix, 
                    usersTableId, 
                    "userAddress, nickname, registeredDate",
                    string.concat("'", getUserAddressAsString(), "', '", nickName, "', ", currentTimestamp)
                );

        _tableland.runSQL(address(this), usersTableId, insertStatement);
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    function getUserAddressAsString() private view returns (string memory) {
         return Strings.toHexString(
            uint256(uint160(msg.sender)),
            20
        );
    }

    function getCheckpointTriggersTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId(
            challengeCheckpointTriggerPrefix,
            challengeCheckpointTriggersTableId
        );
    }

    function getUsersTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId(
            usersPrefix,
            usersTableId
        );
    }

    function getChallengesTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId(
            challengesPrefix,
            challengesTableId
        );
    }

    function getParticipantsTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId (
            participantsPrefix,
            participantsTableId
        );
    }

    function getChallengeCheckpointsTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId
        );
    }

    function getParticipantProgressTableName() private view returns (string memory) {
        return SQLHelpers.toNameFromId(
            participantProgressPrefix,
            participantsProgressTableId
        );
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    // ------------------------------------------ Modifiers ------------------------------------------------

    modifier validChallengeId(uint256 _challengeId) {
        require(_challengeId > 0, "invalid challenge id");
        _;
    }

    // ------------------------------------------ Modifiers ------------------------------------------------
}