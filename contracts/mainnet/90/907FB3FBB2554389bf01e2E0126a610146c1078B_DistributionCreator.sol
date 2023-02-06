// SPDX-License-Identifier: GPL-3.0

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/external/uniswap/IUniswapV3Pool.sol";
import "./utils/UUPSHelper.sol";
import "./struct/DistributionParameters.sol";
import "./struct/ExtensiveDistributionParameters.sol";

/// @title DistributionCreator
/// @author Angle Labs, Inc.
/// @notice Manages the distribution of rewards across different UniswapV3 pools
/// @dev This contract is mostly a helper for APIs getting built on top and helping in Angle
/// UniswapV3 incentivization scheme
/// @dev People depositing rewards should have signed a `message` with the conditions for using the
/// product
contract DistributionCreator is UUPSHelper, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // =========================== CONSTANTS / VARIABLES ===========================

    /// @notice Epoch duration
    uint32 public constant EPOCH_DURATION = 3600;

    /// @notice Base for fee computation
    uint256 public constant BASE_9 = 1e9;

    /// @notice `CoreBorrow` contract handling access control
    ICoreBorrow public coreBorrow;

    /// @notice User contract for distributing rewards
    address public merkleRootDistributor;

    /// @notice Address to which fees will be forwarded
    address public feeRecipient;

    /// @notice Value (in base 10**9) of the fees taken when creating a distribution for a pool which do not
    /// have a whitelisted token in it
    uint256 public fees;

    /// @notice Message that needs to be acknowledged by users creating a distribution
    string public message;

    /// @notice Hash of the message that needs to be signed
    bytes32 public messageHash;

    /// @notice List of all rewards ever distributed or to be distributed in the contract
    /// @dev An attacker could try to populate this list. It shouldn't be an issue as only view functions
    /// iterate on it
    DistributionParameters[] public distributionList;

    /// @notice Maps an address to its fee rebate
    mapping(address => uint256) public feeRebate;

    /// @notice Maps a token to whether it is whitelisted or not. No fees are to be paid for incentives given
    /// on pools with whitelisted tokens
    mapping(address => uint256) public isWhitelistedToken;

    /// @notice Maps an address to its nonce for creating a distribution
    mapping(address => uint256) public nonces;

    /// @notice Maps an address to the last valid hash signed
    mapping(address => bytes32) public userSignatures;

    /// @notice Maps a user to whether it is whitelisted for not signing
    mapping(address => uint256) public userSignatureWhitelist;

    uint256[38] private __gap;

    // ============================== ERRORS / EVENTS ==============================

    event FeesSet(uint256 _fees);
    event FeeRecipientUpdated(address indexed _feeRecipient);
    event MerkleRootDistributorUpdated(address indexed _merkleRootDistributor);
    event MessageUpdated(bytes32 _messageHash);
    event NewDistribution(DistributionParameters distribution, address indexed sender);
    event FeeRebateUpdated(address indexed user, uint256 userFeeRebate);
    event TokenWhitelistToggled(address indexed token, uint256 toggleStatus);
    event UserSigned(bytes32 messageHash, address indexed user);
    event UserSigningWhitelistToggled(address indexed user, uint256 toggleStatus);

    // ================================== MODIFIER =================================

    /// @notice Checks whether the `msg.sender` has the governor role or the guardian role
    modifier onlyGovernorOrGuardian() {
        if (!coreBorrow.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Checks whether an address has signed the message or not
    modifier hasSigned() {
        if (userSignatureWhitelist[msg.sender] == 0 && userSignatures[msg.sender] != messageHash) revert NotSigned();
        _;
    }

    // ================================ CONSTRUCTOR ================================

    function initialize(
        ICoreBorrow _coreBorrow,
        address _merkleRootDistributor,
        uint256 _fees
    ) external initializer {
        if (address(_coreBorrow) == address(0) || _merkleRootDistributor == address(0)) revert ZeroAddress();
        if (_fees > BASE_9) revert InvalidParam();
        merkleRootDistributor = _merkleRootDistributor;
        coreBorrow = _coreBorrow;
        fees = _fees;
    }

    constructor() initializer {}

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override onlyGuardianUpgrader(coreBorrow) {}

    // ============================== DEPOSIT FUNCTION =============================

    /// @notice Creates a `distribution` to incentivize a given UniswapV3 pool for a specific period of time
    /// @return distributionAmount How many reward tokens are actually taken into consideration in the contract
    /// @dev It's important to make sure that the address specified as a UniV3 pool is effectively a pool
    /// otherwise they will not be handled by the distribution script and rewards may be lost
    /// @dev The `positionWrappers` specified in the `distribution` struct need to be supported by the script
    /// @dev If the pool incentivized contains agEUR, then no fees are taken on the rewards
    /// @dev This function will revert if the user has not signed the message `messageHash` once through one of
    /// the functions enabling to sign
    function createDistribution(DistributionParameters memory distribution)
        external
        hasSigned
        returns (uint256 distributionAmount)
    {
        return _createDistribution(distribution);
    }

    /// @notice Same as the function above but for multiple distributions at once
    /// @return List of all the distribution amounts actually deposited for each `distribution` in the `distributions` list
    function createDistributions(DistributionParameters[] memory distributions)
        external
        hasSigned
        returns (uint256[] memory)
    {
        uint256 distributionsLength = distributions.length;
        uint256[] memory distributionAmounts = new uint256[](distributionsLength);
        for (uint256 i; i < distributionsLength; ) {
            distributionAmounts[i] = _createDistribution(distributions[i]);
            unchecked {
                ++i;
            }
        }
        return distributionAmounts;
    }

    /// @notice Checks whether the `msg.sender`'s `signature` is compatible with the message
    /// to sign and stores the fact that signing was done
    /// @dev If you signed the message once, and the message has not been modified, then you do not
    /// need to sign again
    function sign(bytes calldata signature) external {
        _sign(signature);
    }

    /// @notice Combines signing the message and creating a distribution
    function signAndCreateDistribution(DistributionParameters memory distribution, bytes calldata signature)
        external
        returns (uint256 distributionAmount)
    {
        _sign(signature);
        return _createDistribution(distribution);
    }

    /// @notice Internal version of `createDistribution`
    function _createDistribution(DistributionParameters memory distribution)
        internal
        nonReentrant
        returns (uint256 distributionAmount)
    {
        uint32 epochStart = _getRoundedEpoch(distribution.epochStart);
        distribution.epochStart = epochStart;
        // Reward will not be accepted in the following conditions:
        if (
            // if epoch parameters would lead to a past distribution
            epochStart + EPOCH_DURATION < block.timestamp ||
            // if the amount of epochs for which this incentive should last is zero
            distribution.numEpoch == 0 ||
            // if the amount to use to incentivize is still 0
            distribution.amount == 0 ||
            // if the distribution parameters are not correctly specified
            distribution.propFees + distribution.propToken0 + distribution.propToken1 != 1e4 ||
            // if boosted addresses get less than non-boosted addresses in case of
            (distribution.boostingAddress != address(0) && distribution.boostedReward < 1e4) ||
            // if the type of the position wrappers is not well specified
            distribution.positionWrappers.length != distribution.wrapperTypes.length
        ) revert InvalidReward();
        distributionAmount = distribution.amount;
        // Computing fees: these are waived for whitelisted addresses and if there is a whitelisted token in a pool
        uint256 userFeeRebate = feeRebate[msg.sender];
        if (
            userFeeRebate < BASE_9 &&
            isWhitelistedToken[IUniswapV3Pool(distribution.uniV3Pool).token0()] == 0 &&
            isWhitelistedToken[IUniswapV3Pool(distribution.uniV3Pool).token1()] == 0
        ) {
            uint256 _fees = (fees * (BASE_9 - userFeeRebate)) / BASE_9;
            uint256 distributionAmountMinusFees = (distributionAmount * (BASE_9 - _fees)) / BASE_9;
            address _feeRecipient = feeRecipient;
            _feeRecipient = _feeRecipient == address(0) ? address(this) : _feeRecipient;
            IERC20(distribution.rewardToken).safeTransferFrom(
                msg.sender,
                _feeRecipient,
                distributionAmount - distributionAmountMinusFees
            );
            distributionAmount = distributionAmountMinusFees;
            distribution.amount = distributionAmount;
        }

        IERC20(distribution.rewardToken).safeTransferFrom(msg.sender, merkleRootDistributor, distributionAmount);
        uint256 senderNonce = nonces[msg.sender];
        nonces[msg.sender] = senderNonce + 1;
        distribution.rewardId = bytes32(keccak256(abi.encodePacked(msg.sender, senderNonce)));
        distributionList.push(distribution);
        emit NewDistribution(distribution, msg.sender);
    }

    /// @notice Internal version of the `sign` function
    function _sign(bytes calldata signature) internal {
        bytes32 _messageHash = messageHash;
        if (ECDSA.recover(_messageHash, signature) != msg.sender) revert InvalidSignature();
        userSignatures[msg.sender] = _messageHash;
        emit UserSigned(_messageHash, msg.sender);
    }

    // ================================= UI HELPERS ================================
    // These functions are not to be queried on-chain and hence are not optimized for gas consumption

    /// @notice Returns the list of all distributions ever distributed or to be distributed
    function getAllDistributions() external view returns (DistributionParameters[] memory) {
        return distributionList;
    }

    /// @notice Returns the list of all currently active distributions on UniswapV3 pool
    function getActiveDistributions() external view returns (ExtensiveDistributionParameters[] memory) {
        uint32 roundedEpoch = _getRoundedEpoch(uint32(block.timestamp));
        return _getPoolDistributionsBetweenEpochs(address(0), roundedEpoch, roundedEpoch + EPOCH_DURATION);
    }

    /// @notice Returns the list of all the distributions that were or that are going to be live at
    /// a specific epoch
    function getDistributionsForEpoch(uint32 epoch) external view returns (ExtensiveDistributionParameters[] memory) {
        uint32 roundedEpoch = _getRoundedEpoch(epoch);
        return _getPoolDistributionsBetweenEpochs(address(0), roundedEpoch, roundedEpoch + EPOCH_DURATION);
    }

    /// @notice Gets the distributions that were or will be live at some point between `epochStart` (included) and `epochEnd` (excluded)
    /// @dev If a distribution starts during `epochEnd`, it will not be returned by this function
    /// @dev Conversely, if a distribution starts after `epochStart` and ends before `epochEnd`, it will be returned by this function
    function getDistributionsBetweenEpochs(uint32 epochStart, uint32 epochEnd)
        external
        view
        returns (ExtensiveDistributionParameters[] memory)
    {
        return _getPoolDistributionsBetweenEpochs(address(0), _getRoundedEpoch(epochStart), _getRoundedEpoch(epochEnd));
    }

    /// @notice Returns the list of all distributions that were or will be live after `epochStart` (included)
    function getDistributionsAfterEpoch(uint32 epochStart)
        external
        view
        returns (ExtensiveDistributionParameters[] memory)
    {
        return _getPoolDistributionsBetweenEpochs(address(0), _getRoundedEpoch(epochStart), type(uint32).max);
    }

    /// @notice Returns the list of all currently active distributions for a specific UniswapV3 pool
    function getActivePoolDistributions(address uniV3Pool)
        external
        view
        returns (ExtensiveDistributionParameters[] memory)
    {
        uint32 roundedEpoch = _getRoundedEpoch(uint32(block.timestamp));
        return _getPoolDistributionsBetweenEpochs(uniV3Pool, roundedEpoch, roundedEpoch + EPOCH_DURATION);
    }

    /// @notice Returns the list of all the distributions that were or that are going to be live at a
    /// specific epoch and for a specific pool
    function getPoolDistributionsForEpoch(address uniV3Pool, uint32 epoch)
        external
        view
        returns (ExtensiveDistributionParameters[] memory)
    {
        uint32 roundedEpoch = _getRoundedEpoch(epoch);
        return _getPoolDistributionsBetweenEpochs(uniV3Pool, roundedEpoch, roundedEpoch + EPOCH_DURATION);
    }

    /// @notice Returns the list of all distributions that were or will be live between `epochStart` (included) and `epochEnd` (excluded)
    /// for a specific pool
    function getPoolDistributionsBetweenEpochs(
        address uniV3Pool,
        uint32 epochStart,
        uint32 epochEnd
    ) external view returns (ExtensiveDistributionParameters[] memory) {
        return _getPoolDistributionsBetweenEpochs(uniV3Pool, _getRoundedEpoch(epochStart), _getRoundedEpoch(epochEnd));
    }

    /// @notice Returns the list of all distributions that were or will be live after `epochStart` (included)
    /// for a specific pool
    function getPoolDistributionsAfterEpoch(address uniV3Pool, uint32 epochStart)
        external
        view
        returns (ExtensiveDistributionParameters[] memory)
    {
        return _getPoolDistributionsBetweenEpochs(uniV3Pool, _getRoundedEpoch(epochStart), type(uint32).max);
    }

    // ============================ GOVERNANCE FUNCTIONS ===========================

    /// @notice Sets a new `merkleRootDistributor` to which rewards should be distributed
    function setNewMerkleRootDistributor(address _merkleRootDistributor) external onlyGovernorOrGuardian {
        if (_merkleRootDistributor == address(0)) revert InvalidParam();
        merkleRootDistributor = _merkleRootDistributor;
        emit MerkleRootDistributorUpdated(_merkleRootDistributor);
    }

    /// @notice Sets the fees on deposit
    function setFees(uint256 _fees) external onlyGovernorOrGuardian {
        if (_fees >= BASE_9) revert InvalidParam();
        fees = _fees;
        emit FeesSet(_fees);
    }

    /// @notice Sets fee rebates for a given user
    function setUserFeeRebate(address user, uint256 userFeeRebate) external onlyGovernorOrGuardian {
        feeRebate[user] = userFeeRebate;
        emit FeeRebateUpdated(user, userFeeRebate);
    }

    /// @notice Toggles the fee whitelist for `token`
    function toggleTokenWhitelist(address token) external onlyGovernorOrGuardian {
        uint256 toggleStatus = 1 - isWhitelistedToken[token];
        isWhitelistedToken[token] = toggleStatus;
        emit TokenWhitelistToggled(token, toggleStatus);
    }

    /// @notice Recovers fees accrued on the contract for a list of `tokens`
    function recoverFees(IERC20[] calldata tokens, address to) external onlyGovernorOrGuardian {
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ) {
            tokens[i].safeTransfer(to, tokens[i].balanceOf(address(this)));
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sets a new address to receive fees
    function setFeeRecipient(address _feeRecipient) external onlyGovernorOrGuardian {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /// @notice Sets the message that needs to be signed by users before posting rewards
    function setMessage(string memory _message) external onlyGovernorOrGuardian {
        message = _message;
        bytes32 _messageHash = ECDSA.toEthSignedMessageHash(bytes(_message));
        messageHash = _messageHash;
        emit MessageUpdated(_messageHash);
    }

    /// @notice Toggles the whitelist status for `user` when it comes to signing messages before depositing
    /// rewards
    function toggleSigningWhitelist(address user) external onlyGovernorOrGuardian {
        uint256 whitelistStatus = 1 - userSignatureWhitelist[user];
        userSignatureWhitelist[user] = whitelistStatus;
        emit UserSigningWhitelistToggled(user, whitelistStatus);
    }

    // ============================== INTERNAL HELPERS =============================

    /// @notice Rounds an `epoch` timestamp to the start of the corresponding period
    function _getRoundedEpoch(uint32 epoch) internal pure returns (uint32) {
        return (epoch / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /// @notice Checks whether `distribution` was live between `roundedEpochStart` and `roundedEpochEnd`
    function _isDistributionLiveBetweenEpochs(
        DistributionParameters storage distribution,
        uint32 roundedEpochStart,
        uint32 roundedEpochEnd
    ) internal view returns (bool) {
        uint256 distributionEpochStart = distribution.epochStart;
        return (distributionEpochStart + distribution.numEpoch * EPOCH_DURATION > roundedEpochStart &&
            distributionEpochStart < roundedEpochEnd);
    }

    /// @notice Fetches data for `token` on the Uniswap `pool`
    function _getUniswapTokenData(IERC20Metadata token, address pool)
        internal
        view
        returns (UniswapTokenData memory data)
    {
        data.add = address(token);
        data.decimals = token.decimals();
        data.symbol = token.symbol();
        data.poolBalance = token.balanceOf(pool);
    }

    /// @notice Fetches extra data about the parameters in a distribution
    function _getExtensiveDistributionParameters(DistributionParameters memory distribution)
        internal
        view
        returns (ExtensiveDistributionParameters memory extensiveParams)
    {
        extensiveParams.base = distribution;
        extensiveParams.poolFee = IUniswapV3Pool(distribution.uniV3Pool).fee();
        extensiveParams.token0 = _getUniswapTokenData(
            IERC20Metadata(IUniswapV3Pool(distribution.uniV3Pool).token0()),
            distribution.uniV3Pool
        );
        extensiveParams.token1 = _getUniswapTokenData(
            IERC20Metadata(IUniswapV3Pool(distribution.uniV3Pool).token1()),
            distribution.uniV3Pool
        );
        extensiveParams.rewardTokenSymbol = IERC20Metadata(distribution.rewardToken).symbol();
        extensiveParams.rewardTokenDecimals = IERC20Metadata(distribution.rewardToken).decimals();
    }

    /// @notice Gets the list of all the distributions for `uniV3Pool` that have been active between `epochStart` and `epochEnd` (excluded)
    /// @dev If the `uniV3Pool` parameter is equal to 0, then this function will return the distributions for all pools
    function _getPoolDistributionsBetweenEpochs(
        address uniV3Pool,
        uint32 epochStart,
        uint32 epochEnd
    ) internal view returns (ExtensiveDistributionParameters[] memory) {
        uint256 length;
        uint256 distributionListLength = distributionList.length;
        DistributionParameters[] memory longActiveRewards = new DistributionParameters[](distributionListLength);
        for (uint32 i; i < distributionListLength; ) {
            DistributionParameters storage distribution = distributionList[i];
            if (
                _isDistributionLiveBetweenEpochs(distribution, epochStart, epochEnd) &&
                (uniV3Pool == address(0) || distribution.uniV3Pool == uniV3Pool)
            ) {
                longActiveRewards[length] = distribution;
                length += 1;
            }
            unchecked {
                ++i;
            }
        }

        ExtensiveDistributionParameters[] memory activeRewards = new ExtensiveDistributionParameters[](length);
        for (uint32 i; i < length; ) {
            activeRewards[i] = _getExtensiveDistributionParameters(longActiveRewards[i]);
            unchecked {
                ++i;
            }
        }
        return activeRewards;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}

// SPDX-License-Identifier: GPL-3.0

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/ICoreBorrow.sol";
import "../utils/Errors.sol";

/// @title UUPSHelper
/// @notice Helper contract for UUPSUpgradeable contracts where the upgradeability is controlled by a specific address
/// @author Angle Labs., Inc
/// @dev The 0 address check in the modifier allows the use of these modifiers during initalization
abstract contract UUPSHelper is UUPSUpgradeable {
    modifier onlyGuardianUpgrader(ICoreBorrow _coreBorrow) {
        if (address(_coreBorrow) != address(0) && !_coreBorrow.isGovernorOrGuardian(msg.sender))
            revert NotGovernorOrGuardian();
        _;
    }

    modifier onlyGovernorUpgrader(ICoreBorrow _coreBorrow) {
        if (address(_coreBorrow) != address(0) && !_coreBorrow.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    constructor() initializer {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/** 
* TODO: 
- Which helpers do we keep in the contract?
- Do we improve gas wise the rewards that are sent
 */
struct DistributionParameters {
    // ID of the reward (populated once created)
    bytes32 rewardId;
    // Address of the UniswapV3 pool that needs to be incentivized
    address uniV3Pool;
    // Address of the reward token for the incentives
    address rewardToken;
    // Amount of `rewardToken` to distribute
    uint256 amount;
    // List of all UniV3 position wrappers to consider for this contract
    // (this can include addresses of Arrakis or Gamma smart contracts for instance)
    address[] positionWrappers;
    // Type (Arrakis, Gamma, ...) encoded as a `uint32` for each wrapper in the list above. Mapping between wrapper types and their
    // corresponding `uint32` value can be found in Angle Docs
    uint32[] wrapperTypes;
    // In the incentivization formula, how much of the fees should go to holders of token0
    // in base 10**4
    uint32 propToken0;
    // Proportion for holding token1 (in base 10**4)
    uint32 propToken1;
    // Proportion for providing a useful liquidity (in base 10**4) that generates fees
    uint32 propFees;
    // Timestamp at which the incentivization should start
    uint32 epochStart;
    // Amount of epochs for which incentivization should last
    uint32 numEpoch;
    // Whether out of range liquidity should still be incentivized or not
    // This should be equal to 1 if out of range liquidity should still be incentivized
    // and 0 otherwise
    uint32 isOutOfRangeIncentivized;
    // How much more addresses with a maximum boost can get with respect to addresses
    // which do not have a boost (in base 4). In the case of Curve where addresses get 2.5x more
    // this would be 25000
    uint32 boostedReward;
    // Address of the token which dictates who gets boosted rewards or not. This is optional
    // and if the zero address is given no boost will be taken into account
    address boostingAddress;
    // Additional data passed when distributing rewards. This parameter may be used in case
    // the reward distribution script needs to look into other parameters beyond the ones above.
    bytes additionalData;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./DistributionParameters.sol";

struct UniswapTokenData {
    address add;
    uint8 decimals;
    string symbol;
    uint256 poolBalance;
}

struct ExtensiveDistributionParameters {
    DistributionParameters base;
    // Uniswap pool data
    uint24 poolFee;
    UniswapTokenData token0;
    UniswapTokenData token1;
    // rewardToken data
    string rewardTokenSymbol;
    uint8 rewardTokenDecimals;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title ICoreBorrow
/// @author Angle Core Team
/// @notice Interface for the `CoreBorrow` contract
/// @dev This interface only contains functions of the `CoreBorrow` contract which are called by other contracts
/// of this module
interface ICoreBorrow {
    /// @notice Checks if an address corresponds to a treasury of a stablecoin with a flash loan
    /// module initialized on it
    /// @param treasury Address to check
    /// @return Whether the address has the `FLASHLOANER_TREASURY_ROLE` or not
    function isFlashLoanerTreasury(address treasury) external view returns (bool);

    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

error InvalidDispute();
error InvalidLengths();
error InvalidParam();
error InvalidParams();
error InvalidProof();
error InvalidReward();
error InvalidSignature();
error NoDispute();
error NotGovernor();
error NotGovernorOrGuardian();
error NotSigned();
error NotTrusted();
error NotWhitelisted();
error UnresolvedDispute();
error ZeroAddress();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../DistributionCreator.sol";

/// @title MerklGaugeMiddleman
/// @author Angle Labs, Inc.
/// @notice Manages the transfer of rewards from the `AngleDistributor` to the `DistributionCreator` contract
/// @dev This contract is built under the assumption that the `DistributionCreator` contract has already whitelisted
/// this contract for it to distribute rewards without having to sign a message
/// @dev It also assumes that only `ANGLE` rewards will be sent from the `AngleDistributor`
contract MerklGaugeMiddleman {
    using SafeERC20 for IERC20;

    // ================================= PARAMETERS ================================

    /// @notice `CoreBorrow` contract handling access control
    ICoreBorrow public coreBorrow;

    /// @notice Maps a gauge to its reward parameters
    mapping(address => DistributionParameters) public gaugeParams;

    // =================================== EVENT ===================================

    event GaugeSet(address indexed gauge);

    constructor(ICoreBorrow _coreBorrow) {
        if (address(_coreBorrow) == address(0)) revert ZeroAddress();
        coreBorrow = _coreBorrow;
        IERC20 _angle = angle();
        // Condition left here for testing purposes
        if (address(_angle) != address(0))
            _angle.safeIncreaseAllowance(address(merkleRewardManager()), type(uint256).max);
    }

    // ================================= REFERENCES ================================

    /// @notice Address of the `AngleDistributor` contract
    function angleDistributor() public view virtual returns (address) {
        return 0x4f91F01cE8ec07c9B1f6a82c18811848254917Ab;
    }

    /// @notice Address of the ANGLE token
    function angle() public view virtual returns (IERC20) {
        return IERC20(0x31429d1856aD1377A8A0079410B297e1a9e214c2);
    }

    /// @notice Address of the Merkl contract managing rewards to be distributed
    // TODO: to be replaced at deployment
    function merkleRewardManager() public view virtual returns (DistributionCreator) {
        return DistributionCreator(0x4f91F01cE8ec07c9B1f6a82c18811848254917Ab);
    }

    // ============================= EXTERNAL FUNCTIONS ============================

    /// @notice Restores the allowance for the ANGLE token to the `DistributionCreator` contract
    function setAngleAllowance() external {
        IERC20 _angle = angle();
        address manager = address(merkleRewardManager());
        uint256 currentAllowance = _angle.allowance(address(this), manager);
        if (currentAllowance < type(uint256).max)
            _angle.safeIncreaseAllowance(manager, type(uint256).max - currentAllowance);
    }

    /// @notice Specifies the reward distribution parameters for `gauge`
    function setGauge(address gauge, DistributionParameters memory params) external {
        if (!coreBorrow.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        DistributionCreator manager = merkleRewardManager();
        if (
            gauge == address(0) ||
            params.rewardToken != address(angle()) ||
            (manager.isWhitelistedToken(IUniswapV3Pool(params.uniV3Pool).token0()) == 0 &&
                manager.isWhitelistedToken(IUniswapV3Pool(params.uniV3Pool).token0()) == 0)
        ) revert InvalidParams();
        gaugeParams[gauge] = params;
        emit GaugeSet(gauge);
    }

    /// @notice Transmits rewards from the `AngleDistributor` to the `DistributionCreator` with the correct
    /// parameters
    /// @dev Only callable by the `AngleDistributor` contract
    function notifyReward(address gauge, uint256 amount) external {
        DistributionParameters memory params = gaugeParams[gauge];
        if (msg.sender != angleDistributor() || params.uniV3Pool == address(0)) revert InvalidParams();
        params.epochStart = uint32(block.timestamp);
        params.amount = amount;
        merkleRewardManager().createDistribution(params);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "../middleman/MerklGaugeMiddleman.sol";

contract MockMerklGaugeMiddleman is MerklGaugeMiddleman {
    address public angleDistributorAddress;
    IERC20 public angleAddress;
    DistributionCreator public manager;

    constructor(ICoreBorrow _coreBorrow) MerklGaugeMiddleman(_coreBorrow) {}

    function angleDistributor() public view override returns (address) {
        return angleDistributorAddress;
    }

    function angle() public view override returns (IERC20) {
        return angleAddress;
    }

    function merkleRewardManager() public view override returns (DistributionCreator) {
        return manager;
    }

    function setAddresses(
        address _angleDistributorAddress,
        IERC20 _angleAddress,
        DistributionCreator _manager
    ) external {
        angleDistributorAddress = _angleDistributorAddress;
        angleAddress = _angleAddress;
        manager = _manager;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockTokenPermit is ERC20Permit {
    using SafeERC20 for IERC20;
    event Minting(address indexed _to, address indexed _minter, uint256 _amount);

    event Burning(address indexed _from, address indexed _burner, uint256 _amount);

    uint8 internal _decimal;
    mapping(address => bool) public minters;
    address public treasury;
    uint256 public fees;

    bool public reverts;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal_
    ) ERC20Permit(name_) ERC20(name_, symbol_) {
        _decimal = decimal_;
    }

    function decimals() public view override returns (uint8) {
        return _decimal;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
        emit Minting(account, msg.sender, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function setAllowance(address from, address to) public {
        _approve(from, to, type(uint256).max);
    }

    function burnSelf(uint256 amount, address account) public {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function addMinter(address minter) public {
        minters[minter] = true;
    }

    function removeMinter(address minter) public {
        minters[minter] = false;
    }

    function setTreasury(address _treasury) public {
        treasury = _treasury;
    }

    function setFees(uint256 _fees) public {
        fees = _fees;
    }

    function recoverERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external {
        token.safeTransfer(to, amount);
    }

    function swapIn(
        address bridgeToken,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(!reverts);

        IERC20(bridgeToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 canonicalOut = amount;
        canonicalOut -= (canonicalOut * fees) / 10**9;
        _mint(to, canonicalOut);
        return canonicalOut;
    }

    function swapOut(
        address bridgeToken,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(!reverts);
        _burn(msg.sender, amount);
        uint256 bridgeOut = amount;
        bridgeOut -= (bridgeOut * fees) / 10**9;
        IERC20(bridgeToken).safeTransfer(to, bridgeOut);
        return bridgeOut;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/CoreModuleInterfaces.sol";

import "../external/AccessControlUpgradeable.sol";

/// @title AngleDistributorEvents
/// @author Angle Core Team
/// @notice All the events used in `AngleDistributor` contract
contract AngleDistributorEvents {
    event DelegateGaugeUpdated(address indexed _gaugeAddr, address indexed _delegateGauge);
    event DistributionsToggled(bool _distributionsOn);
    event GaugeControllerUpdated(address indexed _controller);
    event GaugeToggled(address indexed gaugeAddr, bool newStatus);
    event InterfaceKnownToggled(address indexed _delegateGauge, bool _isInterfaceKnown);
    event RateUpdated(uint256 _newRate);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);
    event RewardDistributed(address indexed gaugeAddr, uint256 rewardTally);
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IAngleMiddlemanGauge
/// @author Angle Core Team
/// @notice Interface for the `AngleMiddleman` contract
interface IAngleMiddlemanGauge {
    function notifyReward(address gauge, uint256 amount) external;
}

interface IStakingRewards {
    function notifyRewardAmount(uint256 reward) external;
}

interface IGaugeController {
    //solhint-disable-next-line
    function gauge_types(address addr) external view returns (int128);

    //solhint-disable-next-line
    function gauge_relative_weight_write(address addr, uint256 timestamp) external returns (uint256);

    //solhint-disable-next-line
    function gauge_relative_weight(address addr, uint256 timestamp) external view returns (uint256);
}

interface ILiquidityGauge {
    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external {
        require(account == msg.sender, "71");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IAgToken.sol";
import "./ICoreBorrow.sol";

/// @title ITreasury
/// @author Angle Core Team
/// @notice Interface for the `Treasury` contract
/// @dev This interface only contains functions of the `Treasury` which are called by other contracts
/// of this module
interface ITreasury {
    /// @notice Stablecoin handled by this `treasury` contract
    function stablecoin() external view returns (IAgToken);

    /// @notice Checks whether a given address has the  governor role
    /// @param admin Address to check
    /// @return Whether the address has the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether a given address has the guardian or the governor role
    /// @param admin Address to check
    /// @return Whether the address has the guardian or the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract which means that this function
    /// queries the `CoreBorrow` contract
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IAgToken
/// @author Angle Core Team
/// @notice Interface for the stablecoins `AgToken` contracts
/// @dev This interface only contains functions of the `AgToken` contract which are called by other contracts
/// of this module or of the first module of the Angle Protocol
interface IAgToken is IERC20Upgradeable {
    // ======================= Minter Role Only Functions ===========================

    /// @notice Lets the `StableMaster` contract or another whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    /// @dev The contracts allowed to issue agTokens are the `StableMaster` contract, `VaultManager` contracts
    /// associated to this stablecoin as well as the flash loan module (if activated) and potentially contracts
    /// whitelisted by governance
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    // ========================= Treasury Only Functions ===========================

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    // ========================= External functions ================================

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasury.sol";

struct MerkleTree {
    // Root of a Merkle tree which leaves are (address user, address token, uint amount)
    // representing an amount of tokens owed to user.
    // The Merkle tree is assumed to have only increasing amounts: that is to say if a user can claim 1,
    // then after the amount associated in the Merkle tree for this token should be x > 1
    bytes32 merkleRoot;
    // Ipfs hash of the tree data
    bytes32 ipfsHash;
}

/// @title OldMerkleRootDistributor
/// @notice Old pre-upgrade version of the MerkleRootDistributor contract
/// @author Angle Core Team
contract OldMerkleRootDistributor is Initializable {
    using SafeERC20 for IERC20;

    /// @notice Tree of claimable tokens through this contract
    MerkleTree public tree;

    /// @notice Treasury contract handling access control
    ITreasury public treasury;

    /// @notice Mapping user -> token -> amount to track claimed amounts
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Trusted EOAs to update the merkle root
    mapping(address => uint256) public trusted;

    /// @notice Whether or not to enable permissionless claiming
    mapping(address => uint256) public whitelist;

    /// @notice user -> operator -> authorisation to claim
    mapping(address => mapping(address => uint256)) public operators;

    uint256[44] private __gap;

    // ================================== Events ===================================

    event TrustedToggled(address indexed eoa, bool trust);
    event Recovered(address indexed token, address indexed to, uint256 amount);
    event TreeUpdated(bytes32 merkleRoot, bytes32 ipfsHash);
    event Claimed(address user, address token, uint256 amount);
    event WhitelistToggled(address user, bool isEnabled);
    event OperatorToggled(address user, address operator, bool isWhitelisted);

    // ================================== Errors ===================================

    error InvalidLengths();
    error InvalidProof();
    error NotGovernorOrGuardian();
    error NotTrusted();
    error ZeroAddress();
    error NotWhitelisted();

    // ================================= Modifiers =================================

    /// @notice Checks whether the `msg.sender` has the governor role or the guardian role
    modifier onlyGovernorOrGuardian() {
        if (!treasury.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Checks whether the `msg.sender` is a trusted address to change the Merkle root of the contract
    modifier onlyTrusted() {
        if (!treasury.isGovernorOrGuardian(msg.sender) && trusted[msg.sender] != 1) revert NotTrusted();
        _;
    }

    // ============================ Constructor ====================================

    constructor() initializer {}

    function initialize(ITreasury _treasury) public initializer {
        if (address(_treasury) == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    // =========================== Main Function ===================================

    /// @notice Claims rewards for a given set of users
    /// @dev Anyone may call this function for anyone else, funds go to destination regardless, it's just a question of
    /// who provides the proof and pays the gas: `msg.sender` is not used in this function
    /// @param users Recipient of tokens
    /// @param tokens ERC20 claimed
    /// @param amounts Amount of tokens that will be sent to the corresponding users
    /// @param proofs Array of hashes bridging from leaf (hash of user | token | amount) to Merkle root
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) public {
        if (
            users.length == 0 ||
            users.length != tokens.length ||
            users.length != amounts.length ||
            users.length != proofs.length
        ) revert InvalidLengths();

        for (uint256 i; i < users.length; i++) {
            address user = users[i];
            address token = tokens[i];
            uint256 amount = amounts[i];

            // Check whitelist if needed
            if (whitelist[user] == 1 && operators[user][msg.sender] == 0) revert NotWhitelisted();

            // Verifying proof
            bytes32 leaf = keccak256(abi.encode(user, token, amount));
            if (!_verifyProof(leaf, proofs[i])) revert InvalidProof();

            // Closing reentrancy gate here
            uint256 toSend = amount - claimed[user][token];
            claimed[user][token] = amount;

            IERC20(token).safeTransfer(user, toSend);
            emit Claimed(user, token, toSend);
        }
    }

    // =========================== Governance Functions ============================

    /// @notice Pull reward amount from caller
    //solhint-disable-next-line
    function deposit_reward_token(IERC20 token, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Adds or removes trusted EOA
    function toggleTrusted(address eoa) external onlyGovernorOrGuardian {
        uint256 trustedStatus = 1 - trusted[eoa];
        trusted[eoa] = trustedStatus;
        emit TrustedToggled(eoa, trustedStatus == 1);
    }

    /// @notice Updates Merkle Tree
    function updateTree(MerkleTree calldata _tree) external onlyTrusted {
        tree = _tree;
        emit TreeUpdated(_tree.merkleRoot, _tree.ipfsHash);
    }

    /// @notice Toggles permissionless claiming for a given user
    function toggleWhitelist(address user) external {
        if (user != msg.sender && !treasury.isGovernorOrGuardian(msg.sender) && trusted[msg.sender] != 1)
            revert NotTrusted();
        whitelist[user] = 1 - whitelist[user];
        emit WhitelistToggled(user, whitelist[user] == 1);
    }

    /// @notice Toggles whitelisting for a given user and a given operator
    function toggleOperator(address user, address operator) external {
        if (user != msg.sender && !treasury.isGovernorOrGuardian(msg.sender) && trusted[msg.sender] != 1)
            revert NotTrusted();
        operators[user][operator] = 1 - operators[user][operator];
        emit OperatorToggled(user, operator, operators[user][operator] == 1);
    }

    /// @notice Recovers any ERC20 token
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyGovernorOrGuardian {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    // =========================== Internal Functions ==============================

    /// @notice Checks the validity of a proof
    /// @param leaf Hashed leaf data, the starting point of the proof
    /// @param proof Array of hashes forming a hash chain from leaf to root
    /// @return true If proof is correct, else false
    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;
        for (uint256 i; i < proof.length; i += 1) {
            if (currentHash < proof[i]) {
                currentHash = keccak256(abi.encode(currentHash, proof[i]));
            } else {
                currentHash = keccak256(abi.encode(proof[i], currentHash));
            }
        }
        return currentHash == tree.merkleRoot;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/UUPSHelper.sol";

struct MerkleTree {
    // Root of a Merkle tree which leaves are (address user, address token, uint amount)
    // representing an amount of tokens owed to user.
    // The Merkle tree is assumed to have only increasing amounts: that is to say if a user can claim 1,
    // then after the amount associated in the Merkle tree for this token should be x > 1
    bytes32 merkleRoot;
    // Ipfs hash of the tree data
    bytes32 ipfsHash;
}

/// @title Distributor
/// @notice Allows AMMs LPs to claim the rewards that were distributed to them
/// @author Angle Labs. Inc
/// @dev This contract relies on whitelisted or Angle-governance controlled addresses to update the Merkle root
/// for reward distribution. After each tree update, there is a dispute period, during which it is possible to
/// fallback to the old version of the Merkle root
contract Distributor is UUPSHelper {
    using SafeERC20 for IERC20;

    // ================================= VARIABLES =================================

    /// @notice Tree of claimable tokens through this contract
    MerkleTree public tree;

    /// @notice Tree that was in place in the contract before the last `tree` update
    MerkleTree public lastTree;

    /// @notice Token to deposit to freeze the roots update
    IERC20 public disputeToken;

    /// @notice `CoreBorrow` contract handling access control
    ICoreBorrow public coreBorrow;

    /// @notice Address which created the dispute
    /// @dev Used to store if there is an ongoing dispute
    address public disputer;

    /// @notice Last time the `tree` was updated
    uint48 public lastTreeUpdate;

    /// @notice Time before which a change in a tree becomes effective
    uint48 public disputePeriod;

    /// @notice Amount to deposit to freeze the roots update
    uint256 public disputeAmount;

    /// @notice Mapping user -> token -> amount to track claimed amounts
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Trusted EOAs to update the Merkle root
    mapping(address => uint256) public canUpdateMerkleRoot;

    /// @notice Whether or not to disable permissionless claiming
    mapping(address => uint256) public onlyOperatorCanClaim;

    /// @notice user -> operator -> authorisation to claim
    mapping(address => mapping(address => uint256)) public operators;

    uint256[38] private __gap;

    // =================================== EVENTS ==================================

    event Claimed(address user, address token, uint256 amount);
    event Disputed(string reason);
    event DisputePeriodUpdated(uint48 _disputePeriod);
    event DisputeTokenUpdated(address indexed _disputeToken);
    event DisputeAmountUpdated(uint256 _disputeAmount);
    event DisputeResolved(bool valid);
    event OperatorClaimingToggled(address user, bool isEnabled);
    event OperatorToggled(address user, address operator, bool isWhitelisted);
    event Recovered(address indexed token, address indexed to, uint256 amount);
    event TreeUpdated(bytes32 merkleRoot, bytes32 ipfsHash);
    event TrustedToggled(address indexed eoa, bool trust);

    // ================================= MODIFIERS =================================

    /// @notice Checks whether the `msg.sender` has the governor role or the guardian role
    modifier onlyGovernorOrGuardian() {
        if (!coreBorrow.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Checks whether the `msg.sender` is the `user` address or is a trusted address
    modifier onlyTrustedOrUser(address user) {
        if (user != msg.sender && canUpdateMerkleRoot[msg.sender] != 1 && !coreBorrow.isGovernorOrGuardian(msg.sender))
            revert NotTrusted();
        _;
    }

    // ================================ CONSTRUCTOR ================================

    constructor() initializer {}

    function initialize(ICoreBorrow _coreBorrow) external initializer {
        if (address(_coreBorrow) == address(0)) revert ZeroAddress();
        coreBorrow = _coreBorrow;
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override onlyGuardianUpgrader(coreBorrow) {}

    // =============================== MAIN FUNCTION ===============================

    /// @notice Claims rewards for a given set of users
    /// @dev Anyone may call this function for anyone else, funds go to destination regardless, it's just a question of
    /// who provides the proof and pays the gas: `msg.sender` is used only for addresses that require a trusted operator
    /// @param users Recipient of tokens
    /// @param tokens ERC20 claimed
    /// @param amounts Amount of tokens that will be sent to the corresponding users
    /// @param proofs Array of hashes bridging from leaf (hash of user | token | amount) to Merkle root
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        uint256 usersLength = users.length;
        if (
            usersLength == 0 ||
            usersLength != tokens.length ||
            usersLength != amounts.length ||
            usersLength != proofs.length
        ) revert InvalidLengths();

        for (uint256 i; i < usersLength; ) {
            address user = users[i];
            address token = tokens[i];
            uint256 amount = amounts[i];

            // Checking if only an approved operator can claim for `user`
            if (onlyOperatorCanClaim[user] == 1 && operators[user][msg.sender] == 0) revert NotWhitelisted();

            // Verifying proof
            bytes32 leaf = keccak256(abi.encode(user, token, amount));
            if (!_verifyProof(leaf, proofs[i])) revert InvalidProof();

            // Closing reentrancy gate here
            uint256 toSend = amount - claimed[user][token];
            claimed[user][token] = amount;

            IERC20(token).safeTransfer(user, toSend);
            emit Claimed(user, token, toSend);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the MerkleRoot that is currently live for the contract
    function getMerkleRoot() public view returns (bytes32) {
        if (block.timestamp - lastTreeUpdate >= disputePeriod) return tree.merkleRoot;
        else return lastTree.merkleRoot;
    }

    // ============================ GOVERNANCE FUNCTIONS ===========================

    /// @notice Adds or removes EOAs which are trusted to update the Merkle root
    function toggleTrusted(address eoa) external onlyGovernorOrGuardian {
        uint256 trustedStatus = 1 - canUpdateMerkleRoot[eoa];
        canUpdateMerkleRoot[eoa] = trustedStatus;
        emit TrustedToggled(eoa, trustedStatus == 1);
    }

    /// @notice Updates Merkle Tree
    function updateTree(MerkleTree calldata _tree) external {
        if (
            disputer != address(0) ||
            // A trusted address cannot update a tree right after a precedent tree update otherwise it can de facto
            // validate a tree which has not passed the dispute period
            ((canUpdateMerkleRoot[msg.sender] != 1 || block.timestamp - lastTreeUpdate < disputePeriod) &&
                !coreBorrow.isGovernorOrGuardian(msg.sender))
        ) revert NotTrusted();
        MerkleTree memory _lastTree = tree;
        tree = _tree;
        lastTree = _lastTree;
        lastTreeUpdate = uint48(block.timestamp);
        emit TreeUpdated(_tree.merkleRoot, _tree.ipfsHash);
    }

    /// @notice Freezes the Merkle tree update until the dispute is resolved
    /// @dev Requires a deposit of `disputeToken` that'll be slashed if the dispute is not accepted
    /// @dev It is only possible to create a dispute for `disputePeriod` after each tree update
    function disputeTree(string memory reason) external {
        if (block.timestamp - lastTreeUpdate >= disputePeriod) revert InvalidDispute();
        IERC20(disputeToken).safeTransferFrom(msg.sender, address(this), disputeAmount);
        disputer = msg.sender;
        emit Disputed(reason);
    }

    /// @notice Resolve the ongoing dispute, if any
    /// @param valid Whether the dispute was valid
    function resolveDispute(bool valid) external onlyGovernorOrGuardian {
        if (disputer == address(0)) revert NoDispute();
        if (valid) {
            IERC20(disputeToken).safeTransfer(disputer, disputeAmount);
            // If a dispute is valid, the contract falls back to the last tree that was updated
            _revokeTree();
        } else {
            IERC20(disputeToken).safeTransfer(msg.sender, disputeAmount);
            lastTreeUpdate = uint48(block.timestamp);
        }
        disputer = address(0);
        emit DisputeResolved(valid);
    }

    /// @notice Allows the governor or the guardian of this contract to fallback to the last version of the tree
    /// immediately
    function revokeTree() external onlyGovernorOrGuardian {
        if (disputer != address(0)) revert UnresolvedDispute();
        _revokeTree();
    }

    /// @notice Toggles permissioned claiming for a given user
    function toggleOnlyOperatorCanClaim(address user) external onlyTrustedOrUser(user) {
        onlyOperatorCanClaim[user] = 1 - onlyOperatorCanClaim[user];
        emit OperatorClaimingToggled(user, onlyOperatorCanClaim[user] == 1);
    }

    /// @notice Toggles whitelisting for a given user and a given operator
    function toggleOperator(address user, address operator) external onlyTrustedOrUser(user) {
        operators[user][operator] = 1 - operators[user][operator];
        emit OperatorToggled(user, operator, operators[user][operator] == 1);
    }

    /// @notice Recovers any ERC20 token
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyGovernorOrGuardian {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    /// @notice Sets the dispute period before which a tree update becomes effective
    function setDisputePeriod(uint48 _disputePeriod) external onlyGovernorOrGuardian {
        if (_disputePeriod > block.timestamp) revert InvalidParam();
        disputePeriod = uint48(_disputePeriod);
        emit DisputePeriodUpdated(_disputePeriod);
    }

    /// @notice Sets the token used as a caution during disputes
    function setDisputeToken(IERC20 _disputeToken) external onlyGovernorOrGuardian {
        if (disputer != address(0)) revert UnresolvedDispute();
        disputeToken = _disputeToken;
        emit DisputeTokenUpdated(address(_disputeToken));
    }

    /// @notice Sets the amount of `disputeToken` used as a caution during disputes
    function setDisputeAmount(uint256 _disputeAmount) external onlyGovernorOrGuardian {
        if (disputer != address(0)) revert UnresolvedDispute();
        disputeAmount = _disputeAmount;
        emit DisputeAmountUpdated(_disputeAmount);
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @notice Fallback to the last version of the tree
    function _revokeTree() internal {
        MerkleTree memory _tree = lastTree;
        lastTreeUpdate = 0;
        tree = _tree;
        emit TreeUpdated(_tree.merkleRoot, _tree.ipfsHash);
    }

    /// @notice Checks the validity of a proof
    /// @param leaf Hashed leaf data, the starting point of the proof
    /// @param proof Array of hashes forming a hash chain from leaf to root
    /// @return true If proof is correct, else false
    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;
        uint256 proofLength = proof.length;
        for (uint256 i; i < proofLength; ) {
            if (currentHash < proof[i]) {
                currentHash = keccak256(abi.encode(currentHash, proof[i]));
            } else {
                currentHash = keccak256(abi.encode(proof[i], currentHash));
            }
            unchecked {
                ++i;
            }
        }
        return currentHash == getMerkleRoot();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./AngleDistributorEvents.sol";

/// @title AngleDistributor
/// @author Forked from contracts developed by Curve and Frax and adapted by Angle Core Team
/// - ERC20CRV.vy (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/ERC20CRV.vy)
/// - FraxGaugeFXSRewardsDistributor.sol (https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Curve/FraxGaugeFXSRewardsDistributor.sol)
/// @notice All the events used in `AngleDistributor` contract
contract AngleDistributor is AngleDistributorEvents, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Role for governors only
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    /// @notice Role for the guardian
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Length of a week in seconds
    uint256 public constant WEEK = 3600 * 24 * 7;

    /// @notice Time at which the emission rate is updated
    uint256 public constant RATE_REDUCTION_TIME = WEEK;

    /// @notice Reduction of the emission rate
    uint256 public constant RATE_REDUCTION_COEFFICIENT = 1007827884862117171; // 1.5 ^ (1/52) * 10**18

    /// @notice Base used for computation
    uint256 public constant BASE = 10**18;

    /// @notice Maps the address of a gauge to the last time this gauge received rewards
    mapping(address => uint256) public lastTimeGaugePaid;

    /// @notice Maps the address of a gauge to whether it was killed or not
    /// A gauge killed in this contract cannot receive any rewards
    mapping(address => bool) public killedGauges;

    /// @notice Maps the address of a type >= 2 gauge to a delegate address responsible
    /// for giving rewards to the actual gauge
    mapping(address => address) public delegateGauges;

    /// @notice Maps the address of a gauge delegate to whether this delegate supports the `notifyReward` interface
    /// and is therefore built for automation
    mapping(address => bool) public isInterfaceKnown;

    /// @notice Address of the ANGLE token given as a reward
    IERC20 public rewardToken;

    /// @notice Address of the `GaugeController` contract
    IGaugeController public controller;

    /// @notice Address responsible for pulling rewards of type >= 2 gauges and distributing it to the
    /// associated contracts if there is not already an address delegated for this specific contract
    address public delegateGauge;

    /// @notice ANGLE current emission rate, it is first defined in the initializer and then updated every week
    uint256 public rate;

    /// @notice Timestamp at which the current emission epoch started
    uint256 public startEpochTime;

    /// @notice Amount of ANGLE tokens distributed through staking at the start of the epoch
    /// This is an informational variable used to track how much has been distributed through liquidity mining
    uint256 public startEpochSupply;

    /// @notice Index of the current emission epoch
    /// Here also, this variable is not useful per se inside the smart contracts of the protocol, it is
    /// just an informational variable
    uint256 public miningEpoch;

    /// @notice Whether ANGLE distribution through this contract is on or no
    bool public distributionsOn;

    /// @notice Constructor of the contract
    /// @param _rewardToken Address of the ANGLE token
    /// @param _controller Address of the GaugeController
    /// @param _initialRate Initial ANGLE emission rate
    /// @param _startEpochSupply Amount of ANGLE tokens already distributed via liquidity mining
    /// @param governor Governor address of the contract
    /// @param guardian Address of the guardian of this contract
    /// @param _delegateGauge Address that will be used to pull rewards for type 2 gauges
    /// @dev After this contract is created, the correct amount of ANGLE tokens should be transferred to the contract
    /// @dev The `_delegateGauge` can be the zero address
    function initialize(
        address _rewardToken,
        address _controller,
        uint256 _initialRate,
        uint256 _startEpochSupply,
        address governor,
        address guardian,
        address _delegateGauge
    ) external initializer {
        require(
            _controller != address(0) && _rewardToken != address(0) && guardian != address(0) && governor != address(0),
            "0"
        );
        rewardToken = IERC20(_rewardToken);
        controller = IGaugeController(_controller);
        startEpochSupply = _startEpochSupply;
        miningEpoch = 0;
        // Some ANGLE tokens should be sent to the contract directly after initialization
        rate = _initialRate;
        delegateGauge = _delegateGauge;
        distributionsOn = false;
        startEpochTime = block.timestamp;
        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);
        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(GOVERNOR_ROLE, governor);
        _setupRole(GUARDIAN_ROLE, governor);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ======================== Internal Functions =================================

    /// @notice Internal function to distribute rewards to a gauge
    /// @param gaugeAddr Address of the gauge to distribute rewards to
    /// @return weeksElapsed Weeks elapsed since the last call
    /// @return rewardTally Amount of rewards distributed to the gauge
    /// @dev The reason for having an internal function is that it's called by the `distributeReward` and the
    /// `distributeRewardToMultipleGauges`
    /// @dev Although they would need to be performed all the time this function is called, this function does not
    /// contain checks on whether distribution is on, and on whether rate should be reduced. These are done in each external
    /// function calling this function for gas efficiency
    function _distributeReward(address gaugeAddr) internal returns (uint256 weeksElapsed, uint256 rewardTally) {
        // Checking if the gauge has been added or if it still possible to distribute rewards to this gauge
        int128 gaugeType = IGaugeController(controller).gauge_types(gaugeAddr);
        require(gaugeType >= 0 && !killedGauges[gaugeAddr], "110");

        // Calculate the elapsed time in weeks.
        uint256 lastTimePaid = lastTimeGaugePaid[gaugeAddr];

        // Edge case for first reward for this gauge
        if (lastTimePaid == 0) {
            weeksElapsed = 1;
            if (gaugeType == 0) {
                // We give a full approval for the gauges with type zero which correspond to the staking
                // contracts of the protocol
                rewardToken.safeApprove(gaugeAddr, type(uint256).max);
            }
        } else {
            // Truncation desired
            weeksElapsed = (block.timestamp - lastTimePaid) / WEEK;
            // Return early here for 0 weeks instead of throwing, as it could have bad effects in other contracts
            if (weeksElapsed == 0) {
                return (0, 0);
            }
        }
        rewardTally = 0;
        // We use this variable to keep track of the emission rate across different weeks
        uint256 weeklyRate = rate;
        for (uint256 i = 0; i < weeksElapsed; i++) {
            uint256 relWeightAtWeek;
            if (i == 0) {
                // Mutative, for the current week: makes sure the weight is checkpointed. Also returns the weight.
                relWeightAtWeek = controller.gauge_relative_weight_write(gaugeAddr, block.timestamp);
            } else {
                // View
                relWeightAtWeek = controller.gauge_relative_weight(gaugeAddr, (block.timestamp - WEEK * i));
            }
            rewardTally += (weeklyRate * relWeightAtWeek * WEEK) / BASE;

            // To get the rate of the week prior from the current rate we just have to multiply by the weekly division
            // factor
            // There may be some precisions error: inferred previous values of the rate may be different to what we would
            // have had if the rate had been computed correctly in these weeks: we expect from empirical observations
            // this `weeklyRate` to be inferior to what the `rate` would have been
            weeklyRate = (weeklyRate * RATE_REDUCTION_COEFFICIENT) / BASE;
        }

        // Update the last time paid, rounded to the closest week
        // in order not to have an ever moving time on when to call this function
        lastTimeGaugePaid[gaugeAddr] = (block.timestamp / WEEK) * WEEK;

        // If the `gaugeType >= 2`, this means that the gauge is a gauge on another chain (and corresponds to tokens
        // that need to be bridged) or is associated to an external contract of the Angle Protocol
        if (gaugeType >= 2) {
            // If it is defined, we use the specific delegate attached to the gauge
            address delegate = delegateGauges[gaugeAddr];
            if (delegate == address(0)) {
                // If not, we check if a delegate common to all gauges with type >= 2 can be used
                delegate = delegateGauge;
            }
            if (delegate != address(0)) {
                _sendDelegateRewards(gaugeAddr, delegate, rewardTally);
            } else {
                rewardToken.safeTransfer(gaugeAddr, rewardTally);
            }
        } else if (gaugeType == 1) {
            // This is for the case of Perpetual contracts which need to be able to receive their reward tokens
            rewardToken.safeTransfer(gaugeAddr, rewardTally);
            IStakingRewards(gaugeAddr).notifyRewardAmount(rewardTally);
        } else {
            // Potentially override the gauge address
            address delegate = delegateGauges[gaugeAddr];
            if (delegate != address(0)) {
                _sendDelegateRewards(gaugeAddr, delegate, rewardTally);
            } else {
                ILiquidityGauge(gaugeAddr).deposit_reward_token(address(rewardToken), rewardTally);
            }
        }
        emit RewardDistributed(gaugeAddr, rewardTally);
    }

    /// @notice Helper to send `rewardTally` for `gaugeAddr` to the non zero `delegate` address
    function _sendDelegateRewards(
        address gaugeAddr,
        address delegate,
        uint256 rewardTally
    ) internal {
        rewardToken.safeTransfer(delegate, rewardTally);
        // If this delegate supports a specific interface, then rewards sent are notified through this
        // interface
        if (isInterfaceKnown[delegate]) {
            IAngleMiddlemanGauge(delegate).notifyReward(gaugeAddr, rewardTally);
        }
    }

    /// @notice Updates mining rate and supply at the start of the epoch
    /// @dev Any modifying mining call must also call this
    /// @dev It is possible that more than one week past between two calls of this function, and for this reason
    /// this function has been slightly modified from Curve implementation by Angle Team
    function _updateMiningParameters() internal {
        // When entering this function, we always have: `(block.timestamp - startEpochTime) / RATE_REDUCTION_TIME >= 1`
        uint256 epochDelta = (block.timestamp - startEpochTime) / RATE_REDUCTION_TIME;

        // Storing intermediate values for the rate and for the `startEpochSupply`
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += RATE_REDUCTION_TIME * epochDelta;
        miningEpoch += epochDelta;

        for (uint256 i = 0; i < epochDelta; i++) {
            // Updating the intermediate values of the `startEpochSupply`
            _startEpochSupply += _rate * RATE_REDUCTION_TIME;
            _rate = (_rate * BASE) / RATE_REDUCTION_COEFFICIENT;
        }
        rate = _rate;
        startEpochSupply = _startEpochSupply;
        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }

    /// @notice Toggles the fact that a gauge delegate can be used for automation or not and therefore supports
    /// the `notifyReward` interface
    /// @param _delegateGauge Address of the gauge to change
    function _toggleInterfaceKnown(address _delegateGauge) internal {
        bool isInterfaceKnownMem = isInterfaceKnown[_delegateGauge];
        isInterfaceKnown[_delegateGauge] = !isInterfaceKnownMem;
        emit InterfaceKnownToggled(_delegateGauge, !isInterfaceKnownMem);
    }

    // ================= Permissionless External Functions =========================

    /// @notice Distributes rewards to a staking contract (also called gauge)
    /// @param gaugeAddr Address of the gauge to send tokens too
    /// @return weeksElapsed Number of weeks elapsed since the last time rewards were distributed
    /// @return rewardTally Amount of tokens sent to the gauge
    /// @dev Anyone can call this function to distribute rewards to the different staking contracts
    function distributeReward(address gaugeAddr) external nonReentrant returns (uint256, uint256) {
        // Checking if distribution is on
        require(distributionsOn == true, "109");
        // Updating rate distribution parameters if need be
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();
        }
        return _distributeReward(gaugeAddr);
    }

    /// @notice Distributes rewards to multiple staking contracts
    /// @param gauges Addresses of the gauge to send tokens too
    /// @dev Anyone can call this function to distribute rewards to the different staking contracts
    /// @dev Compared with the `distributeReward` function, this function sends rewards to multiple
    /// contracts at the same time
    function distributeRewardToMultipleGauges(address[] memory gauges) external nonReentrant {
        // Checking if distribution is on
        require(distributionsOn == true, "109");
        // Updating rate distribution parameters if need be
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();
        }
        for (uint256 i = 0; i < gauges.length; i++) {
            _distributeReward(gauges[i]);
        }
    }

    /// @notice Updates mining rate and supply at the start of the epoch
    /// @dev Callable by any address, but only once per epoch
    function updateMiningParameters() external {
        require(block.timestamp >= startEpochTime + RATE_REDUCTION_TIME, "108");
        _updateMiningParameters();
    }

    // ========================= Governor Functions ================================

    /// @notice Withdraws ERC20 tokens that could accrue on this contract
    /// @param tokenAddress Address of the ERC20 token to withdraw
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @dev Added to support recovering LP Rewards and other mistaken tokens
    /// from other systems to be distributed to holders
    /// @dev This function could also be used to recover ANGLE tokens in case the rate got smaller
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        // If the token is the ANGLE token, we need to make sure that governance is not going to withdraw
        // too many tokens and that it'll be able to sustain the weekly distribution forever
        // This check assumes that `distributeReward` has been called for gauges and that there are no gauges
        // which have not received their past week's rewards
        if (tokenAddress == address(rewardToken)) {
            uint256 currentBalance = rewardToken.balanceOf(address(this));
            // The amount distributed till the end is `rate * WEEK / (1 - RATE_REDUCTION_FACTOR)` where
            // `RATE_REDUCTION_FACTOR = BASE / RATE_REDUCTION_COEFFICIENT` which translates to:
            require(
                currentBalance >=
                    ((rate * RATE_REDUCTION_COEFFICIENT) * WEEK) / (RATE_REDUCTION_COEFFICIENT - BASE) + amount,
                "4"
            );
        }
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit Recovered(tokenAddress, to, amount);
    }

    /// @notice Sets a new gauge controller
    /// @param _controller Address of the new gauge controller
    function setGaugeController(address _controller) external onlyRole(GOVERNOR_ROLE) {
        require(_controller != address(0), "0");
        controller = IGaugeController(_controller);
        emit GaugeControllerUpdated(_controller);
    }

    /// @notice Sets a new delegate gauge for pulling rewards of a type >= 2 gauges or of all type >= 2 gauges
    /// @param gaugeAddr Gauge to change the delegate of
    /// @param _delegateGauge Address of the new gauge delegate related to `gaugeAddr`
    /// @param toggleInterface Whether we should toggle the fact that the `_delegateGauge` is built for automation or not
    /// @dev This function can be used to remove delegating or introduce the pulling of rewards to a given address
    /// @dev If `gaugeAddr` is the zero address, this function updates the delegate gauge common to all gauges with type >= 2
    /// @dev The `toggleInterface` parameter has been added for convenience to save one transaction when adding a gauge delegate
    /// which supports the `notifyReward` interface
    function setDelegateGauge(
        address gaugeAddr,
        address _delegateGauge,
        bool toggleInterface
    ) external onlyRole(GOVERNOR_ROLE) {
        if (gaugeAddr != address(0)) {
            delegateGauges[gaugeAddr] = _delegateGauge;
        } else {
            delegateGauge = _delegateGauge;
        }
        emit DelegateGaugeUpdated(gaugeAddr, _delegateGauge);

        if (toggleInterface) {
            _toggleInterfaceKnown(_delegateGauge);
        }
    }

    /// @notice Changes the ANGLE emission rate
    /// @param _newRate New ANGLE emission rate
    /// @dev It is important to be super wary when calling this function and to make sure that `distributeReward`
    /// has been called for all gauges in the past weeks. If not, gauges may get an incorrect distribution of ANGLE rewards
    /// for these past weeks based on the new rate and not on the old rate
    /// @dev Governance should thus make sure to call this function rarely and when it does to do it after the weekly `distributeReward`
    /// calls for all existing gauges
    /// @dev As this function assumes that `distributeReward` has been called during the week, it also assumes that the `startEpochSupply`
    /// parameter has been put up to date
    function setRate(uint256 _newRate) external onlyRole(GOVERNOR_ROLE) {
        // Checking if the new rate is compatible with the amount of ANGLE tokens this contract has in balance
        // This check assumes, like this function, that `distributeReward` has correctly been called before
        require(
            rewardToken.balanceOf(address(this)) >=
                ((_newRate * RATE_REDUCTION_COEFFICIENT) * WEEK) / (RATE_REDUCTION_COEFFICIENT - BASE),
            "4"
        );
        rate = _newRate;
        emit RateUpdated(_newRate);
    }

    /// @notice Toggles the status of a gauge to either killed or unkilled
    /// @param gaugeAddr Gauge to toggle the status of
    /// @dev It is impossible to kill a gauge in the `GaugeController` contract, for this reason killing of gauges
    /// takes place in the `AngleDistributor` contract
    /// @dev This means that people could vote for a gauge in the gauge controller contract but that rewards are not going
    /// to be distributed to it in the end: people would need to remove their weights on the gauge killed to end the diminution
    /// in rewards
    /// @dev In the case of a gauge being killed, this function resets the timestamps at which this gauge has been approved and
    /// disapproves the gauge to spend the token
    /// @dev It should be cautiously called by governance as it could result in less ANGLE overall rewards than initially planned
    /// if people do not remove their voting weights to the killed gauge
    function toggleGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
        bool gaugeKilledMem = killedGauges[gaugeAddr];
        if (!gaugeKilledMem) {
            delete lastTimeGaugePaid[gaugeAddr];
            rewardToken.safeApprove(gaugeAddr, 0);
        }
        killedGauges[gaugeAddr] = !gaugeKilledMem;
        emit GaugeToggled(gaugeAddr, !gaugeKilledMem);
    }

    // ========================= Guardian Function =================================

    /// @notice Halts or activates distribution of rewards
    function toggleDistributions() external onlyRole(GUARDIAN_ROLE) {
        bool distributionsOnMem = distributionsOn;
        distributionsOn = !distributionsOnMem;
        emit DistributionsToggled(!distributionsOnMem);
    }

    /// @notice Notifies that the interface of a gauge delegate is known or has changed
    /// @param _delegateGauge Address of the gauge to change
    /// @dev Gauge delegates that are built for automation should be toggled
    function toggleInterfaceKnown(address _delegateGauge) external onlyRole(GUARDIAN_ROLE) {
        _toggleInterfaceKnown(_delegateGauge);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 * This contract was fully forked from OpenZeppelin `ProxyAdmin`
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{ value: msg.value }(implementation, data);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin. It is fully forked from OpenZeppelin
 * `TransparentUpgradeableProxy`
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    event Minting(address indexed _to, address indexed _minter, uint256 _amount);

    event Burning(address indexed _from, address indexed _burner, uint256 _amount);

    uint8 internal _decimal;
    mapping(address => bool) public minters;
    address public treasury;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal_
    ) ERC20(name_, symbol_) {
        _decimal = decimal_;
    }

    function decimals() public view override returns (uint8) {
        return _decimal;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
        emit Minting(account, msg.sender, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function setAllowance(address from, address to) public {
        _approve(from, to, type(uint256).max);
    }

    function burnSelf(uint256 amount, address account) public {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function addMinter(address minter) public {
        minters[minter] = true;
    }

    function removeMinter(address minter) public {
        minters[minter] = false;
    }

    function setTreasury(address _treasury) public {
        treasury = _treasury;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

/// @title Router for price estimation functionality
/// @notice Functions for getting the price of one token with respect to another using Uniswap V2
/// @dev This interface is only used for non critical elements of the protocol
interface IUniswapV2Router {
    /// @notice Given an input asset amount, returns the maximum output amount of the
    /// other asset (accounting for fees) given reserves.
    /// @param path Addresses of the pools used to get prices
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 swapAmount,
        uint256 minExpected,
        address[] calldata path,
        address receiver,
        uint256 swapDeadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract MockCoreBorrow {
    mapping(address => bool) public governors;
    mapping(address => bool) public guardians;

    function isGovernor(address admin) external view returns (bool) {
        return governors[admin];
    }

    function isGovernorOrGuardian(address admin) external view returns (bool) {
        return governors[admin] || guardians[admin];
    }

    function toggleGovernor(address admin) external {
        governors[admin] = !governors[admin];
    }

    function toggleGuardian(address admin) external {
        guardians[admin] = !guardians[admin];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract MockTreasury {
    address public stablecoin;
    address public governor;
    address public guardian;
    address public vaultManager1;
    address public vaultManager2;
    address public flashLoanModule;

    constructor(
        address _stablecoin,
        address _governor,
        address _guardian,
        address _vaultManager1,
        address _vaultManager2,
        address _flashLoanModule
    ) {
        stablecoin = _stablecoin;
        governor = _governor;
        guardian = _guardian;
        vaultManager1 = _vaultManager1;
        vaultManager2 = _vaultManager2;
        flashLoanModule = _flashLoanModule;
    }

    function isGovernor(address admin) external view returns (bool) {
        return (admin == governor);
    }

    function isGovernorOrGuardian(address admin) external view returns (bool) {
        return (admin == governor || admin == guardian);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint32 public constant EPOCH_DURATION = 3600;
    uint256 public fee;

    function setToken(address token, uint256 who) external {
        if (who == 0) token0 = token;
        else token1 = token;
    }

    function round(uint256 amount) external pure returns (uint256) {
        return (amount / EPOCH_DURATION) * EPOCH_DURATION;
    }
}