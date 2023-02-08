// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/VotingAdapterLibrary.sol";
import "../libraries/DaoLibrary.sol";
import "../core/DaoRegistry.sol";
import "../extensions/CommunityEquityExtension.sol";
import "../extensions/BankExtension.sol";
import "../extensions/MemberExtension.sol";
import "../modifiers/AdapterGuard.sol";
import "./interfaces/ICommunityEquityAdapter.sol";


/// @title Community Equity Adapter Contract
/// @notice This contract is used to create a new Community Equity Adapter
contract CommunityEquityAdapter is 
    ICommunityEquityAdapter,
    MemberGuard
{
    /**
     * PUBLIC VARIABLES
     */

    /// @notice daoAddress => proposalId =>
    mapping(address => mapping(bytes32 => SetCommunityEquityProposal)) public setCommunityEquityProposal;
    
    /// @notice daoAddress => proposalId =>
    mapping(address => mapping(bytes32 => SetCommunityEquityMemberProposal)) public setCommunityEquityMemberProposal;
    
    /// @notice daoAddress => proposalId =>
    mapping(address => mapping(bytes32 => RemoveCommunityEquityProposal)) public removeCommunityEquityProposal;
    
    /// @notice daoAddress => proposalId =>
    mapping(address => mapping(bytes32 => RemoveCommunityEquityMemberProposal)) public removeCommunityEquityMemberProposal;


    /**
     * PRIVATE VARIABLES
     */

    /// @notice daoAddress => block.number
    mapping(address => uint256) private _lockedAt;


    /**
     * MODIFIER
     */

    /**
     * @dev This modifier is used to prevent reentrancy attacks on the contract
     * @param daoAddress the address of the DAO contract calling the function
     */
    modifier reentrancyGuard(
        address daoAddress
    ) 
    {
        if(_lockedAt[daoAddress] == block.number)
            revert AdapterGuard.AdapterGuard_ContractLocked(daoAddress);
        
        _lockedAt[daoAddress] = block.number;
        _;
        _lockedAt[daoAddress] = 0;
    }

    modifier proposalGuard(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
    {
        if(dao.getIsProposalUsed(proposalId))
            revert CommunityEquityAdapter_InvalidProposalId();
        _;
    }

    
    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc ICommunityEquityAdapter
    function submitSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        CommunityEquityExtension.CommunityEquityConfig calldata _communityEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external 
        override 
        onlyMember(dao)
        proposalGuard(dao, proposalId)
    {
        setCommunityEquityProposal[address(dao)][proposalId] = 
            SetCommunityEquityProposal(
                VotingAdapterLibrary.ProposalStatus.NOT_STARTED,
                communityEquityId,
                _communityEquityConfig,
                _epochConfig
            );

        emit SubmitSetCommunityEquityProposalEvent(
            address(dao), 
            msg.sender, 
            data, 
            proposalId, 
            communityEquityId, 
            _communityEquityConfig, 
            _epochConfig
        );

        VotingAdapterLibrary._submitProposal(
            dao, 
            proposalId, 
            data, 
            VotingAdapterLibrary.ProposalType.SetCommunityEquityProposal
        );
    }

    /// @inheritdoc ICommunityEquityAdapter
    function submitSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        CommunityEquityExtension.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external 
        override 
        onlyMember(dao)
        proposalGuard(dao, proposalId)
    {
        setCommunityEquityMemberProposal[address(dao)][proposalId] = 
            SetCommunityEquityMemberProposal(
                VotingAdapterLibrary.ProposalStatus.NOT_STARTED,
                communityEquityId,
                _communityEquityMemberConfig
            );

        emit SubmitSetCommunityEquityMemberProposalEvent(
            address(dao), 
            msg.sender, 
            data, 
            proposalId, 
            communityEquityId, 
            _communityEquityMemberConfig
        );

        VotingAdapterLibrary._submitProposal(
            dao, 
            proposalId, 
            data, 
            VotingAdapterLibrary.ProposalType.SetCommunityEquityMemberProposal
        );
    }

    /// @inheritdoc ICommunityEquityAdapter
    function submitRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId
    ) 
        external 
        override
        onlyMember(dao)
        proposalGuard(dao, proposalId)
    {
        removeCommunityEquityProposal[address(dao)][proposalId] = 
            RemoveCommunityEquityProposal(
                VotingAdapterLibrary.ProposalStatus.NOT_STARTED,
                communityEquityId
            );
        
        emit SubmitRemoveCommunityEquityProposalEvent(
            address(dao), 
            msg.sender, 
            data, 
            proposalId, 
            communityEquityId
        );

        VotingAdapterLibrary._submitProposal(
            dao, 
            proposalId, 
            data, 
            VotingAdapterLibrary.ProposalType.RemoveCommunityEquityProposal
        );
    }

    /// @inheritdoc ICommunityEquityAdapter
    function submitRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external 
        override 
        onlyMember(dao)
        proposalGuard(dao, proposalId)
    {        
        removeCommunityEquityMemberProposal[address(dao)][proposalId] = 
            RemoveCommunityEquityMemberProposal(
                VotingAdapterLibrary.ProposalStatus.NOT_STARTED,
                communityEquityId,
                _memberAddress
            );

        emit SubmitRemoveCommunityEquityMemberProposalEvent(
            address(dao), 
            msg.sender, 
            data, 
            proposalId, 
            communityEquityId, 
            _memberAddress
        );

        VotingAdapterLibrary._submitProposal(
            dao,
            proposalId, 
            data, 
            VotingAdapterLibrary.ProposalType.RemoveCommunityEquityMemberProposal
        );
    } 

    /// @inheritdoc ICommunityEquityAdapter
    //slither-disable-next-line reentrancy-events
    function processSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        external 
        override 
        reentrancyGuard(address(dao))
    {
        SetCommunityEquityProposal storage proposal = setCommunityEquityProposal[address(dao)][proposalId];

        if(proposal.status != VotingAdapterLibrary.ProposalStatus.NOT_STARTED)
            revert CommunityEquityAdapter_ProposalAlreadyProcessed();

        proposal.status = 
            VotingAdapterLibrary._processProposal(
                dao,
                proposalId
            );

        if (proposal.status == VotingAdapterLibrary.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = 
                CommunityEquityExtension(
                    dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
                );

            BankExtension bank = 
                BankExtension(
                    dao.getExtensionAddress(DaoLibrary.BANK_EXT)
                );

            if(communityEquity.getIsCommunityEquity(proposal.communityEquityId)){
                _processRemoveCommunityEquityTokens(
                    dao, 
                    proposal.communityEquityId, 
                    communityEquity, 
                    bank
                );
            }

            communityEquity.setCommunityEquity(
                dao,
                proposal.communityEquityId,
                proposal.communityEquityConfig,
                proposal.epochConfig
            );

            bank.addToBalance(
                dao,
                DaoLibrary.GUILD,
                DaoLibrary.UNITS,
                proposal.communityEquityConfig.tokenAmount
            );

            proposal.status == VotingAdapterLibrary.ProposalStatus.DONE;

            emit ProcessSetCommunityEquityProposalEvent(
                address(dao), 
                msg.sender, 
                proposalId, 
                proposal.communityEquityId, 
                proposal.communityEquityConfig, 
                proposal.epochConfig
            );
        }
    }

    /// @inheritdoc ICommunityEquityAdapter
    //slither-disable-next-line reentrancy-events
    function processSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        external 
        override
        reentrancyGuard(address(dao))
    {
        SetCommunityEquityMemberProposal storage proposal = setCommunityEquityMemberProposal[address(dao)][proposalId];
        
        if(proposal.status != VotingAdapterLibrary.ProposalStatus.NOT_STARTED)
            revert CommunityEquityAdapter_ProposalAlreadyProcessed();
        
        proposal.status = 
            VotingAdapterLibrary._processProposal(
                dao,
                proposalId
            );

        if (proposal.status == VotingAdapterLibrary.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = 
                CommunityEquityExtension(
                    dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
                );

            communityEquity.setCommunityEquityMember(
                dao,
                proposal.communityEquityId,
                proposal.communityEquityMemberConfig
            );

            proposal.status == VotingAdapterLibrary.ProposalStatus.DONE;
            
            emit ProcessSetCommunityEquityMemberProposalEvent(
                address(dao), 
                msg.sender, 
                proposalId, 
                proposal.communityEquityId, 
                proposal.communityEquityMemberConfig
            );
        }
    }
  
    /// @inheritdoc ICommunityEquityAdapter
    //slither-disable-next-line reentrancy-events
    function processRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        external 
        override 
        reentrancyGuard(address(dao))
    {
        RemoveCommunityEquityProposal storage proposal = removeCommunityEquityProposal[address(dao)][proposalId];
        
        if(proposal.status != VotingAdapterLibrary.ProposalStatus.NOT_STARTED)
            revert CommunityEquityAdapter_ProposalAlreadyProcessed();
        
        proposal.status = 
            VotingAdapterLibrary._processProposal(
                dao,
                proposalId
            );

        if (proposal.status == VotingAdapterLibrary.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = 
                CommunityEquityExtension(
                    dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
                );

            BankExtension bank = 
                BankExtension(
                    dao.getExtensionAddress(DaoLibrary.BANK_EXT)
                );

            _processRemoveCommunityEquityTokens(
                dao, 
                proposal.communityEquityId, 
                communityEquity, 
                bank
            );

            communityEquity.removeCommunityEquity(
                dao,
                proposal.communityEquityId
            );
            
            proposal.status == VotingAdapterLibrary.ProposalStatus.DONE;
            
            emit ProcessRemoveCommunityEquityProposalEvent(
                address(dao), 
                msg.sender, 
                proposalId, 
                proposal.communityEquityId
            );
        }
    }

    /// @inheritdoc ICommunityEquityAdapter
    //slither-disable-next-line reentrancy-events
    function processRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        external 
        override 
        reentrancyGuard(address(dao))
    {
        RemoveCommunityEquityMemberProposal storage proposal = removeCommunityEquityMemberProposal[address(dao)][proposalId];
        
        if(proposal.status != VotingAdapterLibrary.ProposalStatus.NOT_STARTED)
            revert CommunityEquityAdapter_ProposalAlreadyProcessed();

        proposal.status = 
            VotingAdapterLibrary._processProposal(
                dao,
                proposalId
            );

        if (proposal.status == VotingAdapterLibrary.ProposalStatus.IN_PROGRESS) {
            CommunityEquityExtension communityEquity = 
                CommunityEquityExtension(
                    dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
                );

            communityEquity.removeCommunityEquityMember(
                dao,
                proposal.communityEquityId,
                proposal.memberAddress
            );

            proposal.status == VotingAdapterLibrary.ProposalStatus.DONE;
            
            emit ProcessRemoveCommunityEquityMemberProposalEvent(
                address(dao), 
                msg.sender, 
                proposalId, 
                proposal.communityEquityId, 
                proposal.memberAddress
            );
        }
    }

    /// @inheritdoc ICommunityEquityAdapter
    function actCommunityEquityMemberDistribute(
        DaoRegistry dao, 
        bytes32 communityEquityId, 
        address recipient,
        uint256 amountToBeSent
    ) 
        external 
        override 
        reentrancyGuard(address(dao))
    {
        CommunityEquityExtension communityEquity = 
            CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );

        if(!communityEquity.getIsCommunityEquity(communityEquityId))
            revert CommunityEquityAdapter_InvalidCommunityEquityId();

        if(!communityEquity.getIsCommunityEquityMember(communityEquityId, msg.sender))
            revert CommunityEquityAdapter_NotCommunityEquityMember();
        
        CommunityEquityExtension.CommunityEquityMemberConfig memory communityEquityMemberConfig = 
            communityEquity.getCommunityEquityMemberConfig(
                communityEquityId, 
                msg.sender
            );

        if(amountToBeSent >= communityEquityMemberConfig.singlePaymentAmountThreshold)
            revert CommunityEquityAdapter_AmountExceedsSinglePaymentAmountThreshold();

        if(communityEquityMemberConfig.totalPaymentAmount+amountToBeSent >= communityEquityMemberConfig.totalPaymentAmountThreshold)
            revert CommunityEquityAdapter_AmountExceedsTotalPaymentAmountThreshold();

        BankExtension bank = BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );

        if(bank.balanceOf(DaoLibrary.GUILD, DaoLibrary.UNITS) < amountToBeSent)
            revert CommunityEquityAdapter_InsufficientGuildBalance();

        CommunityEquityExtension.CommunityEquityConfig memory communityEquityConfig = communityEquity.getCommunityEquityConfig(communityEquityId);

        if(communityEquityConfig.tokenAmount < amountToBeSent)
            revert CommunityEquityAdapter_InsufficientCommunityEquityBalance();

        emit ActCommunityEquityMemberDistributeEvent(
            address(dao), 
            msg.sender, 
            communityEquityId, 
            recipient, 
            amountToBeSent
        );

        communityEquityConfig.tokenAmount -= amountToBeSent;

        communityEquity.setCommunityEquity(dao, communityEquityId, communityEquityConfig);

        MemberExtension member = 
            MemberExtension(
                dao.getExtensionAddress(DaoLibrary.MEMBER_EXT)
            );

        if(member.getIsMember(recipient)){            
            bank.addToBalance(
                dao,
                recipient,
                DaoLibrary.UNITS,
                amountToBeSent
            );
        }
        else{
            member.setMember(
                dao,
                IMemberExtension.MemberConfig(
                    recipient,
                    amountToBeSent,
                    block.timestamp,
                    false
                )
            );
        }
        bank.subtractFromBalance(
            dao,
            DaoLibrary.GUILD,
            DaoLibrary.UNITS,
            amountToBeSent
        );

        communityEquityMemberConfig.totalPaymentAmount += amountToBeSent;

        communityEquity.setCommunityEquityMember(
            dao, 
            communityEquityId, 
            communityEquityMemberConfig
        );
    }
    
    /// @inheritdoc ICommunityEquityAdapter
    function actCommunityEquityEpochUpdate(
        DaoRegistry dao,
        bytes32 communityEquityId
    )
        external 
        override 
        reentrancyGuard(address(dao))
    { 
        CommunityEquityExtension communityEquity = 
            CommunityEquityExtension(
                dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT)
            );

        if(!communityEquity.getIsCommunityEquity(communityEquityId))
            revert CommunityEquityAdapter_InvalidCommunityEquityId();

        CommunityEquityExtension.CommunityEquityConfig memory communityEquityConfig = communityEquity.getCommunityEquityConfig(communityEquityId);

        if(communityEquityConfig.allocationType != ICommunityEquityExtension.AllocationType.EPOCH)
            revert CommunityEquityAdapter_InvalidCommunityEquityAllocationType();

        DaoLibrary.EpochConfig memory epochConfig = communityEquity.getCommunityEquityEpochConfig(communityEquityId);

        uint256 blockTimestamp = block.timestamp;
        uint256 epochLastUpdated = epochConfig.epochLast + epochConfig.epochDuration;

        emit ActCommunityEquityEpochUpdateEvent(
            address(dao), 
            msg.sender, 
            communityEquityId
        );

        //slither-disable-next-line timestamp
        if(blockTimestamp > epochLastUpdated){
            BankExtension bank = 
                BankExtension(
                    dao.getExtensionAddress(DaoLibrary.BANK_EXT)
                );

            _processRemoveCommunityEquityTokens(
                dao, 
                communityEquityId, 
                communityEquity, 
                bank
            );

            communityEquityConfig.tokenAmount = communityEquityConfig.allocationTokenAmount;

            while(epochLastUpdated < blockTimestamp){
                epochLastUpdated += epochConfig.epochDuration;
            }

            epochConfig.epochLast = epochLastUpdated;

            communityEquity.setCommunityEquity(
                dao,
                communityEquityId,
                communityEquityConfig,
                epochConfig
            );

            bank.addToBalance(
                dao,
                DaoLibrary.GUILD,
                DaoLibrary.UNITS,
                communityEquityConfig.tokenAmount
            );
        }
    }
    
    
    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev internal function to process the removal of community equity tokens
     * @param dao DaoRegistry contract instance
     * @param communityEquityId unique identifier of the community equity
     * @param communityEquity CommunityEquityExtension contract instance
     * @param bank BankExtension contract instance
     */
    function _processRemoveCommunityEquityTokens(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityExtension communityEquity,
        BankExtension bank
    ) 
        internal 
    {
        CommunityEquityExtension.CommunityEquityConfig memory communityEquityConfig = communityEquity.getCommunityEquityConfig(communityEquityId);

        uint256 tokenAmountToBeRemoved = communityEquityConfig.tokenAmount;
        // Check the balance of the guild token in the bank
        uint guildTokenAmount = 
            bank.balanceOf(
                DaoLibrary.GUILD,
                DaoLibrary.UNITS
            );
        
        // If there are tokens to be removed and the guild has enough tokens
        if(
            tokenAmountToBeRemoved > 0 &&
            guildTokenAmount >= tokenAmountToBeRemoved
        ){
            // Remove the tokens from the guild's balance in the bank
            bank.subtractFromBalance(
                dao,
                DaoLibrary.GUILD,
                DaoLibrary.UNITS,
                tokenAmountToBeRemoved
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../core/DaoRegistry.sol";
import "../adapters/interfaces/IVotingAdapter.sol";
import "./DaoLibrary.sol";
import "../extensions/ERC20Extension.sol";

/// @title Voting Adapter Library
/// @notice This library is used to handle voting logic
library VotingAdapterLibrary {
    /**
     * PUBLIC VARIABLES
     */

    string public constant ROLE_PREFIX = "governance.role.";

    bytes32 public constant DEFAULT_GOV_TOKEN_CFG = 
        keccak256(abi.encodePacked(ROLE_PREFIX, "default"));

    /**
     * STRUCTS
     */

    struct VotingConfig {
        VotingType votingType;
        uint256 votingPeriod;
        uint256 gracePeriod;
        uint256 disputePeriod;
        uint256 passRateMember;
        uint256 passRateToken;
        uint256 supportRequired;
    }

    struct Voting {
        uint256 nbYes;
        uint256 nbNo;
        uint256 nbMembers;
        uint256 nbTokens;
        uint256 startingTime;
        uint256 graceStartingTime;
        uint256 disputeStartingTime;
        uint256 blockNumber;
        bytes32 proposalId;
        bytes data;
        address submittedBy;
        VotingConfig votingConfig;
        ProposalType proposalType;
        VotingState votingState;
    }

    /**
     * ENUMS
     */

    enum ProposalType {
        GenericProposal,
        SetCommunityEquityProposal,
        SetCommunityEquityMemberProposal,
        RemoveCommunityEquityProposal,
        RemoveCommunityEquityMemberProposal,
        SetDynamicEquityProposal,
        SetDynamicEquityEpochProposal,
        SetDynamicEquityMemberProposal,
        SetDynamicEquityMemberSuspendProposal,
        SetDynamicEquityMemberExpenseProposal,
        SetDynamicEquityMemberEpochProposal,
        SetDynamicEquityMemberEpochDefaultProposal,
        RemoveDynamicEquityMemberProposal,
        RemoveDynamicEquityMemberEpochProposal,
        ManagerProposal,
        ManagerConfigurationProposal,
        SetMemberProposal,
        SetMemberSetupProposal,
        SetMemberAgreementProposal,
        RemoveMemberProposal,
        RemoveMemberBadLeaverProposal,
        RemoveMemberResigneeProposal,
        SetVestedEquityProposal,
        SetVestedEquityMemberProposal,
        RemoveVestedEquityMemberProposal
    }

    enum ProposalStatus {
        NOT_STARTED,
        IN_PROGRESS,
        DONE,
        FAILED
    }

    enum VotingType {
        PROPORTIONAL,
        WEIGHTED,
        QUADRATIC,
        OPTIMISTIC,
        COOPERATIVE
    }

    enum VotingState {
        NOT_STARTED,
        TIE,
        PASS,
        NOT_PASS,
        IN_PROGRESS,
        GRACE_PERIOD,
        DISPUTE_PERIOD
    }


    /**
     * INTERNAL FUNCTIONS
     */

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        ProposalType proposalType
    ) 
        internal 
    {
        dao.submitProposal(proposalId);

        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
        );

        address submittedBy = msg.sender;

        dao.sponsorProposal(
            proposalId, 
            submittedBy, 
            address(votingAdapter)
        );
        
        votingAdapter.startNewVotingForProposal(
            dao, 
            proposalId, 
            data, 
            proposalType
        );
    }

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        ProposalType proposalType,
        VotingConfig memory votingConfig
    ) 
        internal 
    {
        dao.submitProposal(proposalId);
        
        IVotingAdapter votingAdapter = 
            IVotingAdapter(
                dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
            );

        address submittedBy = msg.sender;

        dao.sponsorProposal(
            proposalId, 
            submittedBy, 
            address(votingAdapter)
        );
        
        votingAdapter.startNewVotingForProposal(
            dao, 
            proposalId, 
            data, 
            proposalType, 
            votingConfig
        );
    }

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        ProposalType proposalType,
        VotingType votingType
    ) 
        internal 
    {
        dao.submitProposal(proposalId);

        IVotingAdapter votingAdapter = 
            IVotingAdapter(
                dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
            );

        address submittedBy = msg.sender;

        dao.sponsorProposal(
            proposalId, 
            submittedBy, 
            address(votingAdapter)
        );

        VotingConfig memory votingConfig = votingAdapter.getVotingConfig(address(dao));

        votingConfig.votingType = votingType;
        
        votingAdapter.startNewVotingForProposal(
            dao, 
            proposalId, 
            data, 
            proposalType, 
            votingConfig
        );
    }

    function _submitProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes memory data,
        ProposalType proposalType,
        VotingType _votingType,
        uint256 _votingPeriod
    ) 
        internal 
    {
        dao.submitProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(
            dao.getAdapterAddress(DaoLibrary.VOTING_ADPT)
        );

        address submittedBy = msg.sender;
        
        dao.sponsorProposal(proposalId, submittedBy, address(votingAdapter));
        VotingConfig memory votingConfig = votingAdapter.getVotingConfig(address(dao));
        votingConfig.votingType = _votingType;
        votingConfig.votingPeriod = _votingPeriod;
        votingAdapter.startNewVotingForProposal(dao, proposalId, data, proposalType, votingConfig);
    }

    //slither-disable-next-line calls-loop
    function _processProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        internal 
        returns (ProposalStatus)
    {
        dao.processProposal(proposalId);
        IVotingAdapter votingAdapter = IVotingAdapter(dao.votingAdapter(proposalId));
        
        require(
            address(votingAdapter) != address(0), 
            "votingAdpt::adapter not found"
        );

        VotingState voteResult = votingAdapter.voteResult(
            dao,
            proposalId
        );

        if (voteResult == VotingState.PASS) {
            return ProposalStatus.IN_PROGRESS;
        } 
        else if (voteResult == VotingState.NOT_PASS || voteResult == VotingState.TIE) {
            return ProposalStatus.FAILED;
        }
        else{
            return ProposalStatus.NOT_STARTED;
        }
    }

    function _cancelProposal(
        DaoRegistry dao,
        bytes32 proposalId
    ) 
        internal 
        returns (ProposalStatus)
    {
        dao.processProposal(proposalId);

        IVotingAdapter votingAdapter = IVotingAdapter(dao.votingAdapter(proposalId));
        
        require(
            address(votingAdapter) != address(0),
            "votingAdpt::adapter not found"
        );
        
        votingAdapter.cancelVote(
            dao, 
            proposalId
        );
        
        return ProposalStatus.FAILED;
    }

    function calc(
        uint256 balance,
        uint256 units,
        uint256 totalUnits
    ) 
        internal 
        pure 
        returns (uint256) 
    {
        require(
            totalUnits > 0,
            "totalUnits must be greater than 0"
        );

        require(
            units <= totalUnits,
            "units must be less than or equal to totalUnits"
        );
        
        if (balance == 0) {
            return 0;
        }
        // The balance for Internal and External tokens are limited to 2^64-1 (see Bank.sol:L411-L421)
        // The maximum number of units is limited to 2^64-1 (see ...)
        // Worst case cenario is: balance=2^64-1 * units=2^64-1, no overflows.
        uint256 prod = balance * units;
        return prod / totalUnits;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    /**
      * @dev Checks if the member address holds enough funds to be considered a governor.
      * @param dao The DAO Address.
      * @param voterAddr The message sender to be verified as governor.
      * @param proposalId The proposal id to retrieve the governance token address if configured.
      * @param snapshot The snapshot id to check the balance of the governance token for that member configured.
      */
    function getVotingWeight(
        DaoRegistry dao,
        address voterAddr,
        bytes32 proposalId,
        uint256 snapshot
    ) 
        internal 
        view 
        returns (uint256) 
    {
        (address adapterAddress, ) = dao.proposals(proposalId);

        // 1st - if there is any governance token configuration
        // for the adapter address, then read the voting weight based on that token.
        address governanceToken = dao.getAddressConfiguration(
            keccak256(abi.encodePacked(ROLE_PREFIX, adapterAddress))
        );
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 2nd - if there is no governance token configured for the adapter,
        // then check if exists a default governance token.
        // If so, then read the voting weight based on that token.
        governanceToken = dao.getAddressConfiguration(DEFAULT_GOV_TOKEN_CFG);
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 3rd - if none of the previous options are available, assume the
        // governance token is UNITS, then read the voting weight based on that token.
        return
            BankExtension(dao.getExtensionAddress(DaoLibrary.BANK_EXT))
                .getPriorAmount(voterAddr, DaoLibrary.UNITS, snapshot);
    }

    function getVotingWeight(
        DaoRegistry dao,
        address governanceToken,
        address voterAddr,
        uint256 snapshot
    ) 
        internal 
        view 
        returns (uint256) 
    {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        if (bank.isInternalToken(governanceToken)) {
            return bank.getPriorAmount(voterAddr, governanceToken, snapshot);
        }

        // The external token must implement the getPriorAmount function,
        // otherwise this call will fail and revert the voting process.
        // The actual revert does not show a clear reason, so we catch the error
        // and revert with a better error message.
        // slither-disable-next-line unused-return
        try
            ERC20Extension(governanceToken).getPriorAmount(voterAddr, snapshot)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            uint256 votingWeight
        ) {
            return votingWeight;
        } catch {
            revert("getPriorAmount not implemented");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../core/interfaces/IDaoRegistry.sol";

library DaoLibrary {
    /**
     * PRIVATE VARIABLES
     */

    ///@notice Foundance
    bytes32 internal constant FOUNDANCE = keccak256("foundance");

    ///@notice Bank Extension
    bytes32 internal constant BANK_EXT = keccak256("bank-ext");

    ///@notice ERC20 Extension
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");

    ///@notice Member Extension
    bytes32 internal constant MEMBER_EXT = keccak256("member-ext"); 

    ///@notice Dynamic Equity Extension
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");

    ///@notice Vested Equity Extension
    bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext");

    ///@notice Community Equity Extension
    bytes32 internal constant COMMUNITY_EQUITY_EXT = keccak256("community-equity-ext"); 
    
    ///@notice ERC20 Adapter
    bytes32 internal constant ERC20_ADPT = keccak256("erc20-adpt");

    ///@notice Member Adapter
    bytes32 internal constant MANAGER_ADPT = keccak256("manager-adpt");

    ///@notice Voting Adapter
    bytes32 internal constant VOTING_ADPT = keccak256("voting-adpt");

    ///@notice Member Adapter
    bytes32 internal constant MEMBER_ADPT = keccak256("member-adpt"); 

    ///@notice Dynamic Equity Adapter
    bytes32 internal constant DYNAMIC_EQUITY_ADPT = keccak256("dynamic-equity-adpt");

    ///@notice Vested Equity Adapter
    bytes32 internal constant VESTED_EQUITY_ADPT = keccak256("vested-equity-adpt");

    ///@notice Community Equity Adapter
    bytes32 internal constant COMMUNITY_EQUITY_ADPT = keccak256("community-equity-adpt");

    ///@notice GUILD Address
    address internal constant GUILD = address(0xdead);

    ///@notice ESCROW Address
    address internal constant ESCROW = address(0x4bec);

    ///@notice TOTAL Address
    address internal constant TOTAL = address(0xbabe);

    ///@notice UNITS Address
    address internal constant UNITS = address(0xFF1CE);

    ///@notice LOOT Address
    address internal constant LOOT = address(0xB105F00D);

    ///@notice ETH_TOKEN Address
    address internal constant ETH_TOKEN = address(0x0);

    ///@notice MEMBER_COUNT Address
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    ///@notice config COMMUNITY_EQUITY Id
    bytes32 internal constant COMMUNITY_EQUITY = keccak256("community-equity");

    ///@notice config floating point precision
    uint256 internal constant FOUNDANCE_PRECISION = 5;

    ///@notice config MAX_TOKENS_GUILD_BANK for the Bank Extension
    uint8   internal constant MAX_TOKENS_GUILD_BANK = 200;


    /**
     * STRUCTS
     */

    struct EpochConfig {
        uint256 epochDuration;
        uint256 epochReview;
        uint256 epochStart;
        uint256 epochLast;
    }

    
    /**
     * INTERNAL FUNCTIONS
     */

    function sqrt(
        uint256 y
    ) 
        internal 
        pure 
        returns (uint256 z) 
    {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
        function getFlag(
        uint256 flags, 
        uint256 flag
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) 
        internal 
        pure 
        returns (uint256) 
    {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(
        address addr
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(
        address addr
    ) 
        internal 
        pure 
        returns (bool) 
    {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        DaoRegistry dao,
        BankExtension bank
    ) 
        internal 
    {
        dao.potentialNewMember(memberAddress);
        require(
            memberAddress != address(0x0), 
            "invalid member address"
        );
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function totalTokens(
        BankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        //GUILD is accounted for twice otherwise
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); 
    }

    function totalUnitTokens(
        BankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        //GUILD is accounted for twice otherwise
        return  bank.balanceOf(TOTAL, UNITS) - bank.balanceOf(GUILD, UNITS); 
    }

    function totalQuadraticTokens(
        DaoRegistry dao,
        BankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 nbMembers = dao.getNbMembers();
        uint256 memberToken = 0;
        for (uint256 i = 0; i < nbMembers; i++) {
            address memberAddress = dao.getMemberAddress(i);
            memberToken += sqrt(bank.balanceOf(memberAddress, UNITS));
        }
        return  memberToken; 
    }

    function totalCooperativeTokens(
        DaoRegistry dao,
        BankExtension bank
    ) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 nbMembers = dao.getNbMembers();
        uint256 memberToken = 0;
        for (uint256 i = 0; i < nbMembers; i++) {
            address memberAddress = dao.getMemberAddress(i);
            if(bank.balanceOf(memberAddress, UNITS)>0)
                memberToken++;
        }
        return memberToken;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(
        BankExtension bank, 
        uint256 at
    )
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(
        BankExtension bank, 
        address member
    )
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(
        DaoRegistry dao, 
        address addr
    )
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        BankExtension bank,
        address member,
        uint256 at
    ) 
        internal 
        view 
        returns (uint256) 
    {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(
        DaoRegistry dao
    )
        internal
        view
        returns (bool)
    {
        return
            dao.state() == IDaoRegistry.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IDaoRegistry.sol";
import "../extensions/interfaces/IExtension.sol";
import "../modifiers/MemberGuard.sol";
import "../modifiers/AdapterGuard.sol";
import "../libraries/DaoLibrary.sol";

/// @title Dao Registry
/// @notice This contract is used to manage the core DAO state 
contract DaoRegistry is
    IDaoRegistry,
    MemberGuard, 
    AdapterGuard 
{
    /**
     * PUBLIC VARIABLES
     */

    /// @notice controls the lock mechanism using the block.number
    uint256 public lockedAt;

    /// @notice internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    /// @notice The dao state starts as CREATION and is changed to READY after the finalizeDao call
    DaoState public state;

    /// @notice The map to track all members of the DAO with their existing flags
    mapping(address => Member) public members;

    /// @notice delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;

    /// @notice The map that tracks the voting adapter address per proposalId: proposalId => adapterAddress
    mapping(bytes32 => address) public votingAdapter;

    /// @notice The map that keeps track of all adapters registered in the DAO: sha3(adapterId) => adapterAddress
    mapping(bytes32 => address) public adapters;

    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;

    /// @notice The map that keeps track of all extensions registered in the DAO: sha3(extId) => extAddress
    mapping(bytes32 => address) public extensions;

    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;

    /// @notice The map that keeps track of configuration parameters for the DAO and adapters: sha3(configId) => numericValue
    mapping(bytes32 => uint256) public mainConfiguration;
    
    /// @notice The map to track all the configuration of type Address: sha3(configId) => addressValue
    mapping(bytes32 => address) public addressConfiguration;


    /**
     * PRIVATE VARIABLES
     */

    /// @notice The list of members
    address[] private _members;
    /// @notice memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) private _checkpoints;
    /// @notice memberAddress => numDelegateCheckpoints
    mapping(address => uint32) private _numCheckpoints;


    /**
     * INITIALIZE
     */
    
    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    ///@inheritdoc IDaoRegistry
    //slither-disable-next-line reentrancy-no-eth
    function initialize(
        address creator, 
        address payer
    ) 
        external 
    {
        if(initialized)
            revert DaoRegistry_AlreadyInitialized();

        initialized = true;
        
        potentialNewMember(msg.sender);
        potentialNewMember(creator);
        potentialNewMember(payer);
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    ///@inheritdoc IDaoRegistry
    function finalizeDao() 
        external 
    {
        if(
            !isActiveMember(this, msg.sender) && 
            !isAdapter(msg.sender)
        )
            revert DaoRegistry_NotAllowedToFinalize();

        state = DaoState.READY;
    }

    ///@inheritdoc IDaoRegistry
    function lockSession() 
        external 
    {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    ///@inheritdoc IDaoRegistry
    function unlockSession() 
        external 
    {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    ///@inheritdoc IDaoRegistry
    function setConfiguration(
        bytes32 key, 
        uint256 value
    )
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(
            key, 
            value
        );
    }

    ///@inheritdoc IDaoRegistry
    function setAddressConfiguration(
        bytes32 key, 
        address value
    )
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(
            key, 
            value
        );
    }

    ///@inheritdoc IDaoRegistry
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) 
        external 
        hasAccess(this, AclFlag.REPLACE_ADAPTER) 
    {
        if(adapterId == bytes32(0))
            revert DaoRegistry_EmptyAdapterId();

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];

            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;

            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            if(inverseAdapters[adapterAddress].id != bytes32(0))
                revert DaoRegistry_RegisteredAdapterId();

            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            
            emit AdapterAdded(
                adapterId, 
                adapterAddress, 
                acl
            );
        }
    }

    // slither-disable-next-line reentrancy-events
    ///@inheritdoc IDaoRegistry
    function addExtension(
        bytes32 extensionId, 
        IExtension extension
    )
        external
        hasAccess(this, AclFlag.ADD_EXTENSION)
    {
        if(extensionId == bytes32(0))
            revert DaoRegistry_EmptyExtensionId();

        if(extensions[extensionId] != address(0x0))
            revert DaoRegistry_RegisteredExtensionId();

        if(inverseExtensions[address(extension)].deleted)
            revert DaoRegistry_DeletedExtension();

        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;

        emit ExtensionAdded(
            extensionId, 
            address(extension)
        );
    }

    ///@inheritdoc IDaoRegistry
    function removeExtension(
        bytes32 extensionId
    )
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        if(extensionId == bytes32(0))
            revert DaoRegistry_EmptyExtensionId();

        address extensionAddress = extensions[extensionId];

        if(extensionAddress == address(0x0))
            revert DaoRegistry_UnregisteredExtensionId();

        ExtensionEntry storage extEntry = inverseExtensions[extensionAddress];
        extEntry.deleted = true;
        
        //slither-disable-next-line mapping-deletion
        delete extensions[extensionId];
        
        emit ExtensionRemoved(extensionId);
    }

    ///@inheritdoc IDaoRegistry
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    )   
        external 
        hasAccess(this, AclFlag.ADD_EXTENSION) 
    {
        if(!isAdapter(adapterAddress))
            revert DaoRegistry_UnregisteredAdapterId();

        if(!isExtension(extensionAddress))
            revert DaoRegistry_UnregisteredExtensionId();

        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    ///@inheritdoc IDaoRegistry
    function submitProposal(
        bytes32 proposalId
    )
        external
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        if(proposalId == bytes32(0))
            revert DaoRegistry_InvalidProposalId();
        
        if(getProposalFlag(proposalId, ProposalFlag.EXISTS))
            revert DaoRegistry_NotUniqueProposalId();

        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS

        emit SubmittedProposal(
            proposalId, 
            1
        );
    }

    ///@inheritdoc IDaoRegistry
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) 
        external 
        onlyMember2(this, sponsoringMember) 
    {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        if(proposal.adapterAddress != msg.sender)
            revert DaoRegistry_AdapterMismatch();

        if(DaoLibrary.getFlag(flags, uint8(ProposalFlag.PROCESSED)))
            revert DaoRegistry_AlreadyProcessedProposalId();

        votingAdapter[proposalId] = votingAdapterAddr;

        emit SponsoredProposal(
            proposalId, 
            flags, 
            votingAdapterAddr
        );
    }

    ///@inheritdoc IDaoRegistry
    function processProposal(
        bytes32 proposalId
    ) 
        external
    {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        if(proposal.adapterAddress != msg.sender)
            revert DaoRegistry_AdapterMismatch();

        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    ///@inheritdoc IDaoRegistry
    function jailMember(
        address memberAddress
    )
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        if(memberAddress == address(0x0))
            revert DaoRegistry_InvalidMember();

        Member storage member = members[memberAddress];
        if(!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)))
            revert DaoRegistry_NotExistingMember();

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            true
        );
    }

    ///@inheritdoc IDaoRegistry
    function unjailMember(
        address memberAddress
    )
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        if(memberAddress == address(0x0))
            revert DaoRegistry_InvalidMember();

        Member storage member = members[memberAddress];
        if(!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)))
            revert DaoRegistry_NotExistingMember();

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            false
        );
    }

    ///@inheritdoc IDaoRegistry
    function updateDelegateKey(
        address memberAddr, 
        address newDelegateKey
    )
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        if(newDelegateKey == address(0x0))
            revert DaoRegistry_InvalidDelegateKey();

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            if(memberAddressesByDelegatedKey[newDelegateKey] != address(0x0))
                revert DaoRegistry_DelegateKeyAlreadyTaken();
        } else {
            if(memberAddressesByDelegatedKey[memberAddr] != address(0x0))
                revert DaoRegistry_DelegateKeyAddressAlreadyTaken();
        }

        Member storage member = members[memberAddr];
        if(!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)))
            revert DaoRegistry_NotExistingMember();

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }


    /**
     * PUBLIC FUNCTIONS
     */

    /**
     * @notice Adds a new member to the DAO
     * @param memberAddressArray The array of member addresses to add
     */
    //slither-disable-next-line external-function
    function potentialNewMemberBatch(
        address[] calldata memberAddressArray
    )
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        for(uint256 i = 0;i<memberAddressArray.length;i++){
            if(memberAddressArray[i] == address(0x0))
                revert DaoRegistry_InvalidMember(); 

            Member storage member = members[memberAddressArray[i]];
            if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                if(memberAddressesByDelegatedKey[memberAddressArray[i]] != address(0x0))
                    revert DaoRegistry_MemberAddressAlreadyUsedAsDelegate();

                member.flags = DaoLibrary.setFlag(
                    member.flags,
                    uint8(MemberFlag.EXISTS),
                    true
                );
                memberAddressesByDelegatedKey[memberAddressArray[i]] = memberAddressArray[i];
                _members.push(memberAddressArray[i]);
            }
            address bankAddress = extensions[DaoLibrary.BANK_EXT];
            if  (bankAddress != address(0x0)) {
                BankExtension bank = BankExtension(bankAddress);
                //slither-disable-next-line calls-loop
                if (bank.balanceOf(memberAddressArray[i], DaoLibrary.MEMBER_COUNT) == 0) {
                    //slither-disable-next-line calls-loop
                    bank.addToBalance(
                        this,
                        memberAddressArray[i],
                        DaoLibrary.MEMBER_COUNT,
                        1
                    );
                }
            }
        }
    }

    /**
     * @notice Registers a member address in the DAO if it is not registered or invalid.
     * @notice A potential new member is a member that holds no shares, and its registration still needs to be voted on.
     * @param memberAddress The address of the member to register.
     */
    function potentialNewMember(
        address memberAddress
    )
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        if(memberAddress == address(0x0))
            revert DaoRegistry_InvalidMember(); 

        Member storage member = members[memberAddress];
        if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            if(memberAddressesByDelegatedKey[memberAddress] != address(0x0))
                revert DaoRegistry_MemberAddressAlreadyUsedAsDelegate();
                
            member.flags = DaoLibrary.setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[DaoLibrary.BANK_EXT];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, DaoLibrary.MEMBER_COUNT) == 0) {
                bank.addToBalance(
                    this,
                    memberAddress,
                    DaoLibrary.MEMBER_COUNT,
                    1
                );
            }
        }
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(
        bytes32 proposalId, 
        ProposalFlag flag
    )
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        if(!DaoLibrary.getFlag(flags, uint8(ProposalFlag.EXISTS)))
            revert DaoRegistry_NotExistingProposalId();

        if(proposal.adapterAddress != msg.sender)
            revert DaoRegistry_AdapterMismatch();

        if(DaoLibrary.getFlag(flags, uint8(flag))) 
            revert DaoRegistry_AlreadySetFlag();

        flags = DaoLibrary.setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) 
        internal
    {
        uint32 nCheckpoints = _numCheckpoints[member];
        // The only condition that we should allow the deletegaKey upgrade
        // is when the block.number exactly matches the fromBlock value.
        // Anything different from that should generate a new checkpoint.
        if (
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            //slither-disable-next-line incorrect-equality
            _checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        )
        {
            _checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } 
        else {
            _checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            _numCheckpoints[member] = nCheckpoints + 1;
        }
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    /**
     * @param proposalId The ID of the proposal to be checked
     * @return True if the proposal exists, false otherwise
     */
    function getIsProposalUsed(
        bytes32 proposalId
    )
        external
        view
        returns (bool)
    {
        if(proposals[proposalId].adapterAddress == address(0x0))
            return false;
        return true;
    }

    /**
     * @param checkAddr The address to check for a delegate
     * @return The delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(
        address checkAddr
    )
        external
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(
        address memberAddr
    )
        external
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? _checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The delegate key of the member
     */
    function getPriorDelegateKey(
        address memberAddr, 
        uint256 blockNumber
    )
        external
        view
        returns (address)
    {
        if(blockNumber >= block.number)
            revert DaoRegistry_BlockNumberNotFinalized();

        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            _checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return _checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (_checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = _checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        return _checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Returns the number of members in the registry.
     */
    function getNbMembers(
    ) 
        external 
        view 
        returns (uint256) 
    {
        return _members.length;
    }

    /**
     * @notice Returns the member address for the given index.
     */
    function getMemberAddress(
        uint256 index
    ) 
        external 
        view 
        returns (address) 
    {
        return _members[index];
    }

    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(
        address addr
    ) 
        external 
        view 
        returns (bool) 
    {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) 
        external 
        view 
        returns (bool) 
    {
        return
            isAdapter(adapterAddress) &&
            DaoLibrary.getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(
        bytes32 extensionId
    )
        external
        view
        returns (address)
    {
        if(extensions[extensionId] == address(0))
            revert DaoRegistry_UnregisteredExtensionId();

        return extensions[extensionId];
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(
        address adapterAddress, 
        AclFlag flag
    )
        external
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(
        bytes32 adapterId
    )
        external
        view
        returns (address)
    {
        if(adapters[adapterId] == address(0)) 
            revert DaoRegistry_AdapterNotFound();

        return adapters[adapterId];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(
        bytes32 key
    ) 
        external 
        view 
        returns (uint256) 
    {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(
        bytes32 key
    )
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    /**
     * @notice Checks if a given member address is not jailed.
     * @param memberAddress The address of the member to check the flag.
     */
    function notJailed(
        address memberAddress
    ) 
        external 
        view 
        returns (bool) 
    {
        return
            !DaoLibrary.getFlag(
                members[memberAddress].flags,
                uint8(MemberFlag.JAILED)
            );
    }
    
    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(
        address memberAddress, 
        MemberFlag flag
    )
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(members[memberAddress].flags, uint8(flag));
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(
        address adapterAddress
    ) 
        public 
        view 
        returns (bool) 
    {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(
        address extensionAddr
    ) 
        public 
        view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? _checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DaoLibrary.sol";
import "../core/DaoRegistry.sol";
import "./interfaces/IExtension.sol";
import "./interfaces/ICommunityEquityExtension.sol";

/// @title CommunityEquity Extension
/// @notice This contract is used to manage community equity
contract CommunityEquityExtension is 
    IExtension,
    ICommunityEquityExtension
{
    /**
     * PUBLIC VARIABLES
     */

    /// @notice 
    bool public initialized;

    /// @notice 
    DaoLibrary.EpochConfig[] public epochConfig;

    /// @notice 
    CommunityEquityConfig[] public communityEquityConfig;

    /// @notice 
    mapping(bytes32 => uint) public communityEquityIndex;

    /// @notice 
    mapping(bytes32 => CommunityEquityMemberConfig[]) public communityEquityMemberConfig;

    /// @notice 
    mapping(bytes32 => mapping(address => uint)) public communityEquityMemberIndex;


    /**
     * PRIVATE VARIABLES
     */
    
    /// @notice 
    DaoRegistry private _dao;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}
    
    /// @inheritdoc IExtension
    function initialize(
        DaoRegistry dao, 
        address 
    ) 
        external 
        override 
    {
        if(initialized)
            revert CommunityEquity_AlreadyInitialized();

        _dao = dao;

        initialized = true;
    }
    

    /**
     * MODIFIER
     */

    /// @notice 
    modifier hasExtensionAccess(
        DaoRegistry dao, 
        AclFlag flag
    ) 
    {
        if(
            _dao != dao ||
            (
                address(this) != msg.sender &&
                address(_dao) != msg.sender &&
                initialized &&
                !DaoLibrary.isInCreationModeAndHasAccess(_dao) &&
                !_dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert CommunityEquity_AccessDenied();
        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc ICommunityEquityExtension
    function setCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityConfig calldata _communityEquityConfig 
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) 
    {
        uint length = communityEquityConfig.length;
        if(communityEquityIndex[communityEquityId] == 0){
            communityEquityIndex[communityEquityId] = length + 1;
            communityEquityConfig.push(_communityEquityConfig);
        }else{
            communityEquityConfig[communityEquityIndex[communityEquityId]-1] = _communityEquityConfig;
        } 
    }

    /// @inheritdoc ICommunityEquityExtension
    function setCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityConfig calldata _communityEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) 
    {
        uint length = communityEquityConfig.length;
        if(communityEquityIndex[communityEquityId] == 0){
            communityEquityIndex[communityEquityId] = length + 1;
            communityEquityConfig.push(_communityEquityConfig);
            epochConfig.push(_epochConfig);
        }else{
            communityEquityConfig[communityEquityIndex[communityEquityId]-1] = _communityEquityConfig;
            epochConfig[communityEquityIndex[communityEquityId]-1] = _epochConfig;
        } 
    }

    /// @inheritdoc ICommunityEquityExtension
    function setCommunityEquityEpoch(
        DaoRegistry dao,
        bytes32 communityEquityId,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) 
    {
        uint length = communityEquityConfig.length;
        if(communityEquityIndex[communityEquityId] == 0){
            communityEquityIndex[communityEquityId] = length + 1;
            epochConfig.push(_epochConfig);
        }else{
            epochConfig[communityEquityIndex[communityEquityId]-1] = _epochConfig;
        }
    }

    /// @inheritdoc ICommunityEquityExtension
    function setCommunityEquityMember(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external
        override 
        hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) 
    {
        if(!DaoLibrary.isNotReservedAddress(_communityEquityMemberConfig.memberAddress))
            revert Extension_ReservedAddress();
        uint length = communityEquityMemberConfig[communityEquityId].length;
        if(communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig.memberAddress]==0){
            communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig.memberAddress]=length+1;
            communityEquityMemberConfig[communityEquityId].push(_communityEquityMemberConfig);
        }else{
            communityEquityMemberConfig[communityEquityId][communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig.memberAddress]-1] = _communityEquityMemberConfig;
        } 
    }

    /// @inheritdoc ICommunityEquityExtension
    function setCommunityEquityMemberBatch(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityMemberConfig[] calldata _communityEquityMemberConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_COMMUNITY_EQUITY) 
    {
        for(uint256 i=0;i<_communityEquityMemberConfig.length;i++){
            if(DaoLibrary.isNotReservedAddress(_communityEquityMemberConfig[i].memberAddress)){
                uint length = communityEquityMemberConfig[communityEquityId].length;
                if(communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig[i].memberAddress]==0){
                    communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig[i].memberAddress]=length+1;
                    communityEquityMemberConfig[communityEquityId].push(_communityEquityMemberConfig[i]);
                }else{
                    communityEquityMemberConfig[communityEquityId][communityEquityMemberIndex[communityEquityId][_communityEquityMemberConfig[i].memberAddress]-1] = _communityEquityMemberConfig[i];
                } 
            }
        }
    }

    /// @inheritdoc ICommunityEquityExtension
    function removeCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_EQUITY) 
    {
        if(communityEquityIndex[communityEquityId]==0)
            revert CommunityEquity_Undefinied();
            
        communityEquityIndex[communityEquityId]=0;
    }

    /// @inheritdoc ICommunityEquityExtension
    function removeCommunityEquityMember(
        DaoRegistry dao,
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_COMMUNITY_EQUITY) 
    {
        communityEquityMemberIndex[communityEquityId][_memberAddress]=0;
    }
    

    /**
     * READ-ONLY FUNCTIONS
     */

    function getCommunityEquityEpochConfig(
        bytes32 communityEquityId
    ) 
        external 
        view 
        returns (DaoLibrary.EpochConfig memory) 
    {
        if(communityEquityIndex[communityEquityId]==0)
            revert CommunityEquity_Undefinied();
        return epochConfig[communityEquityIndex[communityEquityId]-1];
    }

    function getCommunityEquityConfig(
        bytes32 communityEquityId
    ) 
        external 
        view 
        returns (CommunityEquityConfig memory) 
    {
        if(communityEquityIndex[communityEquityId]==0)
            revert CommunityEquity_Undefinied();
        return communityEquityConfig[communityEquityIndex[communityEquityId]-1];
    }

    function getCommunityEquityMemberConfig(
        bytes32 communityEquityId
    ) 
        external 
        view 
        returns (CommunityEquityMemberConfig[] memory) 
    {
        return communityEquityMemberConfig[communityEquityId];
    }

    function getIsCommunityEquity(
        bytes32 communityEquityId
    ) 
        external 
        view 
        returns (bool) 
    {
        return communityEquityIndex[communityEquityId]>0;
    }

    function getIsCommunityEquityMember(
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external 
        view 
        returns (bool) 
    {
        return communityEquityMemberIndex[communityEquityId][_memberAddress]>0;
    }

    function getCommunityEquityMemberConfig(
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external 
        view 
        returns (CommunityEquityMemberConfig memory) 
    {
        if(communityEquityMemberIndex[communityEquityId][_memberAddress]==0)
            revert CommunityEquity_MemberUndefinied();
        return communityEquityMemberConfig[communityEquityId][communityEquityMemberIndex[communityEquityId][_memberAddress]-1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IBankExtension.sol";
import "./interfaces/IExtension.sol";
import "../libraries/DaoLibrary.sol";
import "../modifiers/AdapterGuard.sol";


/// @title Bank Extension
/// @notice This contract is used to manage the funds of the DAO
contract BankExtension is 
    IExtension,
    IBankExtension,
    ERC165 
{
    using Address for address payable;
    using SafeERC20 for IERC20;
    

    /**
     * PUBLIC VARIABLES
     */
    
    /// @notice the maximum number of external tokens that can be stored in the bank
    uint8 public maxExternalTokens;

    /// @notice 
    bool public initialized;

    /// @notice
    address[] public tokens;
    
    /// @notice
    address[] public internalTokens;
    
    /// @notice tokenAddress => availability
    mapping(address => bool) public availableTokens;
    
    /// @notice
    mapping(address => bool) public availableInternalTokens;
    
    /// @notice tokenAddress => memberAddress   => checkpointNum  => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
    
    /// @notice
    public checkpoints;
    
    /// @notice tokenAddress => memberAddress   => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;


    /**
     * PRIVATE VARIABLES
     */

    /// @notice
    DaoRegistry private _dao;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /// @inheritdoc IExtension
    function initialize(
        DaoRegistry dao, 
        address creator
    ) 
        external 
        override 
    {
        if(initialized)
            revert Bank_AccessDenied();

        if(!dao.isMember(creator))
            revert Extension_NotAMember(creator); 
        
        _dao = dao;

        availableInternalTokens[DaoLibrary.UNITS] = true;
        internalTokens.push(DaoLibrary.UNITS);

        availableInternalTokens[DaoLibrary.MEMBER_COUNT] = true;
        internalTokens.push(DaoLibrary.MEMBER_COUNT);
        
        uint256 nbMembers = dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            addToBalance(
                dao,
                dao.getMemberAddress(i),
                DaoLibrary.MEMBER_COUNT,
                1
            );
        }

        _createNewAmountCheckpoint(
            creator, 
            DaoLibrary.UNITS, 
            1
        );

        _createNewAmountCheckpoint(
            DaoLibrary.TOTAL, 
            DaoLibrary.UNITS, 
            1
        );
        initialized = true;
    }


    /**
     * MODIFIER
     */

    /// @notice
    modifier hasExtensionAccess(
        DaoRegistry dao, 
        AclFlag flag
    ) 
    {
        if(
            _dao != dao ||
            (
                address(this) != msg.sender &&
                address(_dao) != msg.sender &&
                initialized &&
                !DaoLibrary.isInCreationModeAndHasAccess(_dao) &&
                !_dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert Bank_AccessDenied();
        _;
    }

    /// @notice 
    modifier noProposal(
    ) 
    {
        if(_dao.lockedAt() >= block.number)
            revert Bank_DaoLocked(); 

        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc IBankExtension
    function withdraw(
        DaoRegistry dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) 
        external 
        override
        hasExtensionAccess(dao, AclFlag.WITHDRAW) 
    {
        if(balanceOf(member, tokenAddr) < amount)
            revert Bank_NotEnoughFunds();

        subtractFromBalance(
            dao, 
            member, 
            tokenAddr, 
            amount
        );

        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            member.sendValue(amount);
        } 
        else {
            IERC20(tokenAddr).safeTransfer(member, amount);
        }

        emit Withdraw(
            member, 
            tokenAddr, 
            uint160(amount)
        );
    }

    /// @inheritdoc IBankExtension
    function withdrawTo(
        DaoRegistry dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.WITHDRAW) 
    {
        if(balanceOf(memberFrom, tokenAddr) < amount)
            revert Bank_NotEnoughFunds();

        subtractFromBalance(
            dao, 
            memberFrom, 
            tokenAddr, 
            amount
        );

        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            memberTo.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(memberTo, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit WithdrawTo(
            memberFrom, 
            memberTo, 
            tokenAddr, 
            uint160(amount)
        );
    }

    /// @inheritdoc IBankExtension
    function setMaxExternalTokens(
        uint8 maxTokens
    ) 
        external
        override
    {
        if(initialized)
            revert Bank_AlreadyInitialized();

        if(maxTokens <= 0 || maxTokens > DaoLibrary.MAX_TOKENS_GUILD_BANK)
            revert Bank_MaxExternalTokensOutOfRange();

        maxExternalTokens = maxTokens;
    }

    /// @inheritdoc IBankExtension
    function registerPotentialNewToken(
        DaoRegistry dao, 
        address token
    )
        external
        override
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_TOKEN)
    {
        if(!DaoLibrary.isNotReservedAddress(token))
            revert Extension_ReservedAddress();

        if(availableInternalTokens[token]) 
            revert Bank_TokenAlreadyInternal(token);
        
        if(tokens.length > maxExternalTokens)
            revert Bank_TooManyExternalTokens();

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /// @inheritdoc IBankExtension
    function registerPotentialNewInternalToken(
        DaoRegistry dao, 
        address token
    )
        external
        override
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        if(!DaoLibrary.isNotReservedAddress(token)) 
            revert Extension_ReservedAddress();

        if(availableTokens[token]) 
            revert Bank_TokenAlreadyExternal(token);

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    /// @inheritdoc IBankExtension
    function updateToken(
        DaoRegistry dao, 
        address tokenAddr
    )
        external
        override
        hasExtensionAccess(dao, AclFlag.UPDATE_TOKEN)
    {
        if(!isTokenAllowed(tokenAddr))
            revert Bank_TokenNotRegistered(tokenAddr);

        uint256 totalBalance = balanceOf(DaoLibrary.TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            realBalance = address(this).balance;
        } 
        else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(
                dao,
                DaoLibrary.GUILD,
                tokenAddr,
                realBalance - totalBalance
            );
        } 
        else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(DaoLibrary.GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    tokensToRemove
                );
            } 
            else {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    guildBalance
                );
            }
        }
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        DaoRegistry dao,
        address from,
        address to,
        address token,
        uint256 amount
    ) 
        external 
        hasExtensionAccess(dao, AclFlag.INTERNAL_TRANSFER) 
    {
        if(!_dao.notJailed(from))
            revert Bank_NoTransferFromJailedMember(from);

        if(!_dao.notJailed(to))
            revert Bank_NoTransferToJailedMember(to);

        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(
            from, 
            token, 
            newAmount
        );
        
        _createNewAmountCheckpoint(
            to, 
            token, 
            newAmount2
        );
    }

    function addToBalance(
        address,
        address,
        uint256
    ) 
        external 
        payable 
    {
        revert Bank_NotImplemented();
    }

    function subtractFromBalance(
        address,
        address,
        uint256
    ) 
        external 
        pure 
    {
        revert Bank_NotImplemented();
    }

    function internalTransfer(
        address,
        address,
        address,
        uint256
    ) 
        external 
        pure 
    {
        revert Bank_NotImplemented();
    }



    /**
     * PUBLIC FUNCTIONS
     */

    /**
     * @notice Adds to a member"s balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) 
        public 
        payable 
        hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) 
    {
        if(!availableTokens[token] && !availableInternalTokens[token])
            revert Bank_TokenNotRegistered(token);

        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }

    function addToBalanceBatch(
        DaoRegistry dao,
        address[] memory member ,
        address token,
        uint256[] memory amount
    ) 
        public 
        payable 
        hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) 
    {
        if(!availableTokens[token] && !availableInternalTokens[token])
            revert Bank_TokenNotRegistered(token);

        for(uint256 i;i<member.length;i++){
            uint256 newAmount = balanceOf(member[i], token) + amount[i];
            uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount[i];
            _createNewAmountCheckpoint(member[i], token, newAmount);
            _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
        }

    }

    /**
     * @notice Remove from a member"s balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) 
        public 
        hasExtensionAccess(dao, AclFlag.SUB_FROM_BALANCE) 
    {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }


    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) 
        internal 
    {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            if(amount >= type(uint88).max)
                revert Bank_InternalTokenAmountLimitExceeded();

            isValidToken = true;
        } 
        else if (availableTokens[token]) {
            if(amount >= type(uint160).max)
                revert Bank_ExternalTokenAmountLimitExceeded();

            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        if(!isValidToken)
            revert Bank_UnregisteredToken();

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            // The only condition that we should allow the amount update
            // is when the block.number exactly matches the fromBlock value.
            // Anything different from that should generate a new checkpoint.
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) 
        {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } 
        else {
            checkpoints[token][member][nCheckpoints] = 
                Checkpoint(
                    uint96(block.number),
                    newAmount
                );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        //slither-disable-next-line reentrancy-events
        emit NewBalance(
            member, 
            token, 
            newAmount
        );
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank"s tokens
     */
    function getToken(
        uint256 index
    ) 
        external 
        view 
        returns (address) 
    {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() 
        external 
        view 
        returns (uint256) 
    {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() 
        external 
        view 
        returns (address[] memory) 
    {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank"s array of internal tokens
     */
    function getInternalToken(
        uint256 index
    ) 
        external 
        view 
        returns (address) 
    {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() 
        external 
        view 
        returns (uint256) 
    {
        return internalTokens.length;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) 
        external 
        view 
        returns (uint256) 
    {
        if(blockNumber >= block.number)
            revert Bank_BlockNumberNotFinalized();

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } 
            else if (cp.fromBlock < blockNumber) {
                lower = center;
            } 
            else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(
        address token
    ) 
        external 
        view 
        returns (bool) 
    {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(
        address token
    ) 
        public 
        view 
        returns (bool) 
    {
        return availableTokens[token];
    }

    /**
     * @notice Returns an member"s balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member"s balance of which will be returned
     * @return The amount in account"s tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            this.withdrawTo.selector == interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/DaoRegistry.sol";
import "./interfaces/IExtension.sol";
import "./interfaces/IMemberExtension.sol";
import "../libraries/DaoLibrary.sol";
import "../extensions/DynamicEquityExtension.sol";
import "../extensions/VestedEquityExtension.sol";
import "../extensions/CommunityEquityExtension.sol";
import "../extensions/BankExtension.sol";

/// @title Member Extension
/// @notice This contract is used to manage members
contract MemberExtension is 
    IExtension,
    IMemberExtension
{
    /**
     * PUBLIC VARIABLES
     */

    ///@notice 
    bool public initialized;

    ///@notice 
    MemberConfig[] public memberConfig;

    ///@notice 
    mapping(address => uint) public memberIndex;


    /**
     * PRIVATE VARIABLES
     */

    ///@notice 
    DaoRegistry private _dao;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /// @inheritdoc IExtension
    function initialize(
        DaoRegistry dao, 
        address 
    ) 
        external 
        override 
    {
        if(initialized)
            revert Member_AlreadyInitialized();

        _dao = dao;
    
        initialized = true;
    }


    /**
     * MODIFIER
     */

    ///@notice 
    modifier hasExtensionAccess(
        DaoRegistry dao, 
        AclFlag flag
    ) 
    {
        if(
            _dao != dao ||
            (
                address(this) != msg.sender &&
                address(_dao) != msg.sender &&
                initialized &&
                !DaoLibrary.isInCreationModeAndHasAccess(_dao) &&
                !_dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert Member_AccessDenied();
        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc IMemberExtension
    function setMember(
        DaoRegistry dao,
        MemberConfig calldata _memberConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_MEMBER) 
    {
        if(!DaoLibrary.isNotReservedAddress(_memberConfig.memberAddress))
            revert Member_ReservedAddress();
            
        uint length = memberConfig.length;
        if(memberIndex[_memberConfig.memberAddress]==0){
            memberIndex[_memberConfig.memberAddress]=length+1;
            memberConfig.push(_memberConfig);
            BankExtension bank = 
                BankExtension(
                    dao.getExtensionAddress(DaoLibrary.BANK_EXT)
                );
            DaoLibrary.potentialNewMember(
                _memberConfig.memberAddress,
                dao,
                bank
            );
            bank.addToBalance(
                dao,
                _memberConfig.memberAddress,
                DaoLibrary.UNITS,
                _memberConfig.initialAmount
            );
        }
        else{
            memberConfig[memberIndex[_memberConfig.memberAddress]-1] = _memberConfig;
        } 
    }

    /// @inheritdoc IMemberExtension
    function setMemberSetup(
        DaoRegistry dao,
        DynamicEquityExtension.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig,
        VestedEquityExtension.VestedEquityMemberConfig calldata _vestedEquityMemberConfig,
        CommunityEquityExtension.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external
        override 
        hasExtensionAccess(dao, AclFlag.SET_MEMBER) 
    {
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        dynamicEquity.setDynamicEquityMember(
            dao,
            _dynamicEquityMemberConfig
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        vestedEquity.setVestedEquityMember(
            dao,
            _vestedEquityMemberConfig
        );
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        communityEquity.setCommunityEquityMember(
            dao,
            DaoLibrary.COMMUNITY_EQUITY,
            _communityEquityMemberConfig
        );
    }

    /// @inheritdoc IMemberExtension
    function setMemberAppreciationRight(
        DaoRegistry dao,
        address _memberAddress,
        bool appreciationRight
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_MEMBER) 
    {
        if(memberIndex[_memberAddress]==0)
            revert Member_UndefinedMember();
        MemberConfig storage member = memberConfig[memberIndex[_memberAddress]-1];
        member.appreciationRight = appreciationRight;
    }

    /// @inheritdoc IMemberExtension
    function setMemberEnvironment(
        DaoRegistry dao,
        DynamicEquityExtension.DynamicEquityConfig memory _dynamicEquityConfig,
        VestedEquityExtension.VestedEquityConfig memory _vestedEquityConfig,
        CommunityEquityExtension.CommunityEquityConfig memory _communityEquityConfig,
        DaoLibrary.EpochConfig memory _epochConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_MEMBER) 
    {
        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        dynamicEquity.setDynamicEquity(dao, _dynamicEquityConfig, _epochConfig);
        vestedEquity.setVestedEquity(dao, _vestedEquityConfig);
        communityEquity.setCommunityEquity(dao, DaoLibrary.COMMUNITY_EQUITY, _communityEquityConfig, _epochConfig);
    }

    /// @inheritdoc IMemberExtension
    function removeMember(
        DaoRegistry dao,
        address _memberAddress
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_MEMBER) 
    {
        memberIndex[_memberAddress] = 0;
    }

    /// @inheritdoc IMemberExtension
    function removeMemberSetup(
        DaoRegistry dao,
        address _memberAddress
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_MEMBER) 
    {
        if(
            memberIndex[_memberAddress]==0 || 
            _memberAddress==address(0)
        )
            revert Member_UndefinedMember();

        DynamicEquityExtension dynamicEquity = DynamicEquityExtension(dao.getExtensionAddress(DaoLibrary.DYNAMIC_EQUITY_EXT));
        dynamicEquity.removeDynamicEquityMember(
            dao,
            _memberAddress
        );
        CommunityEquityExtension communityEquity = CommunityEquityExtension(dao.getExtensionAddress(DaoLibrary.COMMUNITY_EQUITY_EXT));
        communityEquity.removeCommunityEquityMember(
            dao,
            DaoLibrary.COMMUNITY_EQUITY,
            _memberAddress
        );
        VestedEquityExtension vestedEquity = VestedEquityExtension(dao.getExtensionAddress(DaoLibrary.VESTED_EQUITY_EXT));
        vestedEquity.removeVestedEquityMember(
            dao,
            _memberAddress
        );
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function getIsMember(
        address _memberAddress
    ) 
        public 
        view 
        returns (bool) 
    {
        return memberIndex[_memberAddress]>0;
    }

    function getMemberConfig(
        address _memberAddress
    ) 
        public 
        view 
        returns (MemberConfig memory) 
    {
        if(memberIndex[_memberAddress]==0)
            revert Member_UndefinedMember();

        return memberConfig[memberIndex[_memberAddress]-1];
    }

    function getMemberCount(      
    ) 
        public 
        view 
        returns (uint) 
    {
        uint counter= 0;
        for(uint i=0;i<memberConfig.length;i++){
            if(memberIndex[memberConfig[i].memberAddress]>0)
                counter++;
        }
        return counter;
    }

    function getMemberConfig(      
    ) 
        public 
        view 
        returns (MemberConfig[] memory) 
    {
        uint memberCount  = getMemberCount();
        MemberConfig[] memory temp = new MemberConfig[](memberCount);
        uint counter= 0;
        for(uint i=0;i<memberConfig.length;i++){
            if(memberIndex[memberConfig[i].memberAddress]>0){
                temp[counter] = memberConfig[i];
                counter++;
            }
        }
        return temp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/DaoRegistry.sol";
import "../core/interfaces/IDaoRegistry.sol";
import "../libraries/DaoLibrary.sol";

/// @title Adapter Guard
/// @notice This contract contains the modifiers used by the adapters
abstract contract AdapterGuard {
    /**
     * ERRORS
     */

    error AdapterGuard_ContractLocked(address adapterAddress);

    error AdapterGuard_NotAdapter(address adapterAddress);

    error AdapterGuard_NotExecutor(address adapterAddress);

    error AdapterGuard_DeniedAccess(address adapterAddress);


    /**
     * MODIFIER
     */

    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(
        DaoRegistry dao
    ) 
    {
        if(
            !dao.isAdapter(msg.sender) &&
            !DaoLibrary.isInCreationModeAndHasAccess(dao)
        )
            revert AdapterGuard_NotAdapter(msg.sender);

        _;
    }


    modifier reentrancyDaoGuard(
        DaoRegistry dao
    )
    {
        if(dao.lockedAt() == block.number)
            revert AdapterGuard_ContractLocked(address(this)); 

        dao.lockSession();

        _;

        dao.unlockSession();
    }

    modifier executorFunc(
        DaoRegistry dao
    ) 
    {
        address executorAddr = 
            dao.getExtensionAddress(
                keccak256("executor-ext")
            );
        if(address(this) != executorAddr)
            revert AdapterGuard_NotExecutor(address(this)); 

        _;
    }

    modifier hasAccess(
        DaoRegistry dao, 
        IDaoRegistry.AclFlag flag
    ) 
    {
        if(
            !DaoLibrary.isInCreationModeAndHasAccess(dao) &&
            !dao.hasAdapterAccess(msg.sender, flag)
        )
            revert AdapterGuard_DeniedAccess(msg.sender);

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/DaoRegistry.sol";
import "./events/ICommunityEquityAdapterEvents.sol";
import "./errors/ICommunityEquityAdapterErrors.sol";
import "../../libraries/VotingAdapterLibrary.sol";

/// @title Community Equity Adapter Interface
/// @notice This interface defines the functions that a community equity adapter must implement
interface ICommunityEquityAdapter is
    ICommunityEquityAdapterEvents,
    ICommunityEquityAdapterErrors
{
    /**
     * STRUCTS
     */

    /**
     * @dev struct to store the status, community equity id, community equity config and epoch config of a proposal to set a community equity
     * @param status the status of the proposal
     * @param communityEquityId the unique identifier of the community equity
     * @param communityEquityConfig the new configuration for the community equity
     * @param epochConfig the new configuration for the epoch
     */
    struct SetCommunityEquityProposal {
        VotingAdapterLibrary.ProposalStatus status;
        bytes32 communityEquityId;
        CommunityEquityExtension.CommunityEquityConfig communityEquityConfig;
        DaoLibrary.EpochConfig epochConfig;
    }

    /**
     * @dev struct to store the status, community equity id, and community equity member config of a proposal to set a community equity member
     * @param status the status of the proposal
     * @param communityEquityId the unique identifier of the community equity
     * @param communityEquityMemberConfig the new configuration for the community equity member
     */
    struct SetCommunityEquityMemberProposal {
        VotingAdapterLibrary.ProposalStatus status;
        bytes32 communityEquityId;
        CommunityEquityExtension.CommunityEquityMemberConfig communityEquityMemberConfig;
    }

    /**
     * @dev struct to store the status, community equity id, and member address of a proposal to remove a community equity member
     * @param status the status of the proposal
     * @param communityEquityId the unique identifier of the community equity
     * @param memberAddress the address of the member to be removed
     */
    struct RemoveCommunityEquityMemberProposal {
        VotingAdapterLibrary.ProposalStatus status;
        bytes32 communityEquityId;
        address memberAddress;
    }

    /**
    * @dev struct to store the status and community equity id of a proposal to remove a community equity
    * @param status the status of the proposal
    * @param communityEquityId the unique identifier of the community equity to be removed
    */
    struct RemoveCommunityEquityProposal {
        VotingAdapterLibrary.ProposalStatus status;
        bytes32 communityEquityId;
    }


    /**
     * EXTERNAL FUNCTIONS
     */
    
    /**
    * @dev function to submit a proposal to set a community equity
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier for the proposal
    * @param data extra data associated with the proposal
    * @param communityEquityId unique identifier of the community equity
    * @param _communityEquityConfig the new configuration for the community equity
    * @param _epochConfig the new configuration for the epoch
    */
    function submitSetCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        CommunityEquityExtension.CommunityEquityConfig calldata _communityEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external;

    /**
    * @dev function to submit a proposal to set a community equity member
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier for the proposal
    * @param data extra data associated with the proposal
    * @param communityEquityId unique identifier of the community equity
    * @param _communityEquityMemberConfig the new configuration for the community equity member
    */
    function submitSetCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        CommunityEquityExtension.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external;

    /**
    * @dev function to submit a proposal to remove a community equity
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier for the proposal
    * @param data extra data associated with the proposal
    * @param communityEquityId unique identifier of the community equity to be removed
    */
    function submitRemoveCommunityEquityProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId
    ) 
        external;

    /**
    * @dev function to submit a proposal to remove a community equity member
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier for the proposal
    * @param data extra data associated with the proposal
    * @param communityEquityId unique identifier of the community equity
    * @param _memberAddress address of the community equity member to be removed
    */
    function submitRemoveCommunityEquityMemberProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external;
        
    /**
    * @dev function to process a proposal to set a community equity
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier of the proposal
    */
    function processSetCommunityEquityProposal(
        DaoRegistry dao, 
        bytes32 proposalId
    ) 
        external;

    /**
    * @dev function to process a proposal to set a community equity member
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier of the proposal
    */
    function processSetCommunityEquityMemberProposal(
        DaoRegistry dao, 
        bytes32 proposalId
    )   
        external;

    /**
    * @dev function to process a proposal to remove a community equity
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier of the proposal
    */
    function processRemoveCommunityEquityProposal(
        DaoRegistry dao, 
        bytes32 proposalId
    ) 
        external; 

    /**
    * @dev function to process a proposal to remove a community equity member
    * @param dao DaoRegistry contract instance
    * @param proposalId unique identifier of the proposal
    */
    function processRemoveCommunityEquityMemberProposal(
        DaoRegistry dao, 
        bytes32 proposalId
    ) 
        external;  

    /**
    * @dev function to distribute the community equity
    * @param dao DaoRegistry contract instance
    * @param communityEquityId unique identifier of the community equity
    * @param _recipient recipient of the distribution
    * @param _amountToBeSent amount to be sent
    */
    function actCommunityEquityMemberDistribute(
        DaoRegistry dao,
        bytes32 communityEquityId,
        address _recipient,
        uint256 _amountToBeSent
    ) 
        external;

    /**
    * @dev function to update the community equity epoch
    * @param dao DaoRegistry contract instance
    * @param communityEquityId unique identifier of the community equity
    */
    function actCommunityEquityEpochUpdate(
        DaoRegistry dao,
        bytes32 communityEquityId
    ) 
        external;  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/DaoRegistry.sol";
import "./events/IVotingAdapterEvents.sol";
import "./errors/IVotingAdapterErrors.sol";
import "../../libraries/VotingAdapterLibrary.sol";

/// @title Voting Adapter Interface
/// @notice This interface defines the functions that a voting adapter must implement
interface IVotingAdapter is 
    IVotingAdapterEvents,
    IVotingAdapterErrors
{
    /**
     * STRUCTS
     */

    struct GenericProposal {
        VotingAdapterLibrary.ProposalStatus status;
        bytes data;
        address addressSender;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    function submitGenericProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data
    ) 
        external;

    function processGenericProposal(
        DaoRegistry dao, 
        bytes32 proposalId
    )
        external;      

    function getAdapterName() 
        external 
        pure 
        returns (
            string memory
        );

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        VotingAdapterLibrary.ProposalType
    ) 
        external;

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        VotingAdapterLibrary.ProposalType,
        VotingAdapterLibrary.VotingConfig memory
    ) 
        external;
    
    function cancelVote(
        DaoRegistry dao, 
        bytes32 proposalId
    ) 
        external;


    /**
     * READ-ONLY FUNCTIONS
     */
    
    function voteResult(
        DaoRegistry dao, 
        bytes32 proposalId
    ) 
        external 
        view 
        returns (
            VotingAdapterLibrary.VotingState
        );

     function getVotingConfig(
        address dao
    ) 
        external 
        view 
        returns (
            VotingAdapterLibrary.VotingConfig memory
        );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../core/DaoRegistry.sol";
import "./BankExtension.sol";
import "./interfaces/IExtension.sol";
import "./interfaces/errors/IERC20Errors.sol";
import "../adapters/interfaces/IERC20Adapter.sol";
import "../libraries/DaoLibrary.sol";
import "../modifiers/AdapterGuard.sol";

/// @title ERC20 Extension
/// @notice This contract is used to manage ERC20 tokens
contract ERC20Extension is 
    AdapterGuard, 
    IExtension, 
    IERC20,
    IERC20Errors
{
    /**
     * PUBLIC VARIABLE
     */

    ///@notice Internally tracks deployment under eip-1167 proxy pattern
    bool public initialized;

    ///@notice The DAO address that this extension belongs to
    DaoRegistry public dao;

    ///@notice The token address managed by the DAO that tracks the internal transfers
    address public tokenAddress;

    ///@notice The name of the token managed by the DAO
    string public tokenName;

    ///@notice The symbol of the token managed by the DAO
    string public tokenSymbol;

    ///@notice The number of decimals of the token managed by the DAO
    uint8 public tokenDecimals;
    
    
    /**
     * PRIVATE VARIABLE
     */

    ///@notice Tracks all the token allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    function initialize(
        DaoRegistry _dao, 
        address
    ) 
        external 
        override 
    {
        if(initialized)
            revert ERC20_AlreadyInitialized(); 

        if(tokenAddress == address(0x0))
            revert ERC20_InvalidTokenAddress();

        if(bytes(tokenName).length == 0) 
            revert ERC20_MissingTokenName();

        if(bytes(tokenSymbol).length == 0) 
            revert ERC20_MissingTokenSymbol();

        dao = _dao;

        initialized = true;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev Sets the token address if the extension is not initialized,
     * not reserved and not zero.
     */
    function setToken(
        address _tokenAddress
    ) 
        external 
    {
        if(initialized)
            revert ERC20_AlreadyInitialized(); 

        if(_tokenAddress == address(0x0)) 
            revert ERC20_InvalidTokenAddress();

        if(!DaoLibrary.isNotReservedAddress(_tokenAddress))
            revert ERC20_ReservedTokenAddress();

        tokenAddress = _tokenAddress;
    }

    /**
     * @dev Sets the name of the token if the extension is not initialized.
     */
    function setName(
        string memory _name
    ) 
        external 
    {
        if(initialized)
            revert ERC20_AlreadyInitialized(); 

        tokenName = _name;
    }

    /**
     * @dev Sets the token symbol if the extension is not initialized.
     */
    function setSymbol(
        string memory _symbol
    ) 
        external 
    {
        if(initialized)
            revert ERC20_AlreadyInitialized(); 

        tokenSymbol = _symbol;
    }

    /**
     * @dev Sets the token decimals if the extension is not initialized.
     */
    function setDecimals(
        uint8 _decimals
    ) 
        external 
    {
        if(initialized)
            revert ERC20_AlreadyInitialized(); 

        tokenDecimals = _decimals;
    }


    /**
     * PUBLIC FUNCTIONS
     */

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender The address account that will have the units decremented.
     * @param amount The amount to decrement from the spender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    // slither-disable-next-line reentrancy-benign
    function approve(
        address spender, 
        uint256 amount
    )
        public
        override
        reentrancyDaoGuard(dao)
        returns (bool)
    {
        address senderAddr = dao.getAddressIfDelegated(msg.sender);
        if(!DaoLibrary.isNotZeroAddress(senderAddr))
            revert ERC20_InvalidSender();

        if(!DaoLibrary.isNotZeroAddress(spender))
            revert ERC20_InvalidSpender();

        if(!dao.isMember(senderAddr))
            revert ERC20_SenderNotMember(); 

        if(!DaoLibrary.isNotReservedAddress(spender))
            revert ERC20_SpenderReservedAddress(); 

        _allowances[senderAddr][spender] = amount;
        // slither-disable-next-line reentrancy-events
        emit Approval(
            senderAddr, 
            spender, 
            amount
        );
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to increment in the recipient account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient, 
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        return
            transferFrom(
                dao.getAddressIfDelegated(msg.sender),
                recipient,
                amount
            );
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param sender The address account that will have the units decremented.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to decrement from the sender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) 
        public 
        override 
        returns (bool) 
    {
        if(!DaoLibrary.isNotZeroAddress(recipient))
            revert ERC20_InvalidRecipient();

        IERC20Adapter strategy = 
            IERC20Adapter(
                dao.getAdapterAddress(DaoLibrary.ERC20_ADPT)
            );

        (
            IERC20Adapter.ApprovalType approvalType,
            uint256 allowedAmount
        ) = strategy.evaluateTransfer(
                dao,
                tokenAddress,
                sender,
                recipient,
                amount,
                msg.sender
            );

        BankExtension bank = 
            BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );

        if(approvalType != IERC20Adapter.ApprovalType.NONE)
            revert ERC20_TransferNotAllowed();

        if (approvalType == IERC20Adapter.ApprovalType.SPECIAL) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(
                sender, 
                recipient, 
                amount
            );
            return true;
        }

        if (sender != msg.sender) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            //check if sender has approved msg.sender to spend amount
            if(currentAllowance < amount)
                revert ERC20_InsufficientAllowance();

            if (allowedAmount >= amount) {
                _allowances[sender][msg.sender] = currentAllowance - amount;
            }
        }

        if (allowedAmount >= amount) {
            _transferInternal(
                sender, 
                recipient, 
                amount, 
                bank
            );
            //slither-disable-next-line reentrancy-events
            emit Transfer(
                sender, 
                recipient, 
                amount
            );
            return true;
        }
        return false;
    }


    /**
     * INTERNAL FUNCTIONS
     */
    
    function _transferInternal(
        address senderAddr,
        address recipient,
        uint256 amount,
        BankExtension bank
    ) 
        internal
    {
        DaoLibrary.potentialNewMember(
            recipient, 
            dao, 
            bank
        );

        bank.internalTransfer(
            dao, 
            senderAddr, 
            recipient, 
            tokenAddress, 
            amount
        );
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    /**
     * @dev Returns the name of the token.
     */
    function name(
    ) 
        external 
        view 
        virtual 
        returns (string memory) 
    {
        return tokenName;
    }

    /**
     * @dev Returns the amount of tokens owned by `account` considering the snapshot.
     */
    function getPriorAmount(
        address account, 
        uint256 snapshot
    )
        external
        view
        returns (uint256)
    {
        BankExtension bank = 
            BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
        return bank.getPriorAmount(account, tokenAddress, snapshot);
    }
    
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol(
    ) 
        external 
        view 
        virtual 
        returns (string memory) 
    {
        return tokenSymbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals(
    ) 
        external 
        view 
        virtual 
        returns (uint8) 
    {
        return tokenDecimals;
    }

    /**
     * @dev Returns the token address managed by the DAO that tracks the
     * internal transfers.
     */
    function token(
    ) 
        external 
        view 
        virtual 
        returns (address) 
    {
        return tokenAddress;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner, 
        address spender
    )
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply(
    ) 
        public 
        view 
        override 
        returns (uint256) 
    {
        BankExtension bank = 
            BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
        return bank.balanceOf(DaoLibrary.TOTAL, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(
        address account
    ) 
        public 
        view 
        override 
        returns (uint256) 
    {
        BankExtension bank = 
            BankExtension(
                dao.getExtensionAddress(DaoLibrary.BANK_EXT)
            );
        return bank.balanceOf(account, tokenAddress);//tokenAddress
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./events/IDaoRegistryEvents.sol";
import "./errors/IDaoRegistryErrors.sol";
import "../../extensions/interfaces/IExtension.sol";

/// @title Dao Registry interface
/// @notice This interface defines the functions that can be called on the DaoRegistry contract
interface IDaoRegistry is
    IDaoRegistryEvents,
    IDaoRegistryErrors
{
    /**
     * ENUMS
     */

    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER
    }


    /**
     * STRUCTS
     */
    
    /// @notice The structure to track all the proposals in the DAO
    struct Proposal {
        ///@notice the adapter address that called the functions to change the DAO state
        address adapterAddress; 
        ///@notice flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
        uint256 flags; 
    }

    ///@notice the structure to track all the members in the DAO
    struct Member {
        ///@notice flags to track the state of the member: exists, etc
        uint256 flags; 
    }

    ///@notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint96 fromBlock;
        uint160 amount;
    }

    ///@notice A checkpoint for marking the delegate key for a member from a given block
    struct DelegateCheckpoint {
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO"s creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    function initialize(
        address creator, 
        address payer
    ) 
        external;

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() 
        external;

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() 
        external;

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() 
        external;

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(
        bytes32 key, 
        uint256 value
    )
        external;

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(
        bytes32 key, 
        address value
    )
        external;

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) 
        external;

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    function addExtension(
        bytes32 extensionId, 
        IExtension extension
    )
        external;

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(
        bytes32 extensionId
    )
        external;

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    )   
        external;

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(
        bytes32 proposalId
    )
        external;

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) 
        external;

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(
        bytes32 proposalId
    ) 
        external;

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(
        address memberAddress
    )
        external;

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(
        address memberAddress
    )
        external;

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(
        address memberAddr, 
        address newDelegateKey
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/DaoRegistry.sol";
import "./errors/IExtensionErrors.sol";

/// @title Extension Interface
/// @notice This interface defines the functions for the Extension
interface IExtension is
    IExtensionErrors
{
    /**
     * EXTERNAL FUNCTIONS
     */
    
    function initialize(
        DaoRegistry dao, 
        address creator
    ) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../libraries/DaoLibrary.sol";

/// @title Member Guard
/// @notice This contract contains the modifiers used by the adapters
abstract contract MemberGuard {
    /**
     * ERRORS
     */

    error MemberGuard_NotMember(address memberAddress);


    /**
     * MODIFIER
     */

    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(
        DaoRegistry dao
    ) 
    {
        _onlyMember(
            dao, 
            msg.sender
        );

        _;
    }

    modifier onlyMember2(
        DaoRegistry dao, 
        address _addr
    ) 
    {
        _onlyMember(
            dao, 
            _addr
        );
        
        _;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function isActiveMember(
        DaoRegistry dao, 
        address _addr
    )
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(DaoLibrary.BANK_EXT);
        if (bankAddress != address(0x0)) {
            address memberAddr = DaoLibrary.msgSender(dao, _addr);
            return
                dao.isMember(_addr) &&
                BankExtension(bankAddress).balanceOf(
                    memberAddr,
                    DaoLibrary.UNITS
                ) >
                0;
        }

        return dao.isMember(_addr);
    }

    function _onlyMember(
        DaoRegistry dao, 
        address _addr
    ) 
        internal 
        view 
    {
        if(!isActiveMember(dao, _addr))
            revert MemberGuard_NotMember(_addr); 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Events
/// @notice This interface defines the events for DaoRegistry
interface IDaoRegistryEvents {
    /**
      * EVENTS
      */

    event SubmittedProposal(
        bytes32 proposalId, 
        uint256 flags
    );
    
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    
    event ProcessedProposal(
        bytes32 proposalId, 
        uint256 flags
    );
    
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    
    event AdapterRemoved(
        bytes32 adapterId
    );
    
    event ExtensionAdded(
        bytes32 extensionId, 
        address extensionAddress
    );
    
    event ExtensionRemoved(
        bytes32 extensionId
    );
    
    event UpdateDelegateKey(
        address memberAddress, 
        address newDelegateKey
    );
    
    event ConfigurationUpdated(
        bytes32 key, 
        uint256 value
    );
    
    event AddressConfigurationUpdated(
        bytes32 key, 
        address value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Errors
/// @notice This interface defines the errors for DaoRegistry
interface IDaoRegistryErrors {
    /**
      * ERRORS
      */

    error DaoRegistry_AlreadyInitialized();

    error DaoRegistry_AccessDenied();

    error DaoRegistry_NotAllowedToFinalize();

    error DaoRegistry_EmptyExtensionId();

    error DaoRegistry_RegisteredExtensionId();

    error DaoRegistry_UnregisteredExtensionId();

    error DaoRegistry_DeletedExtension();

    error DaoRegistry_AdapterNotFound();

    error DaoRegistry_AdapterMismatch();

    error DaoRegistry_EmptyAdapterId();

    error DaoRegistry_RegisteredAdapterId();

    error DaoRegistry_UnregisteredAdapterId();

    error DaoRegistry_AlreadySetFlag();

    error DaoRegistry_InvalidProposalId();

    error DaoRegistry_NotExistingProposalId();

    error DaoRegistry_NotUniqueProposalId();

    error DaoRegistry_AlreadyProcessedProposalId();

    error DaoRegistry_InvalidMember();

    error DaoRegistry_NotExistingMember();

    error DaoRegistry_BlockNumberNotFinalized();

    error DaoRegistry_InvalidDelegateKey();

    error DaoRegistry_DelegateKeyAlreadyTaken();

    error DaoRegistry_DelegateKeyAddressAlreadyTaken();

    error DaoRegistry_MemberAddressAlreadyUsedAsDelegate();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Errors
/// @notice This interface defines the errors for the Extension
interface IExtensionErrors {
    /**
     * ERRORS
     */
    
    error Extension_ReservedAddress();
    
    error Extension_NotAMember(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IBankExtensionErrors.sol";
import "./events/IBankExtensionEvents.sol";
import "../../core/DaoRegistry.sol";

/// @title Bank Extension Interface
/// @notice This interface defines the functions for the Bank Extension
interface IBankExtension is 
    IBankExtensionErrors,
    IBankExtensionEvents 
{
    /**
     * ENUMS
     */

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }


    /**
     * STRUCTS
     */

    struct TokenConfig {
        string tokenName;
        string tokenSymbol;
        uint8 maxExternalTokens;
        uint8 decimals;
    }

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    function withdraw(
        DaoRegistry dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) 
        external;

    function withdrawTo(
        DaoRegistry dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) 
        external;

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(
        uint8 maxTokens
    ) 
        external;

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(
        DaoRegistry dao, 
        address token
    )
        external;

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(
        DaoRegistry dao, 
        address token
    )
        external;

    function updateToken(
        DaoRegistry dao, 
        address tokenAddr
    )
        external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Errors
/// @notice This interface defines the errors for Bank Extension
interface IBankExtensionErrors {
    /**
     * ERRORS
     */
    
    error Bank_AccessDenied();

    error Bank_AlreadyInitialized();
    
    error Bank_NotEnoughFunds();

    error Bank_TooManyExternalTokens();

    error Bank_TooManyInternalTokens();

    error Bank_ExternalTokenAmountLimitExceeded();

    error Bank_InternalTokenAmountLimitExceeded();

    error Bank_UnregisteredToken();

    error Bank_BlockNumberNotFinalized();

    error Bank_NoTransferFromJailedMember(address member);

    error Bank_NoTransferToJailedMember(address member);

    error Bank_NotImplemented();

    error Bank_MaxExternalTokensOutOfRange();

    error Bank_TokenAlreadyInternal(address token);

    error Bank_TokenAlreadyExternal(address token);

    error Bank_TokenNotRegistered(address token);

    error Bank_NotAMember(address member);
    
    error Bank_DaoLocked();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Events
/// @notice This interface defines the events for Bank Extension
interface IBankExtensionEvents {
    /**
     * EVENTS
     */

    event NewBalance(
        address member,
        address tokenAddr,
        uint160 amount
    );

    event Withdraw(
        address account, 
        address tokenAddr, 
        uint160 amount
    );

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../libraries/VotingAdapterLibrary.sol";

/// @title Events emitted by the VotingAdapter
/// @notice Contains all events emitted by the VotingAdapter
interface IVotingAdapterEvents{
    /**
     * EVENTS
     */
    
    event SubmitGenericProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes _data, 
        bytes32 _proposalId
    );

    event ProcessGenericProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _proposalId
    );

    event StartNewVotingForProposalEvent(
        address _address, 
        bytes32 _proposalId, 
        VotingAdapterLibrary.Voting _voting
    );

    event SubmitVoteEvent(
        address _daoAddress,
        bytes32 _proposalId,
        address _memberAddress,
        uint256 nbYes,
        uint256 nbNo,
        uint256 nbMembers,
        uint256 nbTokens
    );

    event CancelVotingEvent(
        address _address,
        bytes32 _proposalId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Voting Adapter Errors
/// @notice This interface contains all the errors emitted by the VotingAdapter
interface IVotingAdapterErrors{
    /**
     * ERRORS
     */

    error VotingAdapter_InvalidConfiguration();

    error VotingAdapter_ProposalAlreadyProcessed();

    error VotingAdapter_ProposalNotSponsored();

    error VotingAdapter_InvalidVote();
    
    error VotingAdapter_InvalidProposalId();

    error VotingAdapter_VotingPeriodOver();

    error VotingAdapter_VotingNotStarted();

    error VotingAdapter_MemberAlreadyVoted();
    
    error VotingAdapter_MemberHasNoVotingPower();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC20 Errors
/// @notice This interface defines the errors for ERC20
interface IERC20Errors {
    /**
     * ERRORS
     */

    error ERC20_AlreadyInitialized();

    error ERC20_InvalidTokenAddress();

    error ERC20_MissingTokenName();

    error ERC20_MissingTokenSymbol();

    error ERC20_ReservedTokenAddress();

    error ERC20_InvalidSender();

    error ERC20_InvalidSpender();

    error ERC20_SenderNotMember();

    error ERC20_SpenderReservedAddress();

    error ERC20_InvalidRecipient();

    error ERC20_TransferNotAllowed();
    
    error ERC20_InsufficientAllowance();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/DaoRegistry.sol";
import "./IVotingAdapter.sol";

/// @title ERC20 Adapter Interface
/// @notice This interface defines the functions that an ERC20 adapter must implement
interface IERC20Adapter {
    /**
     * ENUMS
     */

    enum AclFlag {
        REGISTER_TRANSFER
    }

    enum ApprovalType {
        NONE,
        STANDARD,
        SPECIAL
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function evaluateTransfer(
        DaoRegistry dao,
        address tokenAddr,
        address from,
        address to,
        uint256 amount,
        address caller
    ) 
        external 
        view 
        returns (
            ApprovalType, 
            uint256
         );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/ICommunityEquityExtensionErrors.sol";
import "../../core/DaoRegistry.sol";

/// @title Community Equity Extension Interface
/// @notice This interface defines the functions for the Community Equity Extension
interface ICommunityEquityExtension is 
    ICommunityEquityExtensionErrors    
{
    /**
     * ENUMS
     */

    enum AclFlag {
        SET_COMMUNITY_EQUITY,
        REMOVE_COMMUNITY_EQUITY,
        ACT_COMMUNITY_EQUITY
    }

    enum AllocationType {
        POOL,
        EPOCH
    }


    /**
     * STRUCTS
     */
    
    struct CommunityEquityConfig {
        AllocationType allocationType;
        uint256 allocationTokenAmount;
        uint256 tokenAmount;
    }

    struct CommunityEquityMemberConfig {
        address memberAddress;
        uint256 singlePaymentAmountThreshold;
        uint256 totalPaymentAmountThreshold;
        uint256 totalPaymentAmount;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    function setCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityConfig calldata _communityEquityConfig 
    ) 
        external;

    function setCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityConfig calldata _communityEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external;

    function setCommunityEquityEpoch(
        DaoRegistry dao,
        bytes32 communityEquityId,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external;
    
    function setCommunityEquityMember(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external;

    function setCommunityEquityMemberBatch(
        DaoRegistry dao,
        bytes32 communityEquityId,
        CommunityEquityMemberConfig[] calldata _communityEquityMemberConfig
    ) 
        external;

    function removeCommunityEquity(
        DaoRegistry dao,
        bytes32 communityEquityId
    ) 
        external;

    function removeCommunityEquityMember(
        DaoRegistry dao,
        bytes32 communityEquityId,
        address _memberAddress
    ) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Community Equity Extension Errors
/// @notice This interface defines the errors for Community Equity Extension
interface ICommunityEquityExtensionErrors {
    /**
     * ERRORS
     */

    error CommunityEquity_AccessDenied();

    error CommunityEquity_AlreadyInitialized();

    error CommunityEquity_Undefinied();

    error CommunityEquity_MemberUndefinied();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IMemberExtensionErrors.sol";
import "./IDynamicEquityExtension.sol";
import "./IVestedEquityExtension.sol";
import "./ICommunityEquityExtension.sol";
import "./IBankExtension.sol";

/// @title Member Extension Interface
/// @notice This interface defines the functions for the Member Extension
interface IMemberExtension is 
    IMemberExtensionErrors    
{
    /**
     * ENUMS
     */

    enum AclFlag {
        SET_MEMBER,
        REMOVE_MEMBER,
        ACT_MEMBER
    }


    /**
     * STRUCTS
     */

    struct MemberSetupConfig {
        MemberConfig memberConfig;
        IDynamicEquityExtension.DynamicEquityMemberConfig dynamicEquityMemberConfig;
        IVestedEquityExtension.VestedEquityMemberConfig vestedEquityMemberConfig;
        ICommunityEquityExtension.CommunityEquityMemberConfig communityEquityMemberConfig;
    }

    struct MemberConfig {
        address memberAddress;
        uint256 initialAmount;
        uint256 initialPeriod;
        bool appreciationRight;
    }


    /**
     * EXTERNAL FUNCTIONS
     */
    
    function setMember(
        DaoRegistry dao,
        MemberConfig calldata _memberConfig
    ) 
        external;

    function setMemberSetup(
        DaoRegistry dao,
        IDynamicEquityExtension.DynamicEquityMemberConfig calldata _dynamicEquityMemberConfig,
        IVestedEquityExtension.VestedEquityMemberConfig calldata _vestedEquityMemberConfig,
        ICommunityEquityExtension.CommunityEquityMemberConfig calldata _communityEquityMemberConfig
    ) 
        external;

    function setMemberAppreciationRight(
        DaoRegistry dao,
        address _memberAddress,
        bool appreciationRight
    ) 
        external;

    function setMemberEnvironment(
        DaoRegistry dao,
        IDynamicEquityExtension.DynamicEquityConfig memory _dynamicEquityConfig,
        IVestedEquityExtension.VestedEquityConfig memory _vestedEquityConfig,
        ICommunityEquityExtension.CommunityEquityConfig memory _communityEquityConfig,
        DaoLibrary.EpochConfig memory _epochConfig
    ) 
        external;

    function removeMember(
        DaoRegistry dao,
        address _memberAddress
    ) 
        external;

    function removeMemberSetup(
        DaoRegistry dao,
        address _memberAddress
    ) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/DaoLibrary.sol";
import "../core/DaoRegistry.sol";
import "./interfaces/IExtension.sol";
import "./interfaces/IDynamicEquityExtension.sol";


/// @title DynamicEquity Extension
/// @notice This contract is used to manage dynamic equity
contract DynamicEquityExtension is 
    IExtension,
    IDynamicEquityExtension
{
    /**
     * PUBLIC VARIABLES
     */

    /// @notice 
    DaoLibrary.EpochConfig public epochConfig;

    /// @notice 
    DynamicEquityConfig public dynamicEquityConfig;

    /// @notice 
    mapping(uint256 => mapping(address => DynamicEquityMemberConfig)) public dynamicEquityMemberEpochConfigs;

    /// @notice 
    DynamicEquityMemberConfig[] public dynamicEquityMemberConfig;

    /// @notice 
    mapping(address => uint256) public dynamicEquityMemberIndex;

    /// @notice 
    bool public initialized;


    /**
     * PRIVATE VARIABLES
     */

    /// @notice 
    DaoRegistry private _dao;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /// @inheritdoc IExtension
    function initialize(
        DaoRegistry dao, 
        address
    ) 
        external 
        override 
    {
        if(initialized)
            revert DynamicEquity_AlreadyInitialized();

        _dao = dao;

        initialized = true;
    }


    /**
     * MODIFIER
     */

    /// @notice 
    modifier hasExtensionAccess(
        DaoRegistry dao, 
        AclFlag flag
    ) 
    {
        if(
            _dao != dao ||
            (
                address(this) != msg.sender &&
                address(_dao) != msg.sender &&
                initialized &&
                !DaoLibrary.isInCreationModeAndHasAccess(_dao) &&
                !_dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert DynamicEquity_AccessDenied();
        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquity(
        DaoRegistry dao,
        DynamicEquityConfig calldata _dynamicEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        dynamicEquityConfig = _dynamicEquityConfig;
        epochConfig = _epochConfig;
        epochConfig.epochLast = epochConfig.epochStart;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityEpoch(
        DaoRegistry dao,
        uint256 newEpochLast
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        if(
            epochConfig.epochLast >= block.timestamp ||
            epochConfig.epochLast >= newEpochLast
        )
            revert DynamicEquity_InvalidEpoch();

        epochConfig.epochLast = newEpochLast;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMember(
        DaoRegistry dao,
        DynamicEquityMemberConfig memory _dynamicEquityMemberConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        if(!DaoLibrary.isNotReservedAddress(_dynamicEquityMemberConfig.memberAddress))
            revert Extension_ReservedAddress();

        uint length = dynamicEquityMemberConfig.length;

        _dynamicEquityMemberConfig.expense = 0;        
        
        if(dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]==0){
            dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]=length+1;
            dynamicEquityMemberConfig.push(_dynamicEquityMemberConfig);
        }
        else{
            dynamicEquityMemberConfig[dynamicEquityMemberIndex[_dynamicEquityMemberConfig.memberAddress]-1] = _dynamicEquityMemberConfig;
        } 
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberBatch(
        DaoRegistry dao,
        DynamicEquityMemberConfig[] memory _dynamicEquityMemberConfig
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        uint length = dynamicEquityMemberConfig.length;
        for(uint256 i=0; i < _dynamicEquityMemberConfig.length; i++){
            if(DaoLibrary.isNotReservedAddress(_dynamicEquityMemberConfig[i].memberAddress)){
                _dynamicEquityMemberConfig[i].expense = 0;
                if(dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]==0){
                    dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]=length+1;
                    dynamicEquityMemberConfig.push(_dynamicEquityMemberConfig[i]);
                }else{
                    dynamicEquityMemberConfig[dynamicEquityMemberIndex[_dynamicEquityMemberConfig[i].memberAddress]-1] = _dynamicEquityMemberConfig[i];
                } 
            }
        }
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberSuspend(
        DaoRegistry dao,
        address _member,
        uint256 suspendedUntil
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        if(dynamicEquityMemberIndex[_member]==0)
            revert DynamicEquity_UndefinedMember();

        dynamicEquityMemberConfig[dynamicEquityMemberIndex[_member]-1].suspendedUntil = suspendedUntil;
    }

    /// @inheritdoc IDynamicEquityExtension
    function setDynamicEquityMemberEpoch(
        DaoRegistry dao,
        DynamicEquityMemberConfig calldata config
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.SET_DYNAMIC_EQUITY) 
    {
        DynamicEquityMemberConfig memory _dynamicEquityMemberConfig = dynamicEquityMemberConfig[dynamicEquityMemberIndex[config.memberAddress]-1];
        if(dynamicEquityMemberIndex[config.memberAddress] == 0)
            revert DynamicEquity_UndefinedMember();
        
        if(!DaoLibrary.isNotReservedAddress(config.memberAddress))
            revert DynamicEquity_ReservedAddress();

        if(config.availability > _dynamicEquityMemberConfig.availabilityThreshold)
            revert DynamicEquity_AvailabilityOutOfBound();

        if(config.expense > _dynamicEquityMemberConfig.expenseThreshold)
            revert DynamicEquity_ExpenseOutOfBound();

        uint256 expenseCommittedThreshold = _dynamicEquityMemberConfig.expenseCommitted * _dynamicEquityMemberConfig.expenseCommittedThreshold / 100;
       
        if(
            config.expenseCommitted > _dynamicEquityMemberConfig.expenseCommitted + expenseCommittedThreshold ||
            config.expenseCommitted < _dynamicEquityMemberConfig.expenseCommitted - expenseCommittedThreshold
        )
            revert DynamicEquity_ExpenseCommittedOutOfBound();
            
        uint256 withdrawalThreshold = _dynamicEquityMemberConfig.withdrawal * _dynamicEquityMemberConfig.withdrawalThreshold / 100;
       
        if(
            config.withdrawal > _dynamicEquityMemberConfig.withdrawal + withdrawalThreshold ||
            config.withdrawal < _dynamicEquityMemberConfig.withdrawal - withdrawalThreshold
        )
            revert DynamicEquity_WithdrawalOutOfBound();

        dynamicEquityMemberEpochConfigs[epochConfig.epochLast+epochConfig.epochDuration][config.memberAddress] = config;
    }

    /// @inheritdoc IDynamicEquityExtension
    function removeDynamicEquityMemberEpoch(
        DaoRegistry dao,
        address _member
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) 
    {
        if(dynamicEquityMemberIndex[_member]==0)
            revert DynamicEquity_UndefinedMember();

        DynamicEquityMemberConfig storage _config = dynamicEquityMemberEpochConfigs[epochConfig.epochLast+epochConfig.epochDuration][_member];
        _config.memberAddress = address(0);
    }

    /// @inheritdoc IDynamicEquityExtension
    function removeDynamicEquityMember(
        DaoRegistry dao,
        address _member
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_DYNAMIC_EQUITY) 
    {
        dynamicEquityMemberIndex[_member]=0;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function getDynamicEquityMemberEpochAmount(
        address _memberAddress
    ) 
        external 
        view 
        returns (uint) 
    {
        DynamicEquityMemberConfig memory _epochMemberConfig = dynamicEquityMemberEpochConfigs[epochConfig.epochLast][_memberAddress];
        if(_epochMemberConfig.memberAddress != address(0)){
            return _getDynamicEquityMemberEpochAmountInternal(_epochMemberConfig);
        }
        else{
            return _getDynamicEquityMemberEpochAmountInternal(dynamicEquityMemberConfig[dynamicEquityMemberIndex[_memberAddress]-1]);
        }
    }

    function getDynamicEquityMemberEpoch(
        address _member
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig memory) 
    {
        return dynamicEquityMemberEpochConfigs[epochConfig.epochLast][_member];
    }

    function getDynamicEquityMemberEpoch(
        address _member,
        uint256 timestamp
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig memory) 
    {
        return dynamicEquityMemberEpochConfigs[timestamp][_member];
    }

    function getIsNotReviewPeriod(
    ) 
        external 
        view 
        returns (bool) 
    {
        uint256 nextEpoch = getNextEpoch();
        return (block.timestamp<nextEpoch+epochConfig.epochDuration-epochConfig.epochReview);
    }

    function getVotingPeriod(
    ) 
        external 
        view 
        returns (uint256) 
    {
        uint256 nextEpoch = getNextEpoch();
        return nextEpoch + epochConfig.epochDuration - block.timestamp;
    }

    function getDynamicEquityConfig(
    ) 
        external 
        view 
        returns (DynamicEquityConfig memory) 
    {
        return dynamicEquityConfig;
    }

    function getDynamicEquityMemberConfig(
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig[] memory) 
    {
        return dynamicEquityMemberConfig;
    }

    function getDynamicEquityMemberConfig(
        address _memberAddress
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig memory) 
    {
        if(dynamicEquityMemberIndex[_memberAddress]>0){
            return dynamicEquityMemberConfig[dynamicEquityMemberIndex[_memberAddress]-1];
        }
        revert DynamicEquity_UndefinedMember();
    }

    function getIsDynamicEquityMember(
        address _memberAddress
    ) 
        external 
        view 
        returns (bool) 
    {
        return dynamicEquityMemberIndex[_memberAddress]>0;
    }

    function getDynamicEquityMemberSuspendedUntil(
        address _memberAddress
    ) 
        external 
        view 
        returns (uint256 suspendedUntil) 
    {
        if(dynamicEquityMemberIndex[_memberAddress]>0){
            return dynamicEquityMemberConfig[dynamicEquityMemberIndex[_memberAddress]-1].suspendedUntil;
        }
        revert DynamicEquity_UndefinedMember();
    }

    function getMemberConfig(      
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig[] memory) 
    {
        uint256 memberCount  = getMemberCount();
        DynamicEquityMemberConfig[] memory temp = new DynamicEquityMemberConfig[](memberCount);
        uint256 counter= 0;
        for(uint256 i=0;i<dynamicEquityMemberConfig.length;i++){
            if(dynamicEquityMemberIndex[dynamicEquityMemberConfig[i].memberAddress]>0){
                temp[counter] = dynamicEquityMemberConfig[i];
                counter++;
            }
        }
        return temp;
    }

    function getMemberConfigUnique(      
    ) 
        external 
        view 
        returns (DynamicEquityMemberConfig[] memory) 
    {
        uint256 memberCount  = getMemberCountUnique();
        uint256[] memory indexes = new uint256[](memberCount);
        DynamicEquityMemberConfig[] memory temp = new DynamicEquityMemberConfig[](memberCount);
        uint256 counter= 0;
        uint256 index = 0; 
        for(uint256 i=0;i<dynamicEquityMemberConfig.length;i++){
            index = dynamicEquityMemberIndex[dynamicEquityMemberConfig[i].memberAddress];
            if(index>0 && !existInList(indexes, index)){
                temp[counter] = dynamicEquityMemberConfig[index-1];
                indexes[counter] = index;
                counter++;
            }
        }
        return temp;
    }

    function getMemberCountUnique(      
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 counter= 0;
        uint256[] memory indexes = new uint256[](dynamicEquityMemberConfig.length); 
        uint256 index = 0;    
        for(uint256 i=0;i<dynamicEquityMemberConfig.length;i++){
            index = dynamicEquityMemberIndex[dynamicEquityMemberConfig[i].memberAddress];
            if(index>0 && !existInList(indexes, index)){
                indexes[counter] = index;
                counter++;
            }
        }
        return counter;
    }
    
    function getEpochConfig(
    ) 
        public 
        view 
        returns (DaoLibrary.EpochConfig memory) 
    {
        return epochConfig;
    }

    function getMemberCount(      
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 counter= 0;        
        for(uint256 i=0;i<dynamicEquityMemberConfig.length;i++){
            if(dynamicEquityMemberIndex[dynamicEquityMemberConfig[i].memberAddress]>0){
                counter++;
            }
        }
        return counter;
    }

    function getNextEpoch(
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 nextEpoch = epochConfig.epochLast+epochConfig.epochDuration;
        while(nextEpoch < block.timestamp){
            nextEpoch +=epochConfig.epochDuration;
        }
        return nextEpoch;
    }

    function _getDynamicEquityMemberEpochAmountInternal(
        DynamicEquityMemberConfig memory dynamicEquityMemberEpochConfig
    ) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 timeEquity = 0;
        uint256 precisionFactor = 10**DaoLibrary.FOUNDANCE_PRECISION;
        uint256 salaryEpoch = (dynamicEquityMemberEpochConfig.salary * dynamicEquityMemberEpochConfig.availability);
        if(salaryEpoch > dynamicEquityMemberEpochConfig.withdrawal){
            timeEquity = ((salaryEpoch - dynamicEquityMemberEpochConfig.withdrawal) * dynamicEquityConfig.timeMultiplier / precisionFactor);
        }
        uint256 riskEquity = ((dynamicEquityMemberEpochConfig.expense + dynamicEquityMemberEpochConfig.expenseCommitted) * dynamicEquityConfig.riskMultiplier / precisionFactor);
        return timeEquity + riskEquity;
    }

    function existInList(
        uint256[] memory list, 
        uint256 value     
    ) 
        internal 
        pure 
        returns (bool) 
    {          
        for(uint256 i=0;i<list.length;i++){
            if(list[i]==value){
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/DaoRegistry.sol";
import "./interfaces/IExtension.sol";
import "./interfaces/IVestedEquityExtension.sol";
import "../libraries/DaoLibrary.sol";

/// @title VestedEquity Extension
/// @notice This contract is used to manage vested equity
contract VestedEquityExtension is 
    IExtension, 
    IVestedEquityExtension 
{
    /**
     * PUBLIC VARIABLES
     */

    ///@notice 
    bool public initialized;

    ///@notice
    VestedEquityConfig public vestedEquityConfig;

    ///@notice
    VestedEquityMemberConfig[] public vestedEquityMemberConfig;

    ///@notice
    mapping(address => uint) public vestedEquityMemberIndex;


    /**
     * PRIVATE VARIABLES
     */

    ///@notice
    DaoRegistry private _dao;


    /**
     * INITIALIZE
     */

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /// @inheritdoc IExtension
    function initialize(
        DaoRegistry dao, 
        address 
    ) 
        external 
        override 
    {
        if(initialized)
            revert VestedEquity_AlreadyInitialized();

        _dao = dao;

        initialized = true;
    }

    /**
     * MODIFIER
     */

    ///@notice
    modifier hasExtensionAccess(
        DaoRegistry dao, 
        AclFlag flag
    ) 
    {
        if(
            _dao != dao ||
            (
                address(this) != msg.sender &&
                address(_dao) != msg.sender &&
                initialized &&
                !DaoLibrary.isInCreationModeAndHasAccess(_dao) &&
                !_dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                )
            )
        )
            revert VestedEquity_AccessDenied();
        _;
    }


    /**
     * EXTERNAL FUNCTIONS
     */

    /// @inheritdoc IVestedEquityExtension
    function setVestedEquity(
        DaoRegistry dao,
        VestedEquityConfig calldata _vestedEquityConfig
    ) 
        external 
        override
        hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) {
        vestedEquityConfig = _vestedEquityConfig;
    }

    /// @inheritdoc IVestedEquityExtension
    function setVestedEquityMember(
        DaoRegistry dao,
        VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) 
        external 
        override
        hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) 
    {
        if(!DaoLibrary.isNotReservedAddress(_vestedEquityMemberConfig.memberAddress))
            revert VestedEquity_ReservedAddress();

        uint length = vestedEquityMemberConfig.length;
        if(vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]==0){
            vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]=length+1;
            vestedEquityMemberConfig.push(_vestedEquityMemberConfig);
        }
        else{
            vestedEquityMemberConfig[vestedEquityMemberIndex[_vestedEquityMemberConfig.memberAddress]-1] = _vestedEquityMemberConfig;
        } 
    }

    /// @inheritdoc IVestedEquityExtension
    function setVestedEquityMemberBatch(
        DaoRegistry dao,
        VestedEquityMemberConfig[] calldata _vestedEquityMemberConfig
    ) 
        external 
        override
        hasExtensionAccess(dao, AclFlag.SET_VESTED_EQUITY) 
    {
        for(uint256 i=0;i<_vestedEquityMemberConfig.length;i++){
            if(DaoLibrary.isNotReservedAddress(_vestedEquityMemberConfig[i].memberAddress)){
                uint length = vestedEquityMemberConfig.length;
                if(vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]==0){
                    vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]=length+1;
                    vestedEquityMemberConfig.push(_vestedEquityMemberConfig[i]);
                }
                else{
                    vestedEquityMemberConfig[vestedEquityMemberIndex[_vestedEquityMemberConfig[i].memberAddress]-1] = _vestedEquityMemberConfig[i];
                } 
            }
        }
    }

    /// @inheritdoc IVestedEquityExtension
    function removeVestedEquityMember(
        DaoRegistry dao,
        address _member
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) 
    {
        vestedEquityMemberIndex[_member]=0;
    }

    /// @inheritdoc IVestedEquityExtension
    function removeVestedEquityMemberAmount(
        DaoRegistry dao,
        address _member
    ) 
        external
        override
        hasExtensionAccess(dao, AclFlag.REMOVE_VESTED_EQUITY) 
    {
        uint256 blockTimestamp = block.timestamp;
        VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];

        if(blockTimestamp <= _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff)
            revert VestedEquity_CliffNotExceeded();

        if(blockTimestamp <= _vestedEquityMemberConfig.start + vestedEquityConfig.vestingCadenceInS)
            revert VestedEquity_CadenceNotExceeded();

        _vestedEquityMemberConfig.tokenAmount -= _getVestedEquityMemberDistributionAmountInternal(_member);
        uint256 prolongedDuration = blockTimestamp - _vestedEquityMemberConfig.start;
        if(prolongedDuration > _vestedEquityMemberConfig.duration){
            _vestedEquityMemberConfig.duration = 0;
        }
        else{
            _vestedEquityMemberConfig.duration -= prolongedDuration;
        }
        _vestedEquityMemberConfig.start = blockTimestamp;
        _vestedEquityMemberConfig.cliff = 0;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function getVestedEquityConfig(
    ) 
        external 
        view 
        returns (VestedEquityConfig memory) 
    {
        return vestedEquityConfig;
    }
    
    function getIsVestedEquityMember(
        address _memberAddress
    ) 
        external 
        view 
        returns (bool) 
    {
        return vestedEquityMemberIndex[_memberAddress]>0;
    }

    function getVestedEquityMemberConfig(
    ) 
        external 
        view 
        returns (VestedEquityMemberConfig[] memory)    
    {
        return vestedEquityMemberConfig;
    }

    function getVestedEquityMemberConfig(
        address _member
    ) 
        external 
        view 
        returns (VestedEquityMemberConfig memory) 
    {
        if(vestedEquityMemberIndex[_member]==0)
            revert VestedEquity_UndefinedMember();

        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
    }

    function getVestedEquityMemberAmount(
        address _member
    ) 
        external 
        view 
        returns (uint) 
    {
        if(vestedEquityMemberIndex[_member]==0)
            revert VestedEquity_UndefinedMember();

        return vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1].tokenAmount;
    }

    function getVestedEquityMemberDistributionAmount(
        address _member
    ) 
        external 
        view 
        returns (uint) 
    {
        return _getVestedEquityMemberDistributionAmountInternal(_member);
    }

    function _getVestedEquityMemberDistributionAmountInternal(
        address _member
    ) 
        internal 
        view 
        returns (uint) 
    {
        uint256 blockTimestamp = block.timestamp;
        VestedEquityMemberConfig storage _vestedEquityMemberConfig = vestedEquityMemberConfig[vestedEquityMemberIndex[_member]-1];
        uint256 amount = 0;
        if(blockTimestamp > _vestedEquityMemberConfig.start + _vestedEquityMemberConfig.cliff){
            if(_vestedEquityMemberConfig.start + _vestedEquityMemberConfig.duration > blockTimestamp){
                uint256 prolongedDuration = (blockTimestamp - _vestedEquityMemberConfig.start)/vestedEquityConfig.vestingCadenceInS;
                uint256 precisionFactor = 1000000;
                uint256 toBeDistributed = (prolongedDuration * precisionFactor / _vestedEquityMemberConfig.duration) * _vestedEquityMemberConfig.tokenAmount / precisionFactor;
                return toBeDistributed < _vestedEquityMemberConfig.tokenAmount ? toBeDistributed : _vestedEquityMemberConfig.tokenAmount;
            }
            else{
                return _vestedEquityMemberConfig.tokenAmount;
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Member Extension Errors
/// @notice This interface defines the errors for Member Extension
interface IMemberExtensionErrors {
    /**
     * ERRORS
     */

    error Member_AccessDenied();

    error Member_AlreadyInitialized();

    error Member_UndefinedMember();
    
    error Member_ReservedAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IDynamicEquityExtensionErrors.sol";
import "../../core/DaoRegistry.sol";

/// @title DynamicEquity Extension Interface
/// @notice This interface defines the functions for the DynamicEquity Extension
interface IDynamicEquityExtension is 
    IDynamicEquityExtensionErrors    
{
    /**
     * ENUMS
     */

    enum AclFlag {
        SET_DYNAMIC_EQUITY,
        REMOVE_DYNAMIC_EQUITY,
        ACT_DYNAMIC_EQUITY
    }


    /**
     * STRUCTS
     */

   struct DynamicEquityMemberConfig {
        address memberAddress;
        uint256 suspendedUntil;
        uint256 availability;
        uint256 availabilityThreshold;
        uint256 salary;
        uint256 salaryYear;
        uint256 withdrawal;
        uint256 withdrawalThreshold;
        uint256 expense;
        uint256 expenseThreshold;
        uint256 expenseCommitted;
        uint256 expenseCommittedThreshold;
    }

    struct DynamicEquityConfig {
        uint256 riskMultiplier;
        uint256 timeMultiplier;
    }

    function setDynamicEquity(
        DaoRegistry dao,
        DynamicEquityConfig calldata _dynamicEquityConfig,
        DaoLibrary.EpochConfig calldata _epochConfig
    ) 
        external;

    function setDynamicEquityEpoch(
        DaoRegistry dao,
        uint256 newEpochLast
    ) 
        external;

    function setDynamicEquityMember(
        DaoRegistry dao,
        DynamicEquityMemberConfig memory _dynamicEquityMemberConfig
    ) 
        external;

    function setDynamicEquityMemberBatch(
        DaoRegistry dao,
        DynamicEquityMemberConfig[] memory _dynamicEquityMemberConfig
    ) 
        external;

    function setDynamicEquityMemberSuspend(
        DaoRegistry dao,
        address _member,
        uint256 suspendedUntil
    ) 
        external;

    function setDynamicEquityMemberEpoch(
        DaoRegistry dao,
        DynamicEquityMemberConfig calldata config
    ) 
        external; 

    function removeDynamicEquityMemberEpoch(
        DaoRegistry dao,
        address _member
    ) 
        external;

    function removeDynamicEquityMember(
        DaoRegistry dao,
        address _member
    ) 
        external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IVestedEquityExtensionErrors.sol";
import "../../core/DaoRegistry.sol";

/// @title Vested Equity Extension Interface
/// @notice This interface defines the functions for the Vested Equity Extension
interface IVestedEquityExtension is 
    IVestedEquityExtensionErrors    
{
    /**
     * ENUMS
     */

    enum AclFlag {
        SET_VESTED_EQUITY,
        REMOVE_VESTED_EQUITY,
        ACT_VESTED_EQUITY
    }


    /**
     * STRUCTS
     */

    struct VestedEquityMemberConfig {
        address memberAddress;
        uint256 tokenAmount;
        uint256 duration;
        uint256 start;
        uint256 cliff;
    }

    struct VestedEquityConfig {
        uint256 vestingCadenceInS;
    }

    
    /**
     * EXTERNAL FUNCTIONS
     */

    function setVestedEquity(
        DaoRegistry dao,
        VestedEquityConfig calldata _vestedEquityConfig
    ) 
        external;

    function setVestedEquityMember(
        DaoRegistry dao,
        VestedEquityMemberConfig calldata _vestedEquityMemberConfig
    ) 
        external;

    function setVestedEquityMemberBatch(
        DaoRegistry dao,
        VestedEquityMemberConfig[] calldata _vestedEquityMemberConfig
    )
        external;

    function removeVestedEquityMember(
        DaoRegistry dao,
        address _member
    ) 
        external;

    function removeVestedEquityMemberAmount(
        DaoRegistry dao,
        address _member
    ) 
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Extension Errors
/// @notice This interface defines the errors for Dynamic Equity Extension
interface IDynamicEquityExtensionErrors {
    /**
     * ERRORS
     */

    error DynamicEquity_AccessDenied();

    error DynamicEquity_AlreadyInitialized();

    error DynamicEquity_InvalidEpoch();

    error DynamicEquity_InvalidCommunityEquity();

    error DynamicEquity_UndefinedMember();

    error DynamicEquity_ReservedAddress();

    error DynamicEquity_AvailabilityOutOfBound();

    error DynamicEquity_ExpenseOutOfBound();

    error DynamicEquity_ExpenseCommittedOutOfBound();

    error DynamicEquity_WithdrawalOutOfBound();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Vested Equity Extension Errors
/// @notice This interface defines the errors for the Extension
interface IVestedEquityExtensionErrors {
    /**
     * ERRORS
     */

    error VestedEquity_AccessDenied();

    error VestedEquity_AlreadyInitialized();

    error VestedEquity_UndefinedMember();
    
    error VestedEquity_CliffNotExceeded();

    error VestedEquity_CadenceNotExceeded();
    
    error VestedEquity_ReservedAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../extensions/CommunityEquityExtension.sol";

/// @title Events emitted by the CommunityEquityAdapter
/// @notice Contains all events emitted by the CommunityEquityAdapter
interface ICommunityEquityAdapterEvents{
    /**
     * EVENTS
     */
    
    /**
     * @dev Event emitted when a proposal to set the community equity is submitted
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _data extra data associated with the proposal
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _communityEquityConfig new configuration for the community equity
     * @param _epochConfig new configuration for the epoch
     */
    event SubmitSetCommunityEquityProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes _data, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        CommunityEquityExtension.CommunityEquityConfig _communityEquityConfig, 
        DaoLibrary.EpochConfig _epochConfig
    );

    /**
     * @dev Event emitted when a proposal to set the community equity member is submitted
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _data extra data associated with the proposal
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _communityEquityMemberConfig new configuration for the community equity member
     */
    event SubmitSetCommunityEquityMemberProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes _data, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        CommunityEquityExtension.CommunityEquityMemberConfig _communityEquityMemberConfig
    );

    /**
     * @dev Event emitted when a proposal to remove the community equity is submitted
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _data extra data associated with the proposal
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     */
    event SubmitRemoveCommunityEquityProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes _data, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId
    );

    /**
     * @dev Event emitted when a proposal to remove the community equity member is submitted
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _data extra data associated with the proposal
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _memberAddress address of the member to remove
     */
    event SubmitRemoveCommunityEquityMemberProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes _data, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        address _memberAddress
    );

    /**
     * @dev Event emitted when a proposal to set the community equity is processed
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _communityEquityConfig new configuration for the community equity
     * @param _epochConfig new configuration for the epoch
     */
    event ProcessSetCommunityEquityProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        CommunityEquityExtension.CommunityEquityConfig _communityEquityConfig, 
        DaoLibrary.EpochConfig _epochConfig
    );
    
    /**
     * @dev Event emitted when a proposal to set the community equity member is processed
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _communityEquityMemberConfig new configuration for the community equity member
     */
    event ProcessSetCommunityEquityMemberProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        CommunityEquityExtension.CommunityEquityMemberConfig _communityEquityMemberConfig
    );

    /**
     * @dev Event emitted when a proposal to remove the community equity is processed
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     */
    event ProcessRemoveCommunityEquityProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId 
    );

    /**
     * @dev Event emitted when a proposal to remove the community equity member is processed
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _proposalId unique identifier of the proposal
     * @param _communityEquityId unique identifier of the community equity
     * @param _memberAddress address of the member to remove
     */
    event ProcessRemoveCommunityEquityMemberProposalEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _proposalId, 
        bytes32 _communityEquityId, 
        address _memberAddress
    );
    
    /**
     * @dev Event emitted when a community equity member is distributed
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _communityEquityId unique identifier of the community equity
     * @param _recipient address of the recipient
     * @param amountToBeSent the amount of tokens to be sent to the recipient
     */
    event ActCommunityEquityMemberDistributeEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _communityEquityId, 
        address _recipient, 
        uint256 amountToBeSent
    );

    /**
     * @dev Event emitted when a community equity epoch is updated
     * @param _daoAddress address of the DAO contract
     * @param _senderAddress address of the sender
     * @param _communityEquityId unique identifier of the community equity
     */
    event ActCommunityEquityEpochUpdateEvent(
        address _daoAddress, 
        address _senderAddress, 
        bytes32 _communityEquityId
    );
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Community Equity Adapter Errors
/// @notice This interface contains all the errors emitted by the CommunityEquityAdapter
interface ICommunityEquityAdapterErrors{
    /**
     * ERRORS
     */

    error CommunityEquityAdapter_ProposalAlreadyProcessed();
    
    error CommunityEquityAdapter_InvalidCommunityEquityId();

    error CommunityEquityAdapter_InvalidCommunityEquityAllocationType();

    error CommunityEquityAdapter_OngoingDistribution();

    error CommunityEquityAdapter_NotCommunityEquityMember();

    error CommunityEquityAdapter_AmountExceedsSinglePaymentAmountThreshold();

    error CommunityEquityAdapter_AmountExceedsTotalPaymentAmountThreshold();

    error CommunityEquityAdapter_InsufficientGuildBalance();

    error CommunityEquityAdapter_InsufficientCommunityEquityBalance();
    
    error CommunityEquityAdapter_InvalidProposalId();
}