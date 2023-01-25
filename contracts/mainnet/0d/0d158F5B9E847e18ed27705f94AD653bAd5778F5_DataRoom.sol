/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library with immutable args operations.
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibClone.sol)
library LibClone {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// -----------------------------------------------------------------------
    /// Clone Operations
    /// -----------------------------------------------------------------------

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable arguments encoded in `data`, with `salt`.
    function cloneDeterministic(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`.
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(
                0,
                sub(data, 0x4c),
                add(extraLength, 0x6c),
                salt
            )

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(
                    shl(0x48, extraLength),
                    0x593da1005b363d3d373d3d3d3d610000806062363936013d73
                )
            )
            // `keccak256("ReceiveETH(uint256)")`.
            mstore(
                sub(data, 0x3a),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(
                    shl(0x78, add(extraLength, 0x62)),
                    0x6100003d81600a3d39f336602c57343d527f
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            mstore(0x35, keccak256(sub(data, 0x4c), add(extraLength, 0x6c)))
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }
}

/// @notice Keep Factory.
contract DataRoomFactory {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using LibClone for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Deployed(
        DataRoom indexed dataRoom
    );

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    DataRoom internal immutable dataRoomTemplate;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(DataRoom _dataRoomTemplate) payable {
        dataRoomTemplate = _dataRoomTemplate;
    }

    /// -----------------------------------------------------------------------
    /// Deployment Logic
    /// -----------------------------------------------------------------------

    function determineKeep(bytes32 name) public view virtual returns (address) {
        return
            address(dataRoomTemplate).predictDeterministicAddress(
                abi.encodePacked(name),
                name,
                address(this)
            );
    }

    function deployDataRoom(
        bytes32 name // create2 salt.
    ) public payable virtual {
        DataRoom dr = DataRoom(
            address(dataRoomTemplate).cloneDeterministic(
                abi.encodePacked(name),
                name
            )
        );

        dr = new DataRoom();

        emit Deployed(dr);
    }
}

/// @title DataRoom
/// @notice Data room for on-chain orgs.
/// @author audsssy.eth
contract DataRoom {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event PermissionSet(
        address indexed dao,
        address indexed account,
        bool permissioned
    );

    event RecordSet (
        address indexed dao,
        string data,
        address indexed caller
    );  
   
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    error LengthMismatch();

    error InvalidRoom();

    /// -----------------------------------------------------------------------
    /// DataRoom Storage
    /// -----------------------------------------------------------------------

    mapping(address => string[]) public room;

    mapping(address => mapping(address => bool)) public authorized;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() payable {}

    /// -----------------------------------------------------------------------
    /// DataRoom Logic
    /// -----------------------------------------------------------------------

    /// @notice Record data on-chain.
    /// @param account Identifier of a Room.
    /// @param data The data to record.
    /// @dev Calls are permissioned to those authorized to access a Room.
    function setRecord(
        address account, 
        string[] calldata data
    ) 
        public 
        payable
        virtual
    {
        // Initialize Room.
        if (account == msg.sender && !authorized[account][msg.sender]) {
            authorized[account][msg.sender] = true;
        }
        
        _authorized(account, msg.sender);

        for (uint256 i; i < data.length; ) {
            room[account].push(data[i]);
            
            emit RecordSet(account, data[i], msg.sender);
            
            // Unchecked because the only math done is incrementing
            // the array index counter which cannot possibly overflow.
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Retrieve data from a Room.
    /// @param account Identifier of a Room.
    /// @return The array of data associated with a Room.
    function getRoom(address account) 
        public 
        view
        virtual
        returns (string[] memory) 
    {
        return room[account];
    }

    /// @notice Initialize a Room or authorize users to a Room.
    /// @param account Identifier of a Room.
    /// @param users Users to be authorized or deauthorized to access a Room.
    /// @param authorize Authorization status.
    /// @dev Calls are permissioned to the authorized accounts of a Room.
    function setPermission(
        address account,
        address[] calldata users,
        bool[] calldata authorize
    ) 
        public 
        payable
        virtual
    {  
        if (account == address(0)) revert InvalidRoom();

        // Initialize Room.
        if (account == msg.sender && !authorized[account][msg.sender]) {
            authorized[account][msg.sender] = true;
        }
        
        _authorized(account, msg.sender);

        uint256 numUsers = users.length;

        if (numUsers != authorize.length) revert LengthMismatch();

        if (numUsers != 0) {
            for (uint i; i < numUsers; ) {
                authorized[account][users[i]] = authorize[i];
                
                emit PermissionSet(account, users[i], authorize[i]);
                
                // Unchecked because the only math done is incrementing
                // the array index counter which cannot possibly overflow.
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /// @notice Helper function to check access to a Room.
    /// @param account Identifier of a Room.
    /// @param user The user in question.
    function _authorized(address account, address user) internal view virtual returns (bool) {
        if (authorized[account][user]) return true;
        else revert Unauthorized();
    }
}