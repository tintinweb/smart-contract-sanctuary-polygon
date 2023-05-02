/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: contracts/interfaces/ISxTResponseStorage.sol


pragma solidity ^0.8.7;


/**
 * @title The SxTRelayProxy contract interface
 * @notice Other contracts can use this interface to call SxTRelayProxy functions
 */
interface ISxTResponseStorage {
    
    function getUserResponses(bytes32 requestId) external view returns( string[][] memory response);

    function getUserErrors(bytes32 requestId) external view returns( string memory error);
    
    function saveResponse(bytes32 requestId, string[][] calldata data, string calldata errorMessage) external;
    
}
// File: contracts/SxTResponseStorage.sol


pragma solidity ^0.8.7;


/**
 * @title User Request String2D contract
 * @notice User Request contract for string[][] type of response using chainlink direct request
 * @notice The contract will be able to create the request and get response for that request
 */
contract SxTResponseStorage is ISxTResponseStorage, ConfirmedOwner {

    mapping( bytes32 => string[][]) public userResponses;
    mapping( bytes32 => string) public errorResponses;

    /** 
     * @dev The constructor
     */
    constructor () ConfirmedOwner(msg.sender)
    {}

    function getUserResponses(bytes32 requestId) external view override returns(string[][] memory response){
        return userResponses[requestId];
    }

    function getUserErrors(bytes32 requestId) external view override returns(string memory response){
        return errorResponses[requestId];
    }

    /**
     * @dev This function will be called by SxTRelay for providing response for a created request
     * @dev The SxTRelay contract will be looking for the function name saveQueryResponse for saving the response
     * @param requestId - id of request for which response is to be stored
     * @param data - response of the request sent by SxT
     * @param errorMessage - error message send by SxT if there was an error while fetching response for the request
     */
    function saveResponse(bytes32 requestId, string[][] calldata data, string calldata errorMessage) external override {
        string[][] memory response = userResponses[requestId]; 
        delete response;
        // Store response
        errorResponses[requestId] = errorMessage;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 inLength = data[i].length;
            string[] memory row = new string[](inLength);
            for (uint256 j = 0; j < inLength; j++) {
                row[j] = data[i][j];
            }
            response[i] = row;
        }
        userResponses[requestId] = response;
    }
}