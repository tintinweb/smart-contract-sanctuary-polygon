// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@axelar/contracts/executable/AxelarExecutable.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/TokenStructs.sol";
import "./lib/AxelarStructs.sol";

contract MobulaTokensProtocol is AxelarExecutable, Ownable2Step {

    /* Modifiers */
    /**
     * @dev Modifier to limit function calls to Rank I or higher
     */
    modifier onlyRanked() {
        if (rank[msg.sender] == 0) {
            revert InvalidUserRank(rank[msg.sender], 1);
        }
        _;
    }

    /**
     * @dev Modifier to limit function calls to Rank II
     */
    modifier onlyRankII() {
        if (rank[msg.sender] < 2) {
            revert InvalidUserRank(rank[msg.sender], 2);
        }
        _;
    }

    /* Protocol variables */
    /**
     * @dev whitelistedStable Does an ERC20 stablecoin is whitelisted as listing payment
     */
    mapping(address => bool) public whitelistedStable;

    /**
     * @dev whitelistedSubmitter Does this user needs to pay for a Token submission
     * @dev whitelistedLastSubmit Timestamp last submission
     * @dev whitelistedCooldown Minimum time required between two Token submission for whitelisted users
     */
    mapping(address => bool) public whitelistedSubmitter;
    mapping(address => uint256) public whitelistedLastSubmit;
    uint256 public whitelistedCooldown;

    /**
     * @dev submitFloorPrice Minimim price to pay for a listing
     */
    uint256 public submitFloorPrice;

    /**
     * @dev whitelistedAxelarContract Does an address on a blockchain is whitelisted
     */
    mapping(string => mapping(string => bool)) public whitelistedAxelarContract;

    /**
     * @dev tokenListings All Token Listings
     */
    TokenListing[] public tokenListings;

    /**
     * @dev sortingMaxVotes Maximum votes count for Sorting
     * @dev sortingMinAcceptancesPct Minimum % of Acceptances for Sorting
     * @dev sortingMinModificationsPct Minimum % of ModificationsNeeded for Sorting
     * @dev validationMaxVotes Maximum votes count for Validation
     * @dev validationMinAcceptancesPct Minimum % of Acceptances for Validation
     * @dev validationMinModificationsPct Minimum % of ModificationsNeeded for Validation
     * @dev tokensPerVote Amount of tokens rewarded per vote (* coeff)
     */
    uint256 public sortingMaxVotes;
    uint256 public sortingMinAcceptancesPct;
    uint256 public sortingMinModificationsPct;
    uint256 public validationMaxVotes;
    uint256 public validationMinAcceptancesPct;
    uint256 public validationMinModificationsPct;
    uint256 public tokensPerVote;

    /**
     * @dev membersToPromoteToRankI Amount of Rank I promotions available
     * @dev membersToPromoteToRankII Amount of Rank II promotions available
     * @dev votesNeededToRankIPromotion Amount of votes needed for a Rank I promotion
     * @dev votesNeededToRankIIPromotion Amount of votes needed for a Rank II promotion
     * @dev membersToDemoteFromRankI Amount of Rank I demotion available
     * @dev membersToDemoteFromRankII Amount of Rank II demotion available
     * @dev votesNeededToRankIDemotion Amount of votes needed for a Rank I demotion
     * @dev votesNeededToRankIIDemotion Amount of votes needed for a Rank II demotion
     * @dev voteCooldown Minimum time required between a Token update and a first validation vote
     * @dev editCoeffMultiplier Coefficient multiplier for Token update (edit)
     */
    uint256 public membersToPromoteToRankI;
    uint256 public membersToPromoteToRankII;
    uint256 public votesNeededToRankIPromotion;
    uint256 public votesNeededToRankIIPromotion;
    uint256 public membersToDemoteFromRankI;
    uint256 public membersToDemoteFromRankII;
    uint256 public votesNeededToRankIDemotion;
    uint256 public votesNeededToRankIIDemotion;
    uint256 public voteCooldown;
    uint256 public editCoeffMultiplier;

    /**
     * @dev rank User rank
     * @dev promoteVotes Amount of votes for User promotion
     * @dev demoteVotes Amount of votes for User demotion
     * @dev goodSortingVotes Amount of User's 'good' first votes
     * @dev badSortingVotes Amount of User's 'bad' first votes
     * @dev goodValidationVotes Amount of User's 'good' final votes
     * @dev badValidationVotes Amount of User's 'bad' final votes
     * @dev owedRewards Amount of User's owed rewards
     * @dev paidRewards Amount of User's paid rewards
     */
    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodSortingVotes;
    mapping(address => uint256) public badSortingVotes;
    mapping(address => uint256) public goodValidationVotes;
    mapping(address => uint256) public badValidationVotes;
    mapping(address => uint256) public owedRewards;
    mapping(address => uint256) public paidRewards;

    /**
     * @dev poolListings IDs of listing in Pool state
     * @dev updatingListings IDs of listing in Updating state
     * @dev sortingListings IDs of listing in Sorting state
     * @dev validationListings IDs of listing in Validation state
     * @dev validatedListings IDs of listing in Validated state
     * @dev rejectedListings IDs of listing in Rejected state
     * @dev killedListings IDs of listing in Killed state
     */
    uint256[] poolListings;
    uint256[] updatingListings;
    uint256[] sortingListings;
    uint256[] validationListings;
    uint256[] validatedListings;
    uint256[] rejectedListings;
    uint256[] killedListings;

    /**
     * @dev sortingVotesPhase Token's Sorting Users vote phase
     * @dev validationVotesPhase Token's Validation Users vote phase
     */
    mapping(uint256 => mapping(address => uint256)) public sortingVotesPhase;
    mapping(uint256 => mapping(address => uint256)) public validationVotesPhase;

    /**
     * @dev sortingAcceptances Token's Sorting Accept voters
     * @dev sortingRejections Token's Sorting Reject voters
     * @dev sortingModifications Token's Sorting ModificationsNeeded voters
     * @dev validationAcceptances Token's Validation Accept voters
     * @dev validationRejections Token's Validation Reject voters
     * @dev validationModifications Token's Validation ModificationsNeeded voters
     */
    mapping(uint256 => address[]) public sortingAcceptances;
    mapping(uint256 => address[]) public sortingRejections;
    mapping(uint256 => address[]) public sortingModifications;
    mapping(uint256 => address[]) public validationAcceptances;
    mapping(uint256 => address[]) public validationRejections;
    mapping(uint256 => address[]) public validationModifications;
    
    /**
     * @dev PAYMENT_COEFF Payment coefficient
     */
    uint256 private constant PAYMENT_COEFF = 1000;

    /**
     * @dev mobulaToken MOBL token address
     */
    address private mobulaToken;

    /**
     * @dev protocolAPI API address
     */
    address public protocolAPI;

    /* Events */
    event TokenListingSubmitted(address submitter, TokenListing tokenListing);
    event TokenDetailsUpdated(Token token);
    event TokenListingFunded(address indexed funder, TokenListing tokenListing, uint256 amount);
    event RewardsClaimed(address indexed claimer, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ERC20FundsWithdrawn(address indexed recipient, address indexed contractAddress, uint256 amount);
    event UserPromoted(address indexed promoted, uint256 newRank);
    event UserDemoted(address indexed demoted, uint256 newRank);
    event ListingStatusUpdated(Token token, ListingStatus previousStatus, ListingStatus newStatus);
    event SortingVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event ValidationVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event TokenValidated(Token token);

    constructor(address gateway_, address _owner, address _mobulaToken) AxelarExecutable(gateway_) {
        _transferOwnership(_owner);
        mobulaToken = _mobulaToken;
    }

    /* Getters */

    /**
     * @dev Retrieve all Token listings
     */
    function getTokenListings() external view returns (TokenListing[] memory) {
        return tokenListings;
    }

    /**
     * @dev Retrieve all Token listings in Sorting status
     */
    function getSortingTokenListings() external view returns (TokenListing[] memory) {
        return getTokenListingsWithStatus(ListingStatus.Sorting);
    }

    /**
     * @dev Retrieve all Token listings in Validation status
     */
    function getValidationTokenListings() external view returns (TokenListing[] memory) {
        return getTokenListingsWithStatus(ListingStatus.Validation);
    }

    /**
     * @dev Retrieve all Token listings in a specific status
     * @param status Status of listings to retrieve
     */
    function getTokenListingsWithStatus(ListingStatus status) public view returns (TokenListing[] memory) {
        if (status == ListingStatus.Init) {
            return new TokenListing[](0);
        }

        uint256[] memory tokenIds = _getStorageArrayForStatus(status);

        TokenListing[] memory listings = new TokenListing[](tokenIds.length);
        for (uint256 i; i < listings.length; i++) {
            listings[i] = tokenListings[tokenIds[i]];
        }

        return listings;
    }
    
    /* Users methods */

    /**
     * @dev Allows the submitter of a Token to update Token details
     * @param tokenId ID of the Token to update
     * @param ipfsHash New IPFS hash of the Token
     */
    function updateToken(uint256 tokenId, string memory ipfsHash) external {
        _updateToken(tokenId, ipfsHash, msg.sender);
    }

    /**
     * @dev Allows a user to submit a Token for validation
     * @param ipfsHash IPFS hash of the Token
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param tokenId ID of the Token to update (if update, 0 otherwise)
     */
    // TODO : Return tokenId ?
    function submitToken(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount, uint256 tokenId) external {
        _submitToken(ipfsHash, paymentTokenAddress, paymentAmount, msg.sender, tokenId);
    }

    /**
     * @dev Allows a user to top up listing payment
     * @param tokenId ID of the Token to top up
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     */
    function topUpToken(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount) external {
        _topUpToken(tokenId, paymentTokenAddress, paymentAmount, msg.sender);
    }

    /**
     * @dev Claim User rewards
     * @param user User to claim rewards for
     */
    function claimRewards(address user) external {
        uint256 amountToPay = owedRewards[user] * tokensPerVote;
        if (amountToPay == 0) revert NothingToClaim(user);

        paidRewards[user] += amountToPay;
        delete owedRewards[user];

        uint256 moblAmount = amountToPay / PAYMENT_COEFF;

        IERC20(mobulaToken).transfer(user, moblAmount);

        emit RewardsClaimed(user, moblAmount);
    }

    /* Votes */

    /**
     * @dev Allows a ranked user to vote for Token Sorting
     * @param tokenId ID of the Token to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteSorting(uint256 tokenId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRanked
    {
        if (tokenId >= tokenListings.length) revert TokenNotFound(tokenId);

        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Sorting) revert NotSortingListing(listing.token, listing.status);

        if (listing.token.lastUpdate > block.timestamp - voteCooldown) revert TokenInCooldown(listing.token);

        if (sortingVotesPhase[tokenId][msg.sender] >= listing.phase) revert AlreadyVoted(msg.sender, listing.status, listing.phase);

        sortingVotesPhase[tokenId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            sortingModifications[tokenId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            sortingRejections[tokenId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) revert InvalidScoreValue();

            sortingAcceptances[tokenId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit SortingVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (sortingModifications[tokenId].length * 100 >= sortingMaxVotes * sortingMinModificationsPct) {
            _updateListingStatus(tokenId, ListingStatus.Updating);
        } else if (sortingAcceptances[tokenId].length + sortingRejections[tokenId].length + sortingModifications[tokenId].length >= sortingMaxVotes) {
            if (sortingAcceptances[tokenId].length * 100 >= sortingMaxVotes * sortingMinAcceptancesPct) {
                _updateListingStatus(tokenId, ListingStatus.Validation);
            } else {
                _updateListingStatus(tokenId, ListingStatus.Rejected);
            }
        }
    }

    /**
     * @dev Allows a rank II User to vote for Token Validation
     * @param tokenId ID of the Token to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteValidation(uint256 tokenId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRankII
    {
        if (tokenId >= tokenListings.length) revert TokenNotFound(tokenId);

        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Validation) revert NotValidationListing(listing.token, listing.status);

        if (validationVotesPhase[tokenId][msg.sender] >= listing.phase) revert AlreadyVoted(msg.sender, listing.status, listing.phase);

        validationVotesPhase[tokenId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            validationModifications[tokenId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            validationRejections[tokenId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) revert InvalidScoreValue();

            validationAcceptances[tokenId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit ValidationVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (validationModifications[tokenId].length * 100 >= validationMaxVotes * validationMinModificationsPct) {
            _updateListingStatus(tokenId, ListingStatus.Updating);
        } else if (validationAcceptances[tokenId].length + validationRejections[tokenId].length + validationModifications[tokenId].length >= validationMaxVotes) {
            if (validationAcceptances[tokenId].length * 100 >= validationMaxVotes * validationMinAcceptancesPct) {
                _rewardVoters(tokenId, ListingStatus.Validated);

                _saveToken(tokenId);

                _updateListingStatus(tokenId, ListingStatus.Validated);
            } else {
                _rewardVoters(tokenId, ListingStatus.Rejected);

                _updateListingStatus(tokenId, ListingStatus.Rejected);
            }
        }
    }

    /* Hierarchy Management */

    /**
     * @dev Allows a Rank II user to vote for a promotion for a Rank I user or below
     * @param promoted Address of the user
     */
    function promote(address promoted) external onlyRankII {
        uint256 rankPromoted = rank[promoted];
        if (rankPromoted > 1) revert RankPromotionImpossible(rankPromoted, 1);

        if (rankPromoted == 0) {
            if (membersToPromoteToRankI == 0) revert NoPromotionYet(1);
            ++promoteVotes[promoted];

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                --membersToPromoteToRankI;
                _promote(promoted);
            }
        } else {
            if (membersToPromoteToRankII == 0) revert NoPromotionYet(2);
            ++promoteVotes[promoted];

            if (promoteVotes[promoted] == votesNeededToRankIIPromotion) {
                --membersToPromoteToRankII;
                _promote(promoted);
            }
        }
    }

    /**
     * @dev Allows a Rank II user to vote for a demotion for a Rank II user or below
     * @param demoted Address of the user
     */
    function demote(address demoted) external onlyRankII {
        uint256 rankDemoted = rank[demoted];
        if (rankDemoted == 0) revert RankDemotionImpossible(rankDemoted, 1);

        if (rankDemoted == 1) {
            if (membersToDemoteFromRankI == 0) revert NoDemotionYet(1);
            ++demoteVotes[demoted];

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                --membersToDemoteFromRankI;
                _demote(demoted);
            }
        } else {
            if (membersToDemoteFromRankII == 0) revert NoDemotionYet(2);
            ++demoteVotes[demoted];

            if (demoteVotes[demoted] == votesNeededToRankIIDemotion) {
                --membersToDemoteFromRankII;
                _demote(demoted);
            }
        }
    }

    /* Emergency Methods */

    /**
     * @dev Allows the owner to promote a user
     * @param promoted Address of the user
     */
    function emergencyPromote(address promoted) external onlyOwner {
        uint256 rankPromoted = rank[promoted];
        if (rankPromoted > 1) revert RankPromotionImpossible(rankPromoted, 1);
        _promote(promoted);
    }

    /**
     * @dev Allows the owner to demote a user
     * @param demoted Address of the user
     */
    function emergencyDemote(address demoted) external onlyOwner {
        uint256 rankDemoted = rank[demoted];
        if (rankDemoted == 0) revert RankDemotionImpossible(rankDemoted, 1);
        _demote(demoted);
    }

    /**
     * @dev Allows the owner to remove a Token from the validation process
     * @param tokenId ID of the Token
     */
    function emergencyKillRequest(uint256 tokenId) external onlyOwner {
        _updateListingStatus(tokenId, ListingStatus.Killed);
    }

    /**
     * @dev Allows the owner to change a Token listing status
     * @param tokenId ID of the Token
     * @param status New status of the listing
     */
     function emergencyUpdateListingStatus(uint256 tokenId, ListingStatus status) external onlyOwner {
        _updateListingStatus(tokenId, status);
    }

    /* Protocol Management */

    function whitelistStable(address _stableAddress, bool whitelisted) external onlyOwner {
        whitelistedStable[_stableAddress] = whitelisted;
    }

    function whitelistSubmitter(address _submitter, bool whitelisted) external onlyOwner {
        whitelistedSubmitter[_submitter] = whitelisted;
    }

    function whitelistAxelarContract(string memory _sourceChain, string memory _sourceAddress, bool whitelisted) external onlyOwner {
        whitelistedAxelarContract[_sourceChain][_sourceAddress] = whitelisted;
    }

    function updateProtocolAPIAddress(address _protocolAPI) external onlyOwner {
        protocolAPI = _protocolAPI;
    }

    function updateSubmitFloorPrice(uint256 _submitFloorPrice) external onlyOwner {
        submitFloorPrice = _submitFloorPrice;
    }

    function updateSortingMaxVotes(uint256 _sortingMaxVotes) external onlyOwner {
        sortingMaxVotes = _sortingMaxVotes;
    }

    function updateValidationMaxVotes(uint256 _validationMaxVotes)
        external
        onlyOwner
    {
        validationMaxVotes = _validationMaxVotes;
    }

    function updateEditCoeffMultiplier(uint256 _editCoeffMultiplier)
        external
        onlyOwner
    {
        editCoeffMultiplier = _editCoeffMultiplier;
    }

    function updateSortingMinAcceptancesPct(uint256 _sortingMinAcceptancesPct) external onlyOwner {
        if (_sortingMinAcceptancesPct > 100) revert InvalidPercentage(_sortingMinAcceptancesPct);
        sortingMinAcceptancesPct = _sortingMinAcceptancesPct;
    }

    function updateSortingMinModificationsPct(uint256 _sortingMinModificationsPct) external onlyOwner {
        if (_sortingMinModificationsPct > 100) revert InvalidPercentage(_sortingMinModificationsPct);
        sortingMinModificationsPct = _sortingMinModificationsPct;
    }

    function updateValidationMinAcceptancesPct(uint256 _validationMinAcceptancesPct) external onlyOwner {
        if (_validationMinAcceptancesPct > 100) revert InvalidPercentage(_validationMinAcceptancesPct);
        validationMinAcceptancesPct = _validationMinAcceptancesPct;
    }

    function updateValidationMinModificationsPct(uint256 _validationMinModificationsPct) external onlyOwner {
        if (_validationMinModificationsPct > 100) revert InvalidPercentage(_validationMinModificationsPct);
        validationMinModificationsPct = _validationMinModificationsPct;
    }

    function updateTokensPerVote(uint256 _tokensPerVote) external onlyOwner {
        tokensPerVote = _tokensPerVote;
    }

    function updateMembersToPromoteToRankI(uint256 _membersToPromoteToRankI)
        external
        onlyOwner
    {
        membersToPromoteToRankI = _membersToPromoteToRankI;
    }

    function updateMembersToPromoteToRankII(uint256 _membersToPromoteToRankII)
        external
        onlyOwner
    {
        membersToPromoteToRankII = _membersToPromoteToRankII;
    }

    function updateMembersToDemoteFromRankI(uint256 _membersToDemoteToRankI)
        external
        onlyOwner
    {
        membersToDemoteFromRankI = _membersToDemoteToRankI;
    }

    function updateMembersToDemoteFromRankII(uint256 _membersToDemoteToRankII)
        external
        onlyOwner
    {
        membersToDemoteFromRankII = _membersToDemoteToRankII;
    }

    function updateVotesNeededToRankIPromotion(
        uint256 _votesNeededToRankIPromotion
    ) external onlyOwner {
        votesNeededToRankIPromotion = _votesNeededToRankIPromotion;
    }

    function updateVotesNeededToRankIIPromotion(
        uint256 _votesNeededToRankIIPromotion
    ) external onlyOwner {
        votesNeededToRankIIPromotion = _votesNeededToRankIIPromotion;
    }

    function updateVotesNeededToRankIDemotion(
        uint256 _votesNeededToRankIDemotion
    ) external onlyOwner {
        votesNeededToRankIDemotion = _votesNeededToRankIDemotion;
    }

    function updateVotesNeededToRankIIDemotion(
        uint256 _votesNeededToRankIIDemotion
    ) external onlyOwner {
        votesNeededToRankIIDemotion = _votesNeededToRankIIDemotion;
    }

    function updateVoteCooldown(uint256 _voteCooldown) external onlyOwner {
        voteCooldown = _voteCooldown;
    }

    function updateWhitelistedCooldown(uint256 _whitelistedCooldown) external onlyOwner {
        whitelistedCooldown = _whitelistedCooldown;
    }

    /* Funds Management */

    /**
     * @dev Withdraw ETH amount to recipient
     * @param recipient The recipient
     * @param amount Amount to withdraw
     */
    function withdrawFunds(address recipient, uint256 amount) external onlyOwner {
        uint256 protocolBalance = address(this).balance;
        if (amount > protocolBalance) revert InsufficientProtocolBalance(protocolBalance, amount);

        (bool success,) = recipient.call{value: amount}("");

        if (!success) revert ETHTransferFailed(recipient);

        emit FundsWithdrawn(recipient, amount);
    }

    /**
     * @dev Withdraw ERC20 amount to recipient
     * @param recipient The recipient
     * @param amount Amount to withdraw
     * @param contractAddress ERC20 address
     */
    function withdrawERC20Funds(address recipient, uint256 amount, address contractAddress) external onlyOwner {
        bool success = IERC20Extended(contractAddress).transfer(recipient, amount);

        if (!success) revert ERC20WithdrawFailed(contractAddress, recipient, amount);

        emit ERC20FundsWithdrawn(recipient, contractAddress, amount);
    }

    /* Axelar callback */

    /**
     * @dev Execute a cross chain call from Axelar
     * @param sourceChain Source blockchain
     * @param sourceAddress Source smart contract address
     * @param payload Payload
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        if (!whitelistedAxelarContract[sourceChain][sourceAddress]) revert InvalidAxelarContract(sourceChain, sourceAddress);

        MobulaPayload memory mPayload = abi.decode(payload, (MobulaPayload));
        
        if (mPayload.method == MobulaMethod.SubmitToken) {
            _submitToken(mPayload.ipfsHash, mPayload.paymentTokenAddress, mPayload.paymentAmount, mPayload.sender, mPayload.tokenId);
        } else if (mPayload.method == MobulaMethod.UpdateToken) {
            _updateToken(mPayload.tokenId, mPayload.ipfsHash, mPayload.sender);
        } else if (mPayload.method == MobulaMethod.TopUpToken) {
            _topUpToken(mPayload.tokenId, mPayload.paymentTokenAddress, mPayload.paymentAmount, mPayload.sender);
        } else {
            revert UnknownMethod(mPayload);
        }
    }

    /* Internal Methods */

    /**
     * @dev Allows the submitter of a Token to update Token details
     * @param tokenId ID of the Token to update
     * @param ipfsHash New IPFS hash of the Token
     * @param sourceMsgSender Sender of the tx
     */
    function _updateToken(uint256 tokenId, string memory ipfsHash, address sourceMsgSender) internal {
        if (tokenId >= tokenListings.length) revert TokenNotFound(tokenId);

        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Updating) revert NotUpdatingListing(listing.token, listing.status);

        if (listing.submitter != sourceMsgSender) revert InvalidUpdatingUser(sourceMsgSender, listing.submitter);

        listing.token.ipfsHash = ipfsHash;
        listing.token.lastUpdate = block.timestamp;

        emit TokenDetailsUpdated(listing.token);
        
        // We put the Token back to Sorting (impossible to be in Pool status)
        _updateListingStatus(tokenId, ListingStatus.Sorting);
    }
    
    /**
     * @dev Allows a user to submit a Token for validation
     * @param ipfsHash IPFS hash of the Token
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param sourceMsgSender Sender of the tx
     * @param tokenId ID of the Token to update (if update, 0 otherwise)
     */
    function _submitToken(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender, uint256 tokenId)
        internal
    {
        uint256 coeff;
        ListingStatus status = ListingStatus.Pool;

        if (whitelistedSubmitter[sourceMsgSender]) {
            if (whitelistedLastSubmit[sourceMsgSender] > block.timestamp - whitelistedCooldown) revert SubmitterInCooldown(sourceMsgSender);
            whitelistedLastSubmit[sourceMsgSender] = block.timestamp;

            coeff = PAYMENT_COEFF;
        } else if (paymentAmount != 0) {
            // If method was called from another chain
            if (msg.sender != sourceMsgSender) {
                coeff = _getCoeff(paymentAmount);
            } else {
                coeff = _payment(paymentTokenAddress, paymentAmount);
            }
        }

        if (tokenId >= tokenListings.length) {
            revert TokenNotFound(tokenId);
        }

        if (tokenId != 0) {
            coeff += PAYMENT_COEFF * editCoeffMultiplier;
        }

        if (coeff >= PAYMENT_COEFF) {
            status = ListingStatus.Sorting;
        }

        Token memory token;
        token.ipfsHash = ipfsHash;
        token.lastUpdate = block.timestamp;
        
        TokenListing memory listing;
        listing.token = token;
        listing.coeff = coeff;
        listing.submitter = sourceMsgSender;
        listing.phase = 1;

        tokenListings.push(listing);
        token.id = tokenListings.length - 1;

        emit TokenListingSubmitted(sourceMsgSender, listing);
        
        _updateListingStatus(token.id, status);
    }

    /**
     * @dev Allows a user to top up listing payment
     * @param tokenId ID of the Token to top up
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param sourceMsgSender Sender of the tx
     */
    function _topUpToken(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender) internal {
        if (tokenId >= tokenListings.length) revert TokenNotFound(tokenId);
        if (paymentAmount == 0) revert InvalidPaymentAmount();

        // If method was called from another chain
        if (msg.sender != sourceMsgSender) {
            tokenListings[tokenId].coeff += _getCoeff(paymentAmount);
        } else {
            tokenListings[tokenId].coeff += _payment(paymentTokenAddress, paymentAmount);
        }

        emit TokenListingFunded(sourceMsgSender, tokenListings[tokenId], paymentAmount);

        if (tokenListings[tokenId].status == ListingStatus.Pool && tokenListings[tokenId].coeff >= PAYMENT_COEFF) {
            _updateListingStatus(tokenId, ListingStatus.Sorting);
        }
    }

    /**
     * @dev Update the status of a listing, by moving the listing/token index from one status array to another one
     * @param tokenId ID of the Token to vote for
     * @param status New listing status
     */
    function _updateListingStatus(uint256 tokenId, ListingStatus status) internal {
        TokenListing storage listing = tokenListings[tokenId];

        if (status == ListingStatus.Init) revert InvalidStatusUpdate(listing.token, listing.status, status);

        if (listing.status != ListingStatus.Init) {
            // Can only be updated to Pool status, if current status is Init
            if (status == ListingStatus.Pool) revert InvalidStatusUpdate(listing.token, listing.status, status);

            // Remove listing from current status array
            uint256[] storage fromArray = _getStorageArrayForStatus(listing.status);
            uint256 indexMovedListing = fromArray[fromArray.length - 1];
            fromArray[listing.statusIndex] = indexMovedListing;
            tokenListings[indexMovedListing].statusIndex = listing.statusIndex;
            fromArray.pop();
        }

        // Add listing to new status array
        uint256[] storage toArray = _getStorageArrayForStatus(status);
        listing.statusIndex = toArray.length;
        toArray.push(tokenId);

        ListingStatus previousStatus = listing.status;
        listing.status = status;

        // For these status, we need to reset all votes and scores of the listing
        if (status == ListingStatus.Updating || status == ListingStatus.Rejected || status == ListingStatus.Validated || status == ListingStatus.Killed) {
            // Increment listing phase, so voters will be able to vote again on this listing
            if (status == ListingStatus.Updating) {
                ++listing.phase;
            }

            delete listing.accruedUtilityScore;
            delete listing.accruedSocialScore;
            delete listing.accruedTrustScore;

            delete sortingAcceptances[tokenId];
            delete sortingRejections[tokenId];
            delete sortingModifications[tokenId];
            delete validationAcceptances[tokenId];
            delete validationRejections[tokenId];
            delete validationModifications[tokenId];
        }

        emit ListingStatusUpdated(listing.token, previousStatus, status);
    }

    /**
     * @dev Retrieve status' corresponding storage array
     * @param status Status
     */
    function _getStorageArrayForStatus(ListingStatus status) internal view returns (uint256[] storage) {
        uint256[] storage array = poolListings;
        if (status == ListingStatus.Updating) {
            array = updatingListings;
        } else if (status == ListingStatus.Sorting) {
            array = sortingListings;
        } else if (status == ListingStatus.Validation) {
            array = validationListings;
        } else if (status == ListingStatus.Validated) {
            array = validatedListings;
        } else if (status == ListingStatus.Rejected) {
            array = rejectedListings;
        } else if (status == ListingStatus.Killed) {
            array = killedListings;
        }
        return array;
    }

    /**
     * @dev Save Token in Protocol API
     * @param tokenId ID of the Token to save
     */
    function _saveToken(uint256 tokenId) internal {
        TokenListing storage listing = tokenListings[tokenId];

        uint256 scoresCount = sortingAcceptances[tokenId].length + validationAcceptances[tokenId].length;

        // TODO : Handle float value (x10 then round() / 10 ?)
        listing.token.utilityScore = listing.accruedUtilityScore / scoresCount;
        listing.token.socialScore = listing.accruedSocialScore / scoresCount;
        listing.token.trustScore = listing.accruedTrustScore / scoresCount;
        
        IAPI(protocolAPI).addAssetData(listing.token);

        emit TokenValidated(listing.token);
    }

    /**
     * @dev Reward voters of a Token listing process
     * @param tokenId ID of the Token
     * @param finalStatus Final status of the listing
     */
    function _rewardVoters(uint256 tokenId, ListingStatus finalStatus) internal {
        uint256 coeff = tokenListings[tokenId].coeff;

        for (uint256 i; i < sortingAcceptances[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodSortingVotes[sortingAcceptances[tokenId][i]];
                owedRewards[sortingAcceptances[tokenId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingAcceptances[tokenId][i]];
            }
        }
        
        for (uint256 i; i < sortingRejections[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodSortingVotes[sortingRejections[tokenId][i]];
                owedRewards[sortingRejections[tokenId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingRejections[tokenId][i]];
            }
        }

        for (uint256 i; i < validationAcceptances[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodValidationVotes[validationAcceptances[tokenId][i]];
                owedRewards[validationAcceptances[tokenId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationAcceptances[tokenId][i]];
            }
        }

        for (uint256 i; i < validationRejections[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodValidationVotes[validationRejections[tokenId][i]];
                owedRewards[validationRejections[tokenId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationRejections[tokenId][i]];
            }
        }
    }

    /**
     * @dev Make the payment from user
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @return coeff Coeff to add to the listing
     */
    function _payment(address paymentTokenAddress, uint256 paymentAmount) internal returns (uint256 coeff) {
        if (!whitelistedStable[paymentTokenAddress]) revert InvalidPaymentToken(paymentTokenAddress);

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);

        if (!success) revert TokenPaymentFailed(paymentTokenAddress, amount);

        coeff = _getCoeff(paymentAmount);
    }

    /**
     * @dev Get the coeff for a payment amount
     * @param paymentAmount Amount paid (without decimals)
     * @return coeff Coeff to add to the listing
     */
    function _getCoeff(uint256 paymentAmount) internal view returns (uint256 coeff) {
        coeff = (paymentAmount * PAYMENT_COEFF) / submitFloorPrice;
    }

    /**
     * @dev Increase user rank
     * @param promoted Address of the user
     */
    function _promote(address promoted) internal {
        delete promoteVotes[promoted];

        emit UserPromoted(promoted, ++rank[promoted]);
    }

    /**
     * @dev Decrease user rank
     * @param demoted Address of the user
     */
    function _demote(address demoted) internal {
        delete demoteVotes[demoted];

        emit UserDemoted(demoted, --rank[demoted]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

contract AxelarExecutable is IAxelarExecutable {
    IAxelarGateway public immutable gateway;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../lib/TokenStructs.sol";

interface IAPI {
    function addAssetData(Token memory token) external;

    function addStaticData(address token, string memory hashString) external;

    function staticData(address token)
        external
        view
        returns (string memory hashString);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AxelarStructs.sol";
import "./TokenStructs.sol";

// TODO : Add NatSpec + Token to tokenId ?

error AlreadyVoted(address voter, ListingStatus status, uint256 listingPhase);
error InvalidPaymentToken(address paymentToken);
error TokenPaymentFailed(address paymentToken, uint256 amount);
error TokenNotFound(uint256 tokenId);
error InvalidPaymentAmount();
error InvalidUpdatingUser(address sender, address submitter);
error NotSortingListing(Token token, ListingStatus status);
error NotUpdatingListing(Token token, ListingStatus status);
error NotValidationListing(Token token, ListingStatus status);
error TokenInCooldown(Token token);
error SubmitterInCooldown(address submitter);
error InvalidScoreValue();
error InsufficientProtocolBalance(uint256 protocolBalance, uint256 amountToWithdraw);
error NothingToClaim(address claimer);
error ETHTransferFailed(address recipient);
error ERC20WithdrawFailed(address contractAddress, address recipient, uint256 amount);
error InvalidUserRank(uint256 userRank, uint256 minimumRankNeeded);
error RankPromotionImpossible(uint256 userRank, uint256 maxCurrentRank);
error NoPromotionYet(uint256 toRank);
error RankDemotionImpossible(uint256 userRank, uint256 minCurrentRank);
error NoDemotionYet(uint256 fromRank);
error InvalidPercentage(uint256 percentage);
error InvalidStatusUpdate(Token token, ListingStatus currentStatus, ListingStatus targetStatus);
error UnknownMethod(MobulaPayload payload);
error InvalidAxelarContract(string sourceChain, string sourceAddress);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
* @dev Enum to define a listing vote
* @custom:Accept Accept the Token
* @custom:Reject Reject the Token
* @custom:ModificationsNeeded Token needs modifications
*/
enum ListingVote {
    Accept,
    Reject,
    ModificationsNeeded
}

/**
* @dev Enum to define Listing status
* @custom:Init Initial Listing status
* @custom:Pool Token has been submitted
* @custom:Updating Submitter needs to update Token details
* @custom:Sorting RankI users can vote to sort this Token
* @custom:Validation RankII users can vote to validate this Token
* @custom:Validated Token has been validated and listed
* @custom:Rejected Token has been rejected
* @custom:Killed Token has been killed by owner
*/
enum ListingStatus {
    Init,
    Pool,
    Updating,
    Sorting,
    Validation,
    Validated,
    Rejected,
    Killed
}

/**
 * @custom:ipfsHash IPFS Hash of metadatas
 * @custom:id Attributed ID for the Token
 * @custom:lastUpdate Timestamp of Token's last update
 * @custom:utilityScore Token's utility score
 * @custom:socialScore Token's social score
 * @custom:trustScore Token's trust score
 */
// TODO : Use uint8 score type ?
struct Token {
    string ipfsHash;
    uint256 id;
    uint256 lastUpdate;
    uint256 utilityScore;
    uint256 socialScore;
    uint256 trustScore;
}

/**
 * @custom:token Token
 * @custom:coeff Listing coeff
 * @custom:status Listing status
 * @custom:submitter User who submitted the Token for listing
 * @custom:statusIndex Index of listing in corresponding statusArray
 * @custom:accruedUtilityScore Sum of voters utility score
 * @custom:accruedSocialScore Sum of voters social score
 * @custom:accruedTrustScore Sum of voters trust score
 * @custom:phase Phase count
 */
// TODO : Reorg for gas effiency 
struct TokenListing {
    Token token;
    uint256 coeff;
    ListingStatus status;
    address submitter;
    uint256 statusIndex;

    uint256 accruedUtilityScore;
    uint256 accruedSocialScore;
    uint256 accruedTrustScore;

    uint256 phase;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum MobulaMethod {
    SubmitToken,
    UpdateToken,
    TopUpToken
}

struct MobulaPayload {
    MobulaMethod method;
    address sender;
    address paymentTokenAddress;
    string ipfsHash;
    uint256 tokenId;
    uint256 paymentAmount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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