// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

contract CryptoQuest is CryptoQuestDeployer {
    constructor(address registry) CryptoQuestDeployer(registry) {}

    /**
     * @dev Generates a checkpoint for a given challengeId
     *
     */
    function createCheckpoint(
        uint256 checkpointId,
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        uint256 iconId,
        string memory lat,
        string memory lng
    ) external payable {
        string memory values = string.concat(
            getUintInQuotes(checkpointId, true),
            getUintInQuotes(challengeId, true),
            getUintInQuotes(ordering, true),
            getStringInQuotes(title, true),
            getStringInQuotes(iconUrl, true),
            getUintInQuotes(iconId, true),
            getStringInQuotes(lat, true),
            getStringInQuotes(lng, true),
            getUintInQuotes(block.timestamp, false)
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            SQLHelpers.toInsert(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                "id, challengeId, ordering, title, iconUrl, lat, lng, creationTimestamp",
                values
            )
        );
    }

    function createCheckpointTrigger(
        uint256 challengeCheckpointId,
        uint256 checkpointId,
        string memory title,
        string memory imageUrl,
        uint8 isPhotoRequired,
        string memory photoDescription,
        uint8 isUserInputRequired,
        string memory userInputDescription,
        string memory userInputAnswer
    ) external payable {
        string memory values = string.concat(
            getUintInQuotes(challengeCheckpointId, true),
            getUintInQuotes(checkpointId, true),
            getStringInQuotes(title, true),
            getStringInQuotes(imageUrl, true),
            getUintInQuotes(isPhotoRequired, true),
            getStringInQuotes(photoDescription, true),
            getUintInQuotes(isUserInputRequired, true),
            getStringInQuotes(userInputDescription, true),
            getStringInQuotes(userInputAnswer, false)
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            SQLHelpers.toInsert(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                "id,checkpointId,title,imageUrl,isPhotoRequired,photoDescription,isUserInputRequired,userInputDescription,userInputAnswer",
                values
            )
        );
    }

    function removeCheckpointTrigger(uint256 challengeCheckpointId)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengeCheckpointId,
            SQLHelpers.toDelete(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                string.concat("id=", Strings.toString(challengeCheckpointId))
            )
        );
    }

    /**
     * @dev Removes a checkpoint
     */
    function removeCheckpoint(uint256 checkpointId) external payable {
        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            SQLHelpers.toDelete(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                string.concat("id = ", Strings.toString(checkpointId))
            )
        );
    }

    function archiveChallenge(uint256 challengeId, uint256 archiveEnum)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "challengeStatus = ",
                    Strings.toString(archiveEnum)
                ),
                string.concat("id = ", Strings.toString(challengeId))
            )
        );
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
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner,
        string memory imagePreviewURL
    ) external payable {
        // preventing jumbled timestamps
        string memory values = string.concat(
            getUintInQuotes(id, true),
            getStringInQuotes(title, true),
            getStringInQuotes(description, true),
            getUintInQuotes(fromTimestamp, true),
            getUintInQuotes(toTimestamp, true),
            getUserAddressAsString(owner, true),
            getUintInQuotes(block.timestamp, true),
            getUintInQuotes(mapSkinId, true),
            getUintInQuotes(0, true),
            getStringInQuotes(imagePreviewURL, false)
        );

        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toInsert(
                challengesPrefix,
                challengesTableId,
                "id,title,description,fromTimestamp,toTimestamp,userAddress,creationTimestamp,mapSkinId,challengeStatus,imagePreviewURL",
                values
            )
        );
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(
        uint256 challengeId,
        address participantAddress
    ) external payable {
        string memory insertStatement = SQLHelpers.toInsert(
            participantsPrefix,
            participantsTableId,
            "userAddress, joinTimestamp, challengeId",
            string.concat(
                getUserAddressAsString(participantAddress, true),
                getUintInQuotes(block.timestamp, true),
                Strings.toString(challengeId)
            )
        );

        _tableland.runSQL(address(this), participantsTableId, insertStatement);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId, uint256 challengeStatus)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "triggerTimestamp= ",
                    Strings.toString(block.timestamp),
                    ",challengeStatus=",
                    Strings.toString(challengeStatus)
                ),
                string.concat("id=", Strings.toString(challengeId))
            )
        );
    }

    function setChallengeWinner(
        uint256 challengeId,
        address challengeWinner,
        uint256 challengeStatus
    ) external payable {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "challengeStatus=",
                    Strings.toString(challengeStatus),
                    ",winnerAddress=",
                    getUserAddressAsString(challengeWinner, false)
                ),
                string.concat("id =", Strings.toString(challengeId))
            )
        );
    }

    function participantProgressCheckIn(
        uint256 challengeCheckpointId,
        address participantAddress
    ) external payable {
        _tableland.runSQL(
            address(this),
            participantsProgressTableId,
            SQLHelpers.toInsert(
                participantProgressPrefix,
                participantsProgressTableId,
                "userAddress, challengeCheckpointId, visitTimestamp",
                string.concat(
                    getUserAddressAsString(participantAddress, true),
                    getUintInQuotes(challengeCheckpointId, true),
                    getUintInQuotes(block.timestamp, false)
                )
            )
        );
    }

    function createNewUser(address userAddress, string memory nickName)
        public
        payable
    {
        _tableland.runSQL(
            address(this),
            usersTableId,
            SQLHelpers.toInsert(
                usersPrefix,
                usersTableId,
                "userAddress, nickname, registeredDate",
                string.concat(
                    getUserAddressAsString(userAddress, true),
                    getStringInQuotes(nickName, true),
                    getUintInQuotes(block.timestamp, false)
                )
            )
        );
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    function getUserAddressAsString(address sender, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat(
            "'",
            Strings.toHexString(uint256(uint160(sender)), 20),
            "'"
        );
        
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }
        
        return toRet;
    }

    function getUintInQuotes(uint256 value, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat(Strings.toString(value));
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }

    function getStringInQuotes(string memory value, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat("'", value, "'");
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./SQLHelpers.sol";

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
    mapping(string => uint256) baseTables;

    // Interface to the `TablelandTables` registry contract
    ITablelandTables internal _tableland;

    constructor(address registry) {
        _tableland = ITablelandTables(registry);
    }
    
    function createBaseTables() public payable onlyOwner {
        mapSkinsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                mapSkinsPrefix,
                "id integer primary key not null, skinName text not null unique, imagePreviewUrl text not null, mapUri text not null unique"
            )
        );

        usersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                usersPrefix,
                "userAddress text not null primary key, nickName text not null, registeredDate integer not null, unique(nickName)"
            )
        );

        challengesTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengesPrefix,
                "id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer, userAddress text not null,creationTimestamp integer not null,mapSkinId integer not null, challengeStatus integer not null, winnerAddress text, imagePreviewURL text unique(title)"
            )
        );

        challengeCheckpointsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointsPrefix,
                "id integer primary key not null, challengeId integer not null, ordering integer not null, title text not null, iconUrl text not null, iconId integer, lat real not null, lng real not null, creationTimestamp integer not null"
            )
        );

        challengeCheckpointTriggersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointTriggerPrefix,
                "id integer primary key not null, checkpointId integer not null, title text not null, imageUrl text not null, isPhotoRequired integer, photoDescription text, isUserInputRequired integer not null, userInputDescription text, userInputAnswer text"
            )
        );

        participantsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantsPrefix,
                "userAddress text not null, joinTimestamp integer not null, challengeId integer not null, unique(userAddress, challengeId)"
            )
        );

        participantsProgressTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantProgressPrefix,
                "userAddress text not null, challengeCheckpointId integer not null, visitTimestamp integer not null, unique(userAddress, challengeCheckpointId)"
            )
        );
    }

    function initiateDataSeed() public payable onlyOwner {
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
                " (",
                createStatement,
                ")"
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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