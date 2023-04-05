//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8
      0x05  0xf3  0xf3                  RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr
  */
  
  bytes internal constant PROXY_CHILD_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    return create3(_salt, _creationCode, 0);
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode, uint256 _value) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (codeSize(addr) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success,) = proxy.call{ value: _value }(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {Create3} from "@0xsequence/create3/contracts/Create3.sol";

import {RegistrationFeeInfo} from "src/interfaces/IPaidPredictableCompetition.sol";
import {ICompetitionFactory, CompetitionImpl, CompetitionInfo} from "src/interfaces/ICompetitionFactory.sol";

/// @title Competition Factory
/// @author BRKT
/// @notice Contract used to create and retrieve competition contracts and info
contract CompetitionFactory is ICompetitionFactory, Ownable {

    error CompetitionAlreadyExists(bytes32 _competitionId);
    error InvalidCompetitionImpl(CompetitionImpl _competitionImpl);
    error NoCreationCodeForImpl(CompetitionImpl _competitionImpl);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /**
     * @dev Input bytes32: The competition ID
     *      Output CompetitionInfo: The competition details (address and type, etc.)
     */
    mapping(bytes32 => CompetitionInfo) internal _competitions;

    mapping(CompetitionImpl => address) internal _contractCodes;

    /**
     * @dev The fee associated to running a competition, in bps
     */
    uint256 protocolFee;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /**
     * @inheritdoc ICompetitionFactory
     */
    function createCompetition(bytes32 _competitionId, uint16 _numTeams, uint64 _expirationEpoch, CompetitionImpl _competitionImpl, string[] memory _teamNames) public override returns(address addr_) {
        if(_competitionImpl != CompetitionImpl.BASE && _competitionImpl != CompetitionImpl.PREDICTABLE) {
            revert InvalidCompetitionImpl(_competitionImpl);
        }
        CompetitionInfo storage info = _initializeCompetition(_competitionId);
        info.impl = _competitionImpl;
        if(_competitionImpl == CompetitionImpl.BASE) {
            info.addr = Create3.create3(
                _competitionId,
                abi.encodePacked(
                    _getCreationCode(CompetitionImpl.BASE),
                    abi.encode(_numTeams, _expirationEpoch, _teamNames)
                )
            );
        } else if(_competitionImpl == CompetitionImpl.PREDICTABLE) {
            info.addr = Create3.create3(
                _competitionId,
                abi.encodePacked(
                    _getCreationCode(CompetitionImpl.PREDICTABLE),
                    abi.encode(_numTeams, _expirationEpoch, _teamNames)
                )
            );
        }
        addr_ = info.addr;
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function createPaidPredictableCompetition(
        bytes32 _competitionId,
        uint16 _numTeams,
        uint64 _expirationEpoch,
        RegistrationFeeInfo calldata _feeInfo,
        string[] memory _teamNames
    ) public override returns(address addr_) {
        CompetitionInfo storage info = _initializeCompetition(_competitionId);
        info.impl = CompetitionImpl.PAID_PREDICTABLE;
        info.addr = Create3.create3(
            _competitionId,
            abi.encodePacked(
                _getCreationCode(CompetitionImpl.PAID_PREDICTABLE),
                abi.encode(_numTeams, _expirationEpoch, _feeInfo, _teamNames)
            )
        );
        addr_ = info.addr;
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function setProtocolFee(uint256 _feeBps) public onlyOwner {
        protocolFee = _feeBps;
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function setContractCode(CompetitionImpl _impl, bytes memory _code) public onlyOwner {
        _contractCodes[_impl] = SSTORE2.write(_code);
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function getCompetitionInfo(bytes32 _competitionId) external view returns(CompetitionInfo memory info_) {
        info_ = _competitions[_competitionId];
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function getCompetitionAddress(bytes32 _competitionId) external view returns(address addr_) {
        addr_ = _competitions[_competitionId].addr;
    }

    /**
     * @inheritdoc ICompetitionFactory
     */
    function getCompetitionImplType(bytes32 _competitionId) external view returns(CompetitionImpl impl_) {
        impl_ = _competitions[_competitionId].impl;
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function _initializeCompetition(bytes32 _competitionId) internal view returns(CompetitionInfo storage info_) {
        info_ = _competitions[_competitionId];
        if(info_.addr != address(0)) {
            revert CompetitionAlreadyExists(_competitionId);
        }
    }

    function _getCreationCode(CompetitionImpl _competitionImpl) internal view returns(bytes memory code_) {
        if(_contractCodes[_competitionImpl] == address(0)) {
            revert NoCreationCodeForImpl(_competitionImpl);
        }
        code_ = SSTORE2.read(_contractCodes[_competitionImpl]);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- MODIFIERS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Struct to wrap a match outcome for a competition. Needed to ensure team id 0 isn't misunderstood
 *  when assessing the winning team id
 * @param winningTeamId The team id of the winning team. This is the index of the team name in the teamNames array
 * @param isCompleted Whether or not the match has been completed
 */
struct MatchOutcome {
    uint8 winningTeamId;
    bool isCompleted;
}

/// @title Competition Interface
/// @notice Manages Competition round progression, registration, etc
interface ICompetition {
    /**
     * @dev Emitted when a match is completed. Must be a match in the current round and the match must not be completed
     * @param _matchId The id of the match that was completed
     * @param _winningTeamId The team id of the winning team.
     */
    event MatchCompleted(uint256 indexed _matchId, uint8 indexed _winningTeamId);
    /**
     * @dev Owner only function to start the competition, which allows for progression submissions
     */
    function start() external;
    /**
     * @dev Owner only function to set the team names
     * @param _names List of names for the teams. This is what communicates the team order and match-up apart
     *  from simply "0 vs 1" which could be mistaken as a different team than it is.
     */
    function setTeamNames(string[] calldata _names) external;
    /**
     * @dev Owner only function to submit the results of a match
     */
    function completeMatch(uint256 _matchId, uint8 _winningTeamId) external;
    /**
     * @dev Owner only function to progress to the next round
     */
    function advanceRound(uint8[] calldata _matchResults) external;
    /**
     * @dev Owner only function to progress to the next round. Requires every match in the current round to be completed
     */
    function advanceRound() external;
    /**
     * @dev Returns the current progression of this competition. Each MatchOutcome is the outcome of the match at the array index
     */
    function getCompetitionProgression() external view returns(MatchOutcome[] memory bracketProgress_);
    /**
     * @dev Returns the MatchOutcome for the given match id. Will be default values if the
     *  match is incomplete or out of the bounds of the competition
     */
    function getMatchOutcome(uint256 _matchId) external view returns(MatchOutcome memory matchOutcome_);

    function getTeamNames() external view returns(string[] memory teamNames_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RegistrationFeeInfo} from "src/interfaces/IPaidPredictableCompetition.sol";

enum CompetitionImpl {
    UNKNOWN,
    BASE,
    PREDICTABLE,
    PAID_PREDICTABLE
}

struct CompetitionInfo {
    address addr;
    CompetitionImpl impl;
}

/// @title Competition Factory Interface
/// @notice Manages Competition creation and retrieval
interface ICompetitionFactory {
    /**
     * @dev Assumes that the impl type requires only `_numTeams` as a constructor arg
     * @param _competitionId The unique id of the competition
     * @param _numTeams The total number of teams in the competition
     * @param _expirationEpoch The epoch at which the competition expires
     * @param _competitionImpl The implementation type of the competition
     */
    function createCompetition(bytes32 _competitionId, uint16 _numTeams, uint64 _expirationEpoch, CompetitionImpl _competitionImpl, string[] memory _teamNames) external returns(address addr_);
    /**
     * @notice Creates a new competition that allows users to submit bracket predictions for a fee
     * @dev Assumes that the impl type requires `_numTeams` and feeInfo as constructor args. Can set fee to 0 to have a free bracket,
     *  or use createCompetition with impl type PREDICTABLE to have free bracket prediction submissions
     * @param _competitionId The unique id of the competition
     * @param _numTeams The total number of teams in the competition
     * @param _expirationEpoch The epoch at which the competition expires
     * @param _feeInfo The registration fee information for the competition
     */
    function createPaidPredictableCompetition(bytes32 _competitionId, uint16 _numTeams, uint64 _expirationEpoch, RegistrationFeeInfo calldata _feeInfo, string[] memory _teamNames) external returns(address addr_);
    /**
     * @dev Sets the protocol fee that is charged for running a competition
     * @param _feeBps The protocol fee in bps
     */
    function setProtocolFee(uint256 _feeBps) external;
    /**
     * @dev Sets the bytecode for a competition implementation type to use when creating competitions.
     *  Only callable by the owner, and is stored via SSTORE2 in a contract
     * @param _impl The implementation type of the competition
     * @param _code The bytecode of the competition contract
     */
    function setContractCode(CompetitionImpl _impl, bytes memory _code) external;
    /**
     * @dev Returns the info of the competition contract or a default struct if it doesn't exist
     * @param _competitionId The unique id of the competition
     */
    function getCompetitionInfo(bytes32 _competitionId) external view returns(CompetitionInfo memory info_);
    /**
     * @dev Returns the address of the competition contract or address(0) if it doesn't exist
     * @param _competitionId The unique id of the competition
     */
    function getCompetitionAddress(bytes32 _competitionId) external view returns(address addr_);
    /**
     * @dev Returns the implementation type of the competition contract or UNKNOWN if it doesn't exist
     * @param _competitionId The unique id of the competition
     */
    function getCompetitionImplType(bytes32 _competitionId) external view returns(CompetitionImpl impl_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPredictableCompetition} from "src/interfaces/IPredictableCompetition.sol";

struct RegistrationFeeInfo {
    bool isNetworkToken;
    address paymentToken;
    uint256 fee;
}

/// @title Competition Interface
/// @notice Manages Competition buy-ins, payouts, round progression, etc
interface IPaidPredictableCompetition is IPredictableCompetition {
    /**
     * @dev Emitted when a user pays the registration fee. This will only happen the first time a user submits a bracket,
     *  since they can make changes until the competition starts
     * @param user The user submitting the bracket prediction
     * @param feeInfo The fee info for creating bracket predictions in this competition
     */
    event UserPaidForBracket(address indexed user, RegistrationFeeInfo feeInfo);

    /**
     * @dev Emitted when a user is refunded the registration fee. This will only happen if the competition has expired
     * @param user The user who was refunded
     * @param amount The amount of the fee that was refunded
     */
    event UserRefundedForBracket(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user claims their reward at the end of the competition
     * @param user The user who claimed the rewards
     * @param amount The amount of the reward that was claimed (in the payment token's decimal precision)
     */
    event UserClaimedRewards(address indexed user, uint256 amount);

    /**
     * @dev Overrides IPredictableCompetition.createBracketPrediction to require an ERC20 fee payment if ERC20 is the fee token
     * @inheritdoc IPredictableCompetition
     */
    function createBracketPrediction(address _user, uint8[] calldata _matchPredictions) external;

    /**
     * @dev Submits a bracket prediction for this competition using the network token (eth, matic, etc).
     *  Can only be called before the competition has started
     * @param _registrant The user who is submitting the bracket prediction
     * @param _matchPredictions The user's predictions for each match. Each uint8 is the team id for the match at array index
     */
    function createBracketPredictionGasToken(address _registrant, uint8[] calldata _matchPredictions) external payable;

    /**
     * @dev Refunds the registration fee to the sender if the competition has expired and the sender created a bracket prediction
     */
    function refundRegistrationFee() external;

    /**
     * @dev Collects the reward for the sending user. Can only be called when the competition is completed
     */
    function claimRewards() external;

    /**
     * @dev Calculates the reward for the given user. Will only calculate the reward 
     *  if the competition is completed and the user has not claimed it yet
     * @param _user The user to calculate the reward for
     * @return pendingRewards_ The pending reward for the user with the payment token's decimal precision
     */
    function calculatePendingRewards(address _user) external view returns(uint256 pendingRewards_);

    /**
     * @return feeInfo_ The fee info for creating bracket predictions in this competition
     */
    function getBracketPredictionFeeInfo() external view returns(RegistrationFeeInfo memory feeInfo_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICompetition} from "src/interfaces/ICompetition.sol";

/// @title Competition Interface
/// @notice Manages Competition round progression, registration, etc
interface IPredictableCompetition is ICompetition {
    /**
     * 
     * @param sender The address of the user who called the function
     * @param user The user submitting the bracket prediction
     */
    event PredictionSaved(address indexed sender, address indexed user);

    /**
     * @dev Submits a bracket prediction for this competition. Can only be called before the competition has started
     * @param _user The user submitting the bracket prediction
     * @param _matchPredictions The user's predictions for each match. Each uint8 is the team id for the match at array index
     */
    function createBracketPrediction(address _user, uint8[] calldata _matchPredictions) external;

    /**
     * @param _user The user to check
     * @return bracketPrediction_ The user's bracket predictions for this competition. Each uint8 is the team id for the match at array index
     */
    function getUserBracketPrediction(address _user) external view returns(uint8[] memory bracketPrediction_);

    /**
     * @param _user The user to check
     * @return isRegistered_ Whether or not the user has created a bracket prediction for this competition
     */
    function hasUserRegistered(address _user) external view returns(bool isRegistered_);

    /**
     * @dev The returned score is multiplied by 100 to allow for 2 decimal places of precision.
     * @param _user The user to get score for
     * @return score_ The user's current score for this competition
     */
    function getUserBracketScore(address _user) external view returns(uint256 score_);

    /**
     * @dev The returned score is multiplied by 100 to allow for 2 decimal places of precision.
     *  This score is used to determine a user's rank in the competition
     * @return totalScore_ The total score for this competition
     */
    function getTotalScore() external view returns(uint256 totalScore_);

    /**
     * 
     * @param _user The user to get score for
     * @return scorePercent_ The user's current score for this competition as a percentage of the total score with 4 decimal places of precision
     */
    function getUserScorePercent(address _user) external view returns(uint256 scorePercent_);

}