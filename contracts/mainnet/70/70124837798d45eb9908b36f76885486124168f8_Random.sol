/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
// File: @api3/airnode-protocol/contracts/rrp/interfaces/IWithdrawalUtilsV0.sol


pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/ITemplateUtilsV0.sol


pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAuthorizationUtilsV0.sol


pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol


pragma solidity ^0.8.0;




interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File: @api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol


pragma solidity ^0.8.0;


/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// File: contracts/Random.sol


pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

interface AddressAgent{
    function getGroupBuyAddress() external  returns(address);
    function getMoneyToken() external  returns(address _moneyTokenAddress);
    function getAccountBookAddress() external returns(address _accountBookn);
    function getAgentInfoAddress() external returns(address _agentInfoAddress);
    function getMessageAddress() external returns(address _messageAddress);
    function getDecimals() external view returns(uint _decimals);
    function getTopAgentAddress() external view returns(address _topAgentAddress);
    function getRateFee() external view returns(uint _rateFee);
    function getApproveAddress(address approveAddress) external returns(address _approveAddress);
    function getDiceGameAddress() external returns(address _diceGameAddress);
    function getTicketGameAddress() external returns(address _randomAddress); 
}

interface DiceGameAddress{
    function setDiceResult(bytes32 requestId, uint256[] memory qrngUint256Array) external;
}

interface TicketGame{
  function ticketResult(bytes32 _requestId, uint256[] memory _random) external;
}

interface GroupBuyAddress{
  function setGroupBuyResult(bytes32 _requestId, uint256[] memory _random) external;
}

/// @title 代理
contract Random is Ownable, RrpRequesterV0 {
    AddressAgent public addressAgent;
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;
    bytes32 public endpointIdUint256Array;

    mapping(bytes32 => bool) public expectingTicketBeFulfilled;
    mapping(bytes32 => bool) public expectingDiceBeFulfilled;
    mapping(bytes32 => bool) public expectingGroupBuyBeFulfilled;

    modifier onlyGroupBuyAddress() {
        require(addressAgent.getApproveAddress(msg.sender) != address(0), "Invalid call");
        _;
    }

    constructor(address _AddressAgent,address _airnodeRrp) RrpRequesterV0(_airnodeRrp)  {
        addressAgent = AddressAgent(_AddressAgent);
     }

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256Array,
        address _sponsorWallet
    ) external onlyOwner{
        airnode = _airnode;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
    }

     /// @notice Requests a `uint256[]`
    /// @param size Size of the requested array
    function makeRequestUint256Array(uint256 size) public onlyGroupBuyAddress returns(bytes32 ){
        
         bytes32 _requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256Array.selector,
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        ); 

        expectingDiceBeFulfilled[_requestId] = true;
        return _requestId;
    }

    function makeTicketRequestUint256Array(uint256 size) public onlyGroupBuyAddress returns(bytes32 ){

        bytes32 _requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256Array.selector,
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        );

        expectingTicketBeFulfilled[_requestId] = true;
        return _requestId; 
    }

    function makeGroupBuyRequestUint256Array(uint256 size) public onlyGroupBuyAddress returns(bytes32 ){

        bytes32 _requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256Array.selector,
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        );

        expectingGroupBuyBeFulfilled[_requestId] = true;
        return _requestId; 
    }

        /// @notice Called by the Airnode through the AirnodeRrp contract to
    /// fulfill the request
    /// @param requestId Request ID
    /// @param data ABI-encoded response
    function fulfillUint256Array(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        uint256[] memory qrngUint256Array = abi.decode(data, (uint256[]));
        if(expectingTicketBeFulfilled[requestId]){
            TicketGame ticketGame =  TicketGame(addressAgent.getTicketGameAddress());  
            ticketGame.ticketResult(requestId, qrngUint256Array);
        }else if(expectingDiceBeFulfilled[requestId]){
            DiceGameAddress diceGameAddress = DiceGameAddress(addressAgent.getDiceGameAddress());
            diceGameAddress.setDiceResult(requestId, qrngUint256Array);
        }else if(expectingGroupBuyBeFulfilled[requestId]){
            GroupBuyAddress groupBuyAddress = GroupBuyAddress(addressAgent.getGroupBuyAddress());
            groupBuyAddress.setGroupBuyResult(requestId, qrngUint256Array);
        }
    }


}