// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizationUtilsV0.sol";
import "./ITemplateUtilsV0.sol";
import "./IWithdrawalUtilsV0.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirnodeRrpV0.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

contract MagnetProgramsBsc is RrpRequesterV0 {
    event Registration(address _address, address _referrerAddress);

    struct RegistractionData {
        bool registered;
        address payable referrerAddress;
        uint value;
    }

    address private airnode;
    address private sponsor;
    address payable private sponsorWallet;
    bytes32 private getLbPercentEndpointId;
    uint public oracleFee = 460000000000000;

    mapping(bytes32 => uint256) public fulfilledData;
    mapping(uint8 => uint) private levelPrices;
    mapping(bytes32 => address) public registrationRequests;
    mapping(address => RegistractionData) public registrationData;

    constructor(
        address _rrpAddress,
        address _airnode,
        bytes32 _getLbPercentEndpointId,
        uint _initialPrice
    ) RrpRequesterV0(_rrpAddress) {
        for (uint8 i = 1; i < 16; i++) {
            levelPrices[i] = _initialPrice;
            _initialPrice *= 2;
        }
        airnode = _airnode;
        getLbPercentEndpointId = _getLbPercentEndpointId;
    }

    function setSponsors(
        address _sponsor,
        address payable _sponsorWallet
    ) external {
        sponsor = _sponsor;
        sponsorWallet = _sponsorWallet;
    }

    function getLevelPrice(uint8 _program) public view returns (uint) {
        require(_program > 0 && _program < 16, "Invalid program");
        return levelPrices[_program];
    }

    function register(address payable _referrerAddress) external payable {
        require(
            msg.value >= (levelPrices[1] * 3) + oracleFee,
            "Insufficient funds"
        );
        bytes memory parameters = abi.encode(
            bytes32("1u"),
            bytes32("program"),
            uint256(0)
        );
        bytes32 requestId = makeRequest(getLbPercentEndpointId, parameters);
        registrationRequests[requestId] = msg.sender;
        registrationData[msg.sender] = RegistractionData(
            true,
            _referrerAddress,
            msg.value - oracleFee
        );
        sponsorWallet.transfer(oracleFee);
    }

    function makeRequest(
        bytes32 _endpointId,
        bytes memory _parameters
    ) private returns (bytes32) {
        return
            airnodeRrp.makeFullRequest(
                airnode,
                _endpointId,
                sponsor,
                sponsorWallet,
                address(this),
                this.fulfill.selector,
                _parameters
            );
    }

    function fulfill(
        bytes32 requestId,
        bytes calldata data
    ) external onlyAirnodeRrp {
        address userAddress = registrationRequests[requestId];
        require(userAddress != address(0), "No such request made");
        RegistractionData memory _registrationData = registrationData[
            userAddress
        ];
        require(!_registrationData.registered, "User already registered");
        uint256 lbPercent = abi.decode(data, (uint256));
        fulfilledData[requestId] = lbPercent;
        emit Registration(userAddress, _registrationData.referrerAddress);
        _registrationData.referrerAddress.transfer(
            (_registrationData.value * lbPercent) / 1000
        );
    }
}