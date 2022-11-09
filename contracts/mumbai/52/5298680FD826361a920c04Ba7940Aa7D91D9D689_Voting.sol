// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Interfaces/ICampaign.sol";

error Voting__AmountExceedTotalSupply();
error Voting__NotTheManagerContract();
error Voting__InformationAlreadyInitialized();
error Voting__RequestNotVotable();
error Voting__CampaignNotInitialized();

contract Voting {
    /* ====== Structures ====== */
    struct RequestInformation {
        uint256 endDate;
        uint256 tokenAmount;
        address to;
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool executed;
    }

    struct VotingInformation {
        uint256 lastRequestId;
        uint256 totalRequestedAmount;
        uint256 totalRequests;
        uint256 quorumPercentage;
        bool initialized;
    }

    /* ====== Variables ====== */
    mapping(address => mapping(uint256 => RequestInformation))
        private requestsFromCampaigns;

    mapping(address => VotingInformation) private campaignVotingInformations;

    mapping(address => mapping(uint256 => bool))
        private contributorVotedOnRequest;

    address private managerAddress;

    /* ====== Events ====== */
    event RequestSubmitted(
        address campaign,
        uint256 requestId,
        address to,
        uint256 amount,
        uint256 requestEndDate
    );

    event RequestVotesUpdated(
        uint256 totalVotes,
        uint256 yesVotes,
        uint256 noVotes,
        address lastVoter
    );

    /* ====== Modifiers ====== */

    modifier onlyManager() {
        if (msg.sender != managerAddress) {
            revert Voting__NotTheManagerContract();
        }
        _;
    }

    modifier isInitializedCampaign() {
        VotingInformation memory _info = campaignVotingInformations[msg.sender];
        if (!_info.initialized) {
            revert Voting__CampaignNotInitialized();
        }
        _;
    }

    /* ====== Functions ====== */
    constructor(address _managerContractAddress) {
        managerAddress = _managerContractAddress;
    }

    function requestForTokenTransfer(
        address _to,
        uint256 _amount,
        uint256 _requestDuration
    ) external isInitializedCampaign {
        uint256 _totalSupply = ICampaign(msg.sender).getTotalSupply();

        VotingInformation memory _info = campaignVotingInformations[msg.sender];

        if (_amount > _totalSupply - _info.totalRequestedAmount) {
            revert Voting__AmountExceedTotalSupply();
        }

        uint256 _endDate = block.timestamp + _requestDuration;

        campaignVotingInformations[msg.sender].lastRequestId++;
        campaignVotingInformations[msg.sender].totalRequests++;
        campaignVotingInformations[msg.sender].totalRequestedAmount += _amount;

        requestsFromCampaigns[msg.sender][
            campaignVotingInformations[msg.sender].lastRequestId
        ] = RequestInformation(_endDate, _amount, _to, 0, 0, 0, false, false);

        emit RequestSubmitted(
            msg.sender,
            campaignVotingInformations[msg.sender].lastRequestId,
            _to,
            _amount,
            _endDate
        );
    }

    function intializeCampaignVotingInformation(
        uint256 _quorumPercentage,
        address _campaignAddress
    ) external onlyManager {
        if (campaignVotingInformations[_campaignAddress].initialized) {
            revert Voting__InformationAlreadyInitialized();
        }

        campaignVotingInformations[_campaignAddress] = VotingInformation(
            0,
            0,
            0,
            _quorumPercentage,
            true
        );
    }

    function executeRequest(uint256 _requestId, address _campaignAddress)
        external
        onlyManager
        returns (bool approved)
    {
        uint256 _numContributor = ICampaign(_campaignAddress)
            .getNumberOfContributor();

        RequestInformation memory _info = requestsFromCampaigns[
            _campaignAddress
        ][_requestId];

        uint256 _votePercentage = (_info.totalVotes * 100) / _numContributor;

        approved = false;

        if (
            _votePercentage >=
            campaignVotingInformations[_campaignAddress].quorumPercentage
        ) {
            if (_info.yesVotes > _info.noVotes) {
                approved = true;
                requestsFromCampaigns[_campaignAddress][_requestId]
                    .approved = true;

                //Send the tokens to the receiver address

                address _receiver = requestsFromCampaigns[_campaignAddress][
                    _requestId
                ].to;
                uint256 _amount = requestsFromCampaigns[_campaignAddress][
                    _requestId
                ].tokenAmount;

                ICampaign(_campaignAddress).transferStableTokensAfterRequest(
                    _receiver,
                    _amount
                );
            }
        }
        requestsFromCampaigns[_campaignAddress][_requestId].executed = true;
    }

    function voteOnRequest(
        address _contributor,
        uint256 _requestId,
        bool _approve
    ) external isInitializedCampaign {
        address _campaign = msg.sender;

        RequestInformation memory _requestInfo = requestsFromCampaigns[
            _campaign
        ][_requestId];

        bool _votable = _isRequestVotable(
            _requestInfo,
            _contributor,
            _requestId
        );
        if (!_votable) {
            revert Voting__RequestNotVotable();
        }

        requestsFromCampaigns[_campaign][_requestId].totalVotes++;

        if (_approve) {
            requestsFromCampaigns[_campaign][_requestId].yesVotes++;
        } else {
            requestsFromCampaigns[_campaign][_requestId].noVotes++;
        }

        contributorVotedOnRequest[_contributor][_requestId] = true;

        emit RequestVotesUpdated(
            requestsFromCampaigns[_campaign][_requestId].totalVotes,
            requestsFromCampaigns[_campaign][_requestId].yesVotes,
            requestsFromCampaigns[_campaign][_requestId].noVotes,
            _contributor
        );
    }

    function _isRequestVotable(
        RequestInformation memory _info,
        address _contributor,
        uint256 _requestId
    ) internal view returns (bool) {
        if (
            !_info.approved &&
            !_info.executed &&
            !(block.timestamp >= _info.endDate) &&
            !contributorVotedOnRequest[_contributor][_requestId]
        ) {
            return true;
        }

        return false;
    }

    /* ====== View / Pure Functions ====== */

    function getVotingInformation(address _campaignAddress)
        external
        view
        returns (VotingInformation memory)
    {
        return campaignVotingInformations[_campaignAddress];
    }

    function getRequestInformation(address _campaignAddress, uint256 _requestId)
        external
        view
        returns (RequestInformation memory)
    {
        return requestsFromCampaigns[_campaignAddress][_requestId];
    }

    function getFinishedRequestsFromCampaign(address _campaignAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _counter;

        for (
            uint256 index;
            index < campaignVotingInformations[_campaignAddress].totalRequests;
            index++
        ) {
            RequestInformation memory _info = requestsFromCampaigns[
                _campaignAddress
            ][index];
            if ((block.timestamp >= _info.endDate) && !_info.executed) {
                _counter++;
            }
        }

        uint256[] memory _finishedRequests = new uint256[](_counter);
        uint256 _arrayIndex = 0;

        for (
            uint256 index = 1;
            index <= campaignVotingInformations[_campaignAddress].totalRequests;
            index++
        ) {
            RequestInformation memory _info = requestsFromCampaigns[
                _campaignAddress
            ][index];
            if ((block.timestamp >= _info.endDate) && !_info.executed) {
                _finishedRequests[_arrayIndex] = index;
                _arrayIndex++;
            }
        }

        return _finishedRequests;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVoting.sol";

interface ICampaign {
    enum TokenTier {
        bronze,
        silver,
        gold
    }

    struct ContributorInfo {
        TokenTier tier;
        uint256 contributionAmount;
        bool tokenMinted;
        bool allowableToMint;
    }

    event TokensTransfered(address to, uint256 amount);
    event SubmitterAddressChanged(address newAddress);
    event UpdateContributor(address contributor, uint256 amount);

    function initialize(
        uint256 _duration,
        address _submitter,
        address _token,
        uint256 _minAmount,
        string memory _campaignURI
    ) external;

    function addContributor(address _contributor, uint256 _amount) external;

    function updateSubmitterAddress(address _submitter) external;

    /**
     * @dev - the submitter can transfer after the campaign is finished the tokens to an address
     * @param _to - the address to receive the tokens
     * @param _amount - the number of tokens to be transferred
     */
    function transferStableTokens(address _to, uint256 _amount) external;

    function transferStableTokensAfterRequest(address _to, uint256 _amount)
        external;

    function transferStableTokensWithRequest(
        address _to,
        uint256 _amount,
        uint256 _requestDuration
    ) external;

    function voteOnTransferRequest(uint256 _requestId, bool _approve) external;

    /**
     * @dev - set the status of the campaign to finished
     */
    function finishFunding() external returns (bool successful);

    function updateCampaignURI(string memory _newURI) external;

    function setContributionToZero(address _contributor)
        external
        returns (uint256);

    function updateVotingContractAddress(address _newAddress) external;

    /* ========== View Functions ========== */
    function getEndDate() external view returns (uint256);

    function getStartDate() external view returns (uint256);

    function getDuration() external view returns (uint256);

    function getSubmitter() external view returns (address);

    function isFundingActive() external view returns (bool);

    function getRemainingFundingTime() external view returns (uint256);

    function getContributor(address _contributor)
        external
        view
        returns (uint256);

    function getNumberOfContributor() external view returns (uint256);

    function getTotalSupply() external view returns (uint256);

    function getMinAmount() external view returns (uint256);

    function getCampaignURI() external view returns (string memory);

    function getTokenTiers() external view returns (uint256[] memory);

    function isCampaignVotable() external view returns (bool);

    function getVotingContractAddress() external view returns (address);

    function getContributorInfo(address _contributor)
        external
        view
        returns (ContributorInfo memory);

    function getAllRequests()
        external
        view
        returns (IVoting.RequestInformation[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVoting {
    struct RequestInformation {
        uint256 endDate;
        uint256 tokenAmount;
        address to;
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool executed;
    }

    struct VotingInformation {
        uint256 lastRequestId;
        uint256 totalRequestedAmount;
        uint256 totalRequests;
        uint256 quorumPercentage;
        bool initialized;
    }

    event RequestSubmitted(
        address campaign,
        uint256 requestId,
        address to,
        uint256 amount,
        uint256 requestEndDate
    );

    event RequestVotesUpdated(
        uint256 totalVotes,
        uint256 yesVotes,
        uint256 noVotes,
        address lastVoter
    );

    function requestForTokenTransfer(
        address _to,
        uint256 _amount,
        uint256 _requestDuration
    ) external;

    function intializeCampaignVotingInformation(
        uint256 _quorumPercentage,
        address _campaignAddress
    ) external;

    function voteOnRequest(
        address _contributor,
        uint256 _requestId,
        bool _approve
    ) external;

    function executeRequest(uint256 _requestId, address _campaignAddress)
        external
        returns (bool approved);

    function getVotingInformation(address _campaignAddress)
        external
        view
        returns (VotingInformation memory);

    function getRequestInformation(address _campaignAddress, uint256 _requestId)
        external
        view
        returns (RequestInformation memory);

    function getFinishedRequestsFromCampaign(address _campaignAddress)
        external
        view
        returns (uint256[] memory);
}