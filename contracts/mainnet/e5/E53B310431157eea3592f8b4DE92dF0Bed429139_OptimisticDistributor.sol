// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/AncillaryData.sol";
import "../../common/implementation/Lockable.sol";
import "../../common/implementation/MultiCaller.sol";
import "../../common/implementation/Testable.sol";
import "../../common/interfaces/AddressWhitelistInterface.sol";
import "../../merkle-distributor/implementation/MerkleDistributor.sol";
import "../../oracle/implementation/Constants.sol";
import "../../oracle/interfaces/FinderInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/interfaces/OptimisticOracleV2Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  OptimisticDistributor contract.
 * @notice Allows sponsors to distribute rewards through MerkleDistributor contract secured by UMA Optimistic Oracle.
 */
contract OptimisticDistributor is Lockable, MultiCaller, Testable {
    using SafeERC20 for IERC20;

    /********************************************
     *  OPTIMISTIC DISTRIBUTOR DATA STRUCTURES  *
     ********************************************/

    // Represents reward posted by a sponsor.
    struct Reward {
        bool distributionExecuted;
        address sponsor;
        IERC20 rewardToken;
        uint256 maximumRewardAmount;
        uint256 earliestProposalTimestamp;
        uint256 optimisticOracleProposerBond;
        uint256 optimisticOracleLivenessTime;
        uint256 previousProposalTimestamp;
        bytes32 priceIdentifier;
        bytes customAncillaryData;
    }

    // Represents proposed rewards distribution.
    struct Proposal {
        uint256 rewardIndex;
        uint256 timestamp;
        bytes32 merkleRoot;
        string ipfsHash;
    }

    /********************************************
     *      STATE VARIABLES AND CONSTANTS       *
     ********************************************/

    // Reserve for bytes appended to ancillary data (e.g. OracleSpoke) when resolving price from non-mainnet chains.
    // This also covers appending rewardIndex by this contract.
    uint256 public constant ANCILLARY_BYTES_RESERVE = 512;

    // Restrict Optimistic Oracle liveness to between 10 minutes and 100 years.
    uint256 public constant MINIMUM_LIVENESS = 10 minutes;
    uint256 public constant MAXIMUM_LIVENESS = 5200 weeks;

    // Ancillary data length limit can be synced and stored in the contract.
    uint256 public ancillaryBytesLimit;

    // Rewards are stored in dynamic array.
    Reward[] public rewards;

    // Immutable variables used to validate input parameters when funding new rewards.
    uint256 public immutable maximumFundingPeriod;
    uint256 public immutable maximumProposerBond;

    // Proposals are mapped to hash of their identifier, timestamp and ancillaryData.
    mapping(bytes32 => Proposal) public proposals;

    // Immutable variables provided at deployment.
    FinderInterface public immutable finder;
    IERC20 public immutable bondToken;

    // Merkle Distributor is automatically deployed on constructor and owned by this contract.
    MerkleDistributor public immutable merkleDistributor;

    // Interface parameters that can be synced and stored in the contract.
    OptimisticOracleV2Interface public optimisticOracle;

    /********************************************
     *                  EVENTS                  *
     ********************************************/

    event RewardCreated(
        address indexed sponsor,
        IERC20 rewardToken,
        uint256 indexed rewardIndex,
        uint256 maximumRewardAmount,
        uint256 earliestProposalTimestamp,
        uint256 optimisticOracleProposerBond,
        uint256 optimisticOracleLivenessTime,
        bytes32 indexed priceIdentifier,
        bytes customAncillaryData
    );
    event RewardIncreased(uint256 indexed rewardIndex, uint256 newMaximumRewardAmount);
    event ProposalCreated(
        address indexed sponsor,
        IERC20 rewardToken,
        uint256 indexed rewardIndex,
        uint256 proposalTimestamp,
        uint256 maximumRewardAmount,
        bytes32 indexed proposalId,
        bytes32 merkleRoot,
        string ipfsHash
    );
    event RewardDistributed(
        address indexed sponsor,
        IERC20 rewardToken,
        uint256 indexed rewardIndex,
        uint256 maximumRewardAmount,
        bytes32 indexed proposalId,
        bytes32 merkleRoot,
        string ipfsHash
    );
    event ProposalRejected(uint256 indexed rewardIndex, bytes32 indexed proposalId);

    /**
     * @notice Constructor.
     * @param _finder Finder to look up UMA contract addresses.
     * @param _bondToken ERC20 token that the bond is paid in.
     * @param _timer Contract that stores the current time in a testing environment.
     * @param _maximumFundingPeriod Maximum period for reward funding (proposals allowed only afterwards).
     * @param _maximumProposerBond Maximum allowed Optimistic Oracle proposer bond amount.
     */
    constructor(
        FinderInterface _finder,
        IERC20 _bondToken,
        address _timer,
        uint256 _maximumFundingPeriod,
        uint256 _maximumProposerBond
    ) Testable(_timer) {
        finder = _finder;
        require(_getCollateralWhitelist().isOnWhitelist(address(_bondToken)), "Bond token not supported");
        bondToken = _bondToken;
        syncUmaEcosystemParams();
        maximumFundingPeriod = _maximumFundingPeriod;
        maximumProposerBond = _maximumProposerBond;
        merkleDistributor = new MerkleDistributor();
    }

    /********************************************
     *            FUNDING FUNCTIONS             *
     ********************************************/

    /**
     * @notice Allows any caller to create a Reward struct and deposit tokens that are linked to these rewards.
     * @dev The caller must approve this contract to transfer `maximumRewardAmount` amount of `rewardToken`.
     * @param rewardToken ERC20 token that the rewards will be paid in.
     * @param maximumRewardAmount Maximum reward amount that the sponsor is posting for distribution.
     * @param earliestProposalTimestamp Starting timestamp when proposals for distribution can be made.
     * @param priceIdentifier Identifier that should be passed to the Optimistic Oracle on proposed distribution.
     * @param customAncillaryData Custom ancillary data that should be sent to the Optimistic Oracle on proposed
     * distribution.
     * @param optimisticOracleProposerBond Amount of bondToken that should be posted in addition to final fee
     * to the Optimistic Oracle on proposed distribution.
     * @param optimisticOracleLivenessTime Liveness period in seconds during which proposed distribution can be
     * disputed through Optimistic Oracle.
     */
    function createReward(
        uint256 maximumRewardAmount,
        uint256 earliestProposalTimestamp,
        uint256 optimisticOracleProposerBond,
        uint256 optimisticOracleLivenessTime,
        bytes32 priceIdentifier,
        IERC20 rewardToken,
        bytes calldata customAncillaryData
    ) external nonReentrant() {
        require(earliestProposalTimestamp <= getCurrentTime() + maximumFundingPeriod, "Too long till proposal opening");
        require(optimisticOracleProposerBond <= maximumProposerBond, "OO proposer bond too high");
        require(_getIdentifierWhitelist().isIdentifierSupported(priceIdentifier), "Identifier not registered");
        require(_ancillaryDataWithinLimits(customAncillaryData), "Ancillary data too long");
        require(optimisticOracleLivenessTime >= MINIMUM_LIVENESS, "OO liveness too small");
        require(optimisticOracleLivenessTime < MAXIMUM_LIVENESS, "OO liveness too large");

        // Store funded reward and log created reward.
        Reward memory reward =
            Reward({
                distributionExecuted: false,
                sponsor: msg.sender,
                rewardToken: rewardToken,
                maximumRewardAmount: maximumRewardAmount,
                earliestProposalTimestamp: earliestProposalTimestamp,
                optimisticOracleProposerBond: optimisticOracleProposerBond,
                optimisticOracleLivenessTime: optimisticOracleLivenessTime,
                previousProposalTimestamp: 0,
                priceIdentifier: priceIdentifier,
                customAncillaryData: customAncillaryData
            });
        uint256 rewardIndex = rewards.length;
        rewards.push() = reward;
        emit RewardCreated(
            reward.sponsor,
            reward.rewardToken,
            rewardIndex,
            reward.maximumRewardAmount,
            reward.earliestProposalTimestamp,
            reward.optimisticOracleProposerBond,
            reward.optimisticOracleLivenessTime,
            reward.priceIdentifier,
            reward.customAncillaryData
        );

        // Pull maximum rewards from the sponsor.
        rewardToken.safeTransferFrom(msg.sender, address(this), maximumRewardAmount);
    }

    /**
     * @notice Allows anyone to deposit additional rewards for distribution before `earliestProposalTimestamp`.
     * @dev The caller must approve this contract to transfer `additionalRewardAmount` amount of `rewardToken`.
     * @param rewardIndex Index for identifying existing Reward struct that should receive additional funding.
     * @param additionalRewardAmount Additional reward amount that the sponsor is posting for distribution.
     */
    function increaseReward(uint256 rewardIndex, uint256 additionalRewardAmount) external nonReentrant() {
        require(rewardIndex < rewards.length, "Invalid rewardIndex");
        require(getCurrentTime() < rewards[rewardIndex].earliestProposalTimestamp, "Funding period ended");

        // Update maximumRewardAmount and log new amount.
        rewards[rewardIndex].maximumRewardAmount += additionalRewardAmount;
        emit RewardIncreased(rewardIndex, rewards[rewardIndex].maximumRewardAmount);

        // Pull additional rewards from the sponsor.
        rewards[rewardIndex].rewardToken.safeTransferFrom(msg.sender, address(this), additionalRewardAmount);
    }

    /********************************************
     *          DISTRIBUTION FUNCTIONS          *
     ********************************************/

    /**
     * @notice Allows any caller to propose distribution for funded reward starting from `earliestProposalTimestamp`.
     * Only one undisputed proposal at a time is allowed.
     * @dev The caller must approve this contract to transfer `optimisticOracleProposerBond` + final fee amount
     * of `bondToken`.
     * @param rewardIndex Index for identifying existing Reward struct that should be proposed for distribution.
     * @param merkleRoot Merkle root describing allocation of proposed rewards distribution.
     * @param ipfsHash Hash of IPFS object, conveniently stored for clients to verify proposed distribution.
     */
    function proposeDistribution(
        uint256 rewardIndex,
        bytes32 merkleRoot,
        string calldata ipfsHash
    ) external nonReentrant() {
        require(rewardIndex < rewards.length, "Invalid rewardIndex");

        uint256 timestamp = getCurrentTime();
        Reward memory reward = rewards[rewardIndex];
        require(timestamp >= reward.earliestProposalTimestamp, "Cannot propose in funding period");
        require(!reward.distributionExecuted, "Reward already distributed");
        require(_noBlockingProposal(rewardIndex, reward), "New proposals blocked");

        // Store current timestamp at reward struct so that any subsequent proposals are blocked till dispute.
        rewards[rewardIndex].previousProposalTimestamp = timestamp;

        // Append rewardIndex to ancillary data.
        bytes memory ancillaryData = _appendRewardIndex(rewardIndex, reward.customAncillaryData);

        // Generate hash for proposalId.
        bytes32 proposalId = _getProposalId(reward.priceIdentifier, timestamp, ancillaryData);

        // Request price from Optimistic Oracle.
        optimisticOracle.requestPrice(reward.priceIdentifier, timestamp, ancillaryData, bondToken, 0);

        // Set proposal liveness and bond and calculate total bond amount.
        optimisticOracle.setCustomLiveness(
            reward.priceIdentifier,
            timestamp,
            ancillaryData,
            reward.optimisticOracleLivenessTime
        );
        uint256 totalBond =
            optimisticOracle.setBond(
                reward.priceIdentifier,
                timestamp,
                ancillaryData,
                reward.optimisticOracleProposerBond
            );

        // Pull proposal bond and final fee from the proposer, and approve it for Optimistic Oracle.
        bondToken.safeTransferFrom(msg.sender, address(this), totalBond);
        bondToken.safeApprove(address(optimisticOracle), totalBond);

        // Propose canonical value representing "True"; i.e. the proposed distribution is valid.
        optimisticOracle.proposePriceFor(
            msg.sender,
            address(this),
            reward.priceIdentifier,
            timestamp,
            ancillaryData,
            int256(1e18)
        );

        // Store and log proposed distribution.
        proposals[proposalId] = Proposal({
            rewardIndex: rewardIndex,
            timestamp: timestamp,
            merkleRoot: merkleRoot,
            ipfsHash: ipfsHash
        });
        emit ProposalCreated(
            reward.sponsor,
            reward.rewardToken,
            rewardIndex,
            timestamp,
            reward.maximumRewardAmount,
            proposalId,
            merkleRoot,
            ipfsHash
        );
    }

    /**
     * @notice Allows any caller to execute distribution that has been validated by the Optimistic Oracle.
     * @param proposalId Hash for identifying existing rewards distribution proposal.
     * @dev Calling this for unresolved proposals will revert.
     */
    function executeDistribution(bytes32 proposalId) external nonReentrant() {
        // All valid proposals should have non-zero proposal timestamp.
        Proposal memory proposal = proposals[proposalId];
        require(proposal.timestamp != 0, "Invalid proposalId");

        // Only one validated proposal per reward can be executed for distribution.
        Reward memory reward = rewards[proposal.rewardIndex];
        require(!reward.distributionExecuted, "Reward already distributed");

        // Append reward index to ancillary data.
        bytes memory ancillaryData = _appendRewardIndex(proposal.rewardIndex, reward.customAncillaryData);

        // Get resolved price. Reverts if the request is not settled or settleable.
        int256 resolvedPrice =
            optimisticOracle.settleAndGetPrice(reward.priceIdentifier, proposal.timestamp, ancillaryData);

        // Transfer rewards to MerkleDistributor for accepted proposal and flag distributionExecuted.
        // This does not revert on rejected proposals so that disputer could receive back its bond and winning
        // in the same transaction when settleAndGetPrice is called above.
        if (resolvedPrice == 1e18) {
            rewards[proposal.rewardIndex].distributionExecuted = true;

            reward.rewardToken.safeApprove(address(merkleDistributor), reward.maximumRewardAmount);
            merkleDistributor.setWindow(
                reward.maximumRewardAmount,
                address(reward.rewardToken),
                proposal.merkleRoot,
                proposal.ipfsHash
            );
            emit RewardDistributed(
                reward.sponsor,
                reward.rewardToken,
                proposal.rewardIndex,
                reward.maximumRewardAmount,
                proposalId,
                proposal.merkleRoot,
                proposal.ipfsHash
            );
        }
        // ProposalRejected can be emitted multiple times whenever someone tries to execute the same rejected proposal.
        else emit ProposalRejected(proposal.rewardIndex, proposalId);
    }

    /********************************************
     *          MAINTENANCE FUNCTIONS           *
     ********************************************/

    /**
     * @notice Updates the address stored in this contract for the OptimisticOracle to the latest version set
     * in the Finder.
     * @dev There is no risk of leaving this function public for anyone to call as in all cases we want the address of
     * OptimisticOracle in this contract to map to the latest version in the Finder.
     */
    function syncUmaEcosystemParams() public nonReentrant() {
        optimisticOracle = _getOptimisticOracle();
        ancillaryBytesLimit = optimisticOracle.ancillaryBytesLimit();
    }

    /********************************************
     *            INTERNAL FUNCTIONS            *
     ********************************************/

    function _getOptimisticOracle() internal view returns (OptimisticOracleV2Interface) {
        return OptimisticOracleV2Interface(finder.getImplementationAddress(OracleInterfaces.OptimisticOracleV2));
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getCollateralWhitelist() internal view returns (AddressWhitelistInterface) {
        return AddressWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
    }

    function _appendRewardIndex(uint256 rewardIndex, bytes memory customAncillaryData)
        internal
        pure
        returns (bytes memory)
    {
        return AncillaryData.appendKeyValueUint(customAncillaryData, "rewardIndex", rewardIndex);
    }

    function _ancillaryDataWithinLimits(bytes memory customAncillaryData) internal view returns (bool) {
        // Since rewardIndex has variable length as string, it is not appended here and is assumed
        // to be included in ANCILLARY_BYTES_RESERVE.
        return
            optimisticOracle.stampAncillaryData(customAncillaryData, address(this)).length + ANCILLARY_BYTES_RESERVE <=
            ancillaryBytesLimit;
    }

    function _getProposalId(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(identifier, timestamp, ancillaryData));
    }

    // Returns true if there are no blocking proposals (eiter there were no prior proposals or they were disputed).
    function _noBlockingProposal(uint256 rewardIndex, Reward memory reward) internal view returns (bool) {
        // Valid proposal cannot have zero timestamp.
        if (reward.previousProposalTimestamp == 0) return true;

        bytes memory ancillaryData = _appendRewardIndex(rewardIndex, reward.customAncillaryData);
        OptimisticOracleV2Interface.Request memory blockingRequest =
            optimisticOracle.getRequest(
                address(this),
                reward.priceIdentifier,
                reward.previousProposalTimestamp,
                ancillaryData
            );

        // Previous proposal is blocking till disputed that can be detected by non-zero disputer address.
        // In case Optimistic Oracle was upgraded since the previous proposal it needs to be unblocked for new proposal.
        // This can be detected by uninitialized bonding currency for the previous proposal.
        return blockingRequest.disputer != address(0) || address(blockingRequest.currency) == address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Library for encoding and decoding ancillary data for DVM price requests.
 * @notice  We assume that on-chain ancillary data can be formatted directly from bytes to utf8 encoding via
 * web3.utils.hexToUtf8, and that clients will parse the utf8-encoded ancillary data as a comma-delimitted key-value
 * dictionary. Therefore, this library provides internal methods that aid appending to ancillary data from Solidity
 * smart contracts. More details on UMA's ancillary data guidelines below:
 * https://docs.google.com/document/d/1zhKKjgY1BupBGPPrY_WOJvui0B6DMcd-xDR8-9-SPDw/edit
 */
library AncillaryData {
    // This converts the bottom half of a bytes32 input to hex in a highly gas-optimized way.
    // Source: the brilliant implementation at https://gitter.im/ethereum/solidity?at=5840d23416207f7b0ed08c9b.
    function toUtf8Bytes32Bottom(bytes32 bytesIn) private pure returns (bytes32) {
        unchecked {
            uint256 x = uint256(bytesIn);

            // Nibble interleave
            x = x & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
            x = (x | (x * 2**64)) & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
            x = (x | (x * 2**32)) & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
            x = (x | (x * 2**16)) & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
            x = (x | (x * 2**8)) & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
            x = (x | (x * 2**4)) & 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;

            // Hex encode
            uint256 h = (x & 0x0808080808080808080808080808080808080808080808080808080808080808) / 8;
            uint256 i = (x & 0x0404040404040404040404040404040404040404040404040404040404040404) / 4;
            uint256 j = (x & 0x0202020202020202020202020202020202020202020202020202020202020202) / 2;
            x = x + (h & (i | j)) * 0x27 + 0x3030303030303030303030303030303030303030303030303030303030303030;

            // Return the result.
            return bytes32(x);
        }
    }

    /**
     * @notice Returns utf8-encoded bytes32 string that can be read via web3.utils.hexToUtf8.
     * @dev Will return bytes32 in all lower case hex characters and without the leading 0x.
     * This has minor changes from the toUtf8BytesAddress to control for the size of the input.
     * @param bytesIn bytes32 to encode.
     * @return utf8 encoded bytes32.
     */
    function toUtf8Bytes(bytes32 bytesIn) internal pure returns (bytes memory) {
        return abi.encodePacked(toUtf8Bytes32Bottom(bytesIn >> 128), toUtf8Bytes32Bottom(bytesIn));
    }

    /**
     * @notice Returns utf8-encoded address that can be read via web3.utils.hexToUtf8.
     * Source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string/8447#8447
     * @dev Will return address in all lower case characters and without the leading 0x.
     * @param x address to encode.
     * @return utf8 encoded address bytes.
     */
    function toUtf8BytesAddress(address x) internal pure returns (bytes memory) {
        return
            abi.encodePacked(toUtf8Bytes32Bottom(bytes32(bytes20(x)) >> 128), bytes8(toUtf8Bytes32Bottom(bytes20(x))));
    }

    /**
     * @notice Converts a uint into a base-10, UTF-8 representation stored in a `string` type.
     * @dev This method is based off of this code: https://stackoverflow.com/a/65707309.
     */
    function toUtf8BytesUint(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return "0";
        }
        uint256 j = x;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (x != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(x - (x / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        return bstr;
    }

    function appendKeyValueBytes32(
        bytes memory currentAncillaryData,
        bytes memory key,
        bytes32 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8Bytes(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is an address that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value An address to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueAddress(
        bytes memory currentAncillaryData,
        bytes memory key,
        address value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesAddress(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is a uint that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value A uint to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueUint(
        bytes memory currentAncillaryData,
        bytes memory key,
        uint256 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesUint(value));
    }

    /**
     * @notice Helper method that returns the left hand side of a "key:value" pair plus the colon ":" and a leading
     * comma "," if the `currentAncillaryData` is not empty. The return value is intended to be prepended as a prefix to
     * some utf8 value that is ultimately added to a comma-delimited, key-value dictionary.
     */
    function constructPrefix(bytes memory currentAncillaryData, bytes memory key) internal pure returns (bytes memory) {
        if (currentAncillaryData.length > 0) {
            return abi.encodePacked(",", key, ":");
        } else {
            return abi.encodePacked(key, ":");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    // These functions are intended to be used by child contracts to temporarily disable and re-enable the guard.
    // Intended use:
    // _startReentrantGuardDisabled();
    // ...
    // _endReentrantGuardDisabled();
    //
    // IMPORTANT: these should NEVER be used in a method that isn't inside a nonReentrant block. Otherwise, it's
    // possible to permanently lock your contract.
    function _startReentrantGuardDisabled() internal {
        _notEntered = true;
    }

    function _endReentrantGuardDisabled() internal {
        _notEntered = false;
    }
}

// This contract is taken from Uniswap's multi call implementation (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol)
// and was modified to be solidity 0.8 compatible. Additionally, the method was restricted to only work with msg.value
// set to 0 to avoid any nasty attack vectors on function calls that use value sent with deposits.
pragma solidity ^0.8.0;

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
contract MultiCaller {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        require(msg.value == 0, "Only multicall with 0 value");
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run in production, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface AddressWhitelistInterface {
    function addToWhitelist(address newElement) external;

    function removeFromWhitelist(address newElement) external;

    function isOnWhitelist(address newElement) external view returns (bool);

    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MerkleDistributorInterface.sol";

/**
 * Inspired by:
 * - https://github.com/pie-dao/vested-token-migration-app
 * - https://github.com/Uniswap/merkle-distributor
 * - https://github.com/balancer-labs/erc20-redeemable
 *
 * @title  MerkleDistributor contract.
 * @notice Allows an owner to distribute any reward ERC20 to claimants according to Merkle roots. The owner can specify
 *         multiple Merkle roots distributions with customized reward currencies.
 * @dev    The Merkle trees are not validated in any way, so the system assumes the contract owner behaves honestly.
 */
contract MerkleDistributor is MerkleDistributorInterface, Ownable {
    using SafeERC20 for IERC20;

    // Windows are mapped to arbitrary indices.
    mapping(uint256 => Window) public merkleWindows;

    // Index of next created Merkle root.
    uint256 public nextCreatedIndex;

    // Track which accounts have claimed for each window index.
    // Note: uses a packed array of bools for gas optimization on tracking certain claims. Copied from Uniswap's contract.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    /****************************************
     *                EVENTS
     ****************************************/
    event Claimed(
        address indexed caller,
        uint256 windowIndex,
        address indexed account,
        uint256 accountIndex,
        uint256 amount,
        address indexed rewardToken
    );
    event CreatedWindow(
        uint256 indexed windowIndex,
        uint256 rewardsDeposited,
        address indexed rewardToken,
        address owner
    );
    event WithdrawRewards(address indexed owner, uint256 amount, address indexed currency);
    event DeleteWindow(uint256 indexed windowIndex, address owner);

    /****************************
     *      ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Set merkle root for the next available window index and seed allocations.
     * @notice Callable only by owner of this contract. Caller must have approved this contract to transfer
     *      `rewardsToDeposit` amount of `rewardToken` or this call will fail. Importantly, we assume that the
     *      owner of this contract correctly chooses an amount `rewardsToDeposit` that is sufficient to cover all
     *      claims within the `merkleRoot`.
     * @param rewardsToDeposit amount of rewards to deposit to seed this allocation.
     * @param rewardToken ERC20 reward token.
     * @param merkleRoot merkle root describing allocation.
     * @param ipfsHash hash of IPFS object, conveniently stored for clients
     */
    function setWindow(
        uint256 rewardsToDeposit,
        address rewardToken,
        bytes32 merkleRoot,
        string calldata ipfsHash
    ) external onlyOwner {
        uint256 indexToSet = nextCreatedIndex;
        nextCreatedIndex = indexToSet + 1;

        _setWindow(indexToSet, rewardsToDeposit, rewardToken, merkleRoot, ipfsHash);
    }

    /**
     * @notice Delete merkle root at window index.
     * @dev Callable only by owner. Likely to be followed by a withdrawRewards call to clear contract state.
     * @param windowIndex merkle root index to delete.
     */
    function deleteWindow(uint256 windowIndex) external onlyOwner {
        delete merkleWindows[windowIndex];
        emit DeleteWindow(windowIndex, msg.sender);
    }

    /**
     * @notice Emergency method that transfers rewards out of the contract if the contract was configured improperly.
     * @dev Callable only by owner.
     * @param rewardCurrency rewards to withdraw from contract.
     * @param amount amount of rewards to withdraw.
     */
    function withdrawRewards(IERC20 rewardCurrency, uint256 amount) external onlyOwner {
        rewardCurrency.safeTransfer(msg.sender, amount);
        emit WithdrawRewards(msg.sender, amount, address(rewardCurrency));
    }

    /****************************
     *    NON-ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Batch claims to reduce gas versus individual submitting all claims. Method will fail
     *         if any individual claims within the batch would fail.
     * @dev    Optimistically tries to batch together consecutive claims for the same account and same
     *         reward token to reduce gas. Therefore, the most gas-cost-optimal way to use this method
     *         is to pass in an array of claims sorted by account and reward currency. It also reverts
     *         when any of individual `_claim`'s `amount` exceeds `remainingAmount` for its window.
     * @param claims array of claims to claim.
     */
    function claimMulti(Claim[] memory claims) public virtual override {
        uint256 batchedAmount;
        uint256 claimCount = claims.length;
        for (uint256 i = 0; i < claimCount; i++) {
            Claim memory _claim = claims[i];
            _verifyAndMarkClaimed(_claim);
            batchedAmount += _claim.amount;

            // If the next claim is NOT the same account or the same token (or this claim is the last one),
            // then disburse the `batchedAmount` to the current claim's account for the current claim's reward token.
            uint256 nextI = i + 1;
            IERC20 currentRewardToken = merkleWindows[_claim.windowIndex].rewardToken;
            if (
                nextI == claimCount ||
                // This claim is last claim.
                claims[nextI].account != _claim.account ||
                // Next claim account is different than current one.
                merkleWindows[claims[nextI].windowIndex].rewardToken != currentRewardToken
                // Next claim reward token is different than current one.
            ) {
                currentRewardToken.safeTransfer(_claim.account, batchedAmount);
                batchedAmount = 0;
            }
        }
    }

    /**
     * @notice Claim amount of reward tokens for account, as described by Claim input object.
     * @dev    If the `_claim`'s `amount`, `accountIndex`, and `account` do not exactly match the
     *         values stored in the merkle root for the `_claim`'s `windowIndex` this method
     *         will revert. It also reverts when `_claim`'s `amount` exceeds `remainingAmount` for the window.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     */
    function claim(Claim memory _claim) public virtual override {
        _verifyAndMarkClaimed(_claim);
        merkleWindows[_claim.windowIndex].rewardToken.safeTransfer(_claim.account, _claim.amount);
    }

    /**
     * @notice Returns True if the claim for `accountIndex` has already been completed for the Merkle root at
     *         `windowIndex`.
     * @dev    This method will only work as intended if all `accountIndex`'s are unique for a given `windowIndex`.
     *         The onus is on the Owner of this contract to submit only valid Merkle roots.
     * @param windowIndex merkle root to check.
     * @param accountIndex account index to check within window index.
     * @return True if claim has been executed already, False otherwise.
     */
    function isClaimed(uint256 windowIndex, uint256 accountIndex) public view returns (bool) {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        uint256 claimedWord = claimedBitMap[windowIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice Returns rewardToken set by admin for windowIndex.
     * @param windowIndex merkle root to check.
     * @return address Reward token address
     */
    function getRewardTokenForWindow(uint256 windowIndex) public view override returns (address) {
        return address(merkleWindows[windowIndex].rewardToken);
    }

    /**
     * @notice Returns True if leaf described by {account, amount, accountIndex} is stored in Merkle root at given
     *         window index.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     * @return valid True if leaf exists.
     */
    function verifyClaim(Claim memory _claim) public view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_claim.account, _claim.amount, _claim.accountIndex));
        return MerkleProof.verify(_claim.merkleProof, merkleWindows[_claim.windowIndex].merkleRoot, leaf);
    }

    /****************************
     *     PRIVATE FUNCTIONS
     ****************************/

    // Mark claim as completed for `accountIndex` for Merkle root at `windowIndex`.
    function _setClaimed(uint256 windowIndex, uint256 accountIndex) private {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        claimedBitMap[windowIndex][claimedWordIndex] =
            claimedBitMap[windowIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // Store new Merkle root at `windowindex`. Pull `rewardsDeposited` from caller to seed distribution for this root.
    function _setWindow(
        uint256 windowIndex,
        uint256 rewardsDeposited,
        address rewardToken,
        bytes32 merkleRoot,
        string memory ipfsHash
    ) private {
        Window storage window = merkleWindows[windowIndex];
        window.merkleRoot = merkleRoot;
        window.remainingAmount = rewardsDeposited;
        window.rewardToken = IERC20(rewardToken);
        window.ipfsHash = ipfsHash;

        emit CreatedWindow(windowIndex, rewardsDeposited, rewardToken, msg.sender);

        window.rewardToken.safeTransferFrom(msg.sender, address(this), rewardsDeposited);
    }

    // Verify claim is valid and mark it as completed in this contract.
    function _verifyAndMarkClaimed(Claim memory _claim) private {
        // Check claimed proof against merkle window at given index.
        require(verifyClaim(_claim), "Incorrect merkle proof");
        // Check the account has not yet claimed for this window.
        require(!isClaimed(_claim.windowIndex, _claim.accountIndex), "Account has already claimed for this window");

        // Proof is correct and claim has not occurred yet, mark claimed complete.
        _setClaimed(_claim.windowIndex, _claim.accountIndex);
        merkleWindows[_claim.windowIndex].remainingAmount -= _claim.amount;
        emit Claimed(
            msg.sender,
            _claim.windowIndex,
            _claim.account,
            _claim.accountIndex,
            _claim.amount,
            address(merkleWindows[_claim.windowIndex].rewardToken)
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant OptimisticOracleV2 = "OptimisticOracleV2";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FinderInterface.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleV2Interface {
    event RequestPrice(
        address indexed requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        address currency,
        uint256 reward,
        uint256 finalFee
    );
    event ProposePrice(
        address indexed requester,
        address indexed proposer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice,
        uint256 expirationTimestamp,
        address currency
    );
    event DisputePrice(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice
    );
    event Settle(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 price,
        uint256 payout
    );
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    struct RequestSettings {
        bool eventBased; // True if the request is set to be event-based.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
        bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
        bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        RequestSettings requestSettings; // Custom settings associated with a request.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    function defaultLiveness() external view virtual returns (uint256);

    function finder() external view virtual returns (FinderInterface);

    function getCurrentTime() external view virtual returns (uint256);

    // Note: this is required so that typechain generates a return value with named fields.
    mapping(bytes32 => Request) public requests;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Sets the request to be an "event-based" request.
     * @dev Calling this method has a few impacts on the request:
     *
     * 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
     *    with the request.
     *
     * 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
     *    prematurely proposes a response loses their bond.
     *
     * 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
     *    the requesting contract.
     *
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setEventBased(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets which callbacks should be enabled for the request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
     * @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
     * @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
     */
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external virtual;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    /**
     * @notice Returns the state of a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State enum value.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    function stampAncillaryData(bytes memory ancillaryData, address requester)
        public
        view
        virtual
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the currentTime variable set in the Timer.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Concise list of functions in MerkleDistributor implementation that would be called by
 * a consuming external contract (such as the Across Protocol's AcceleratingDistributor).
 */
interface MerkleDistributorInterface {
    // A Window maps a Merkle root to a reward token address.
    struct Window {
        // Merkle root describing the distribution.
        bytes32 merkleRoot;
        // Remaining amount of deposited rewards that have not yet been claimed.
        uint256 remainingAmount;
        // Currency in which reward is processed.
        IERC20 rewardToken;
        // IPFS hash of the merkle tree. Can be used to independently fetch recipient proofs and tree. Note that the canonical
        // data type for storing an IPFS hash is a multihash which is the concatenation of  <varint hash function code>
        // <varint digest size in bytes><hash function output>. We opted to store this in a string type to make it easier
        // for users to query the ipfs data without needing to reconstruct the multihash. to view the IPFS data simply
        // go to https://cloudflare-ipfs.com/ipfs/<IPFS-HASH>.
        string ipfsHash;
    }

    // Represents an account's claim for `amount` within the Merkle root located at the `windowIndex`.
    struct Claim {
        uint256 windowIndex;
        uint256 amount;
        uint256 accountIndex; // Used only for bitmap. Assumed to be unique for each claim.
        address account;
        bytes32[] merkleProof;
    }

    function claim(Claim memory _claim) external;

    function claimMulti(Claim[] memory claims) external;

    function getRewardTokenForWindow(uint256 windowIndex) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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