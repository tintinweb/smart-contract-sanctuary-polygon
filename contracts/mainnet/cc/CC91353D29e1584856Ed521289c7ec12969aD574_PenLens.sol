// SPDX-License-Identifier: MITsolid
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ProxyImplementation.sol";
import "hardhat/console.sol";

import "./interfaces/IMultiRewards.sol";
import "./interfaces/IPen.sol";
import "./interfaces/IPenV1Redeem.sol";
import "./interfaces/IPenV1Rewards.sol";
import "./interfaces/IPenLens.sol";
import "./interfaces/IPenDyst.sol";
import "./interfaces/IPenPool.sol";
import "./interfaces/IPenPoolFactory.sol";
import "./interfaces/IDyst.sol";
import "./interfaces/IDystopiaLens.sol";
import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyFactory.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IVlPen.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IVotingSnapshot.sol";
import "./interfaces/IPartnersRewards.sol";
import "./interfaces/ITokensAllowlist.sol";

/**
 * @title Primary view interface for protocol
 * @author Penrose
 * @dev This is the main contract used by the front-end to read protocol and user position data
 * @dev Other protocol contracts also use oxLens as a primary source of truth
 * @dev All data in this contract is read-only
 */
contract PenLens is ProxyImplementation {
    /*******************************************************
     *                     Configuration
     *******************************************************/

    // Public addresses
    address public gaugesFactoryAddress;
    address public minterAddress;
    address public penPoolFactoryAddress;
    address public penAddress;
    address public penDystAddress;
    address public penDystRewardsPoolAddress;
    address public partnersRewardsPoolAddress;
    address public poolsFactoryAddress;
    address public rewardsDistributorAddress;
    address public dystAddress;
    address public dystopiaLensAddress;
    address public treasuryAddress;
    address public userProxyFactoryAddress;
    address public userProxyInterfaceAddress;
    address public veAddress;
    address public vlPenAddress;
    address public voterProxyAddress;
    address public voterAddress;
    address public votingSnapshotAddress;
    address public penV1RewardsAddress;
    address public penV1RedeemAddress;
    address public penV1Address;
    address public tokensAllowlistAddress;

    /**
     * Interface helpers --these are also user facing, however they are only meant to be consumed
     * by other contracts and are provided as a convenience. In most cases interfaces are kept as internal.
     */
    IMultiRewards public penDystRewardsPool;
    IPen public pen;
    IVlPen public vlPen;
    IPenPoolFactory public penPoolFactory;
    IPenDyst public penDyst;
    IDyst public dyst;
    IDystopiaLens public dystopiaLens;
    IUserProxyFactory public userProxyFactory;
    IVe public ve;
    IVoterProxy public voterProxy;
    IVotingSnapshot public votingSnapshot;
    ITokensAllowlist public tokensAllowlist;

    // Migration pool mapping
    mapping(address => address) public penPoolsMigrationMapping;

    // Modifiers
    modifier onlyTreasury() {
        require(msg.sender == treasuryAddress, "Only treasury");
        _;
    }

    // Structs
    struct PenPoolData {
        address id;
        address stakingAddress;
        uint256 stakedTotalSupply;
        uint256 totalSupply;
        IDystopiaLens.Pool poolData;
    }
    struct ProtocolAddresses {
        address penPoolFactoryAddress;
        address dystopiaLensAddress;
        address penAddress;
        address vlPenAddress;
        address penDystAddress;
        address voterProxyAddress;
        address dystAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
        address veAddress;
        address userProxyInterfaceAddress;
        address votingSnapshotAddress;
        address penV1RewardsAddress;
        address penV1RedeemAddress;
        address penV1Address;
        address tokensAllowlistAddress;
    }
    struct UserPosition {
        address userProxyAddress;
        uint256 veTotalBalanceOf;
        IDystopiaLens.PositionVe[] vePositions;
        IUserProxy.PositionStakingPool[] stakingPools;
        uint256 penDystBalanceOf;
        uint256 stakedPenDystBalanceOf;
        IUserProxy.RewardToken[] penDystRewardPoolPosition;
        uint256 penV1StakedPenDystStakableAmount;
        uint256 penV1StakedPenDystBalanceOf;
        IUserProxy.RewardToken[] penV1PenDystRewardPoolPosition;
        uint256 penBalanceOf;
        uint256 dystBalanceOf;
        uint256 vlPenBalanceOf;
        IVlPen.LocksData vlPenLocksData;
        IUserProxy.RewardToken[] vlPenRewardPoolPosition;
        VotesData votesData;
        uint256 penV1BalanceOf;
        address[] userProxyImplementationsAddresses;
    }
    struct VotesData {
        address delegateAddress;
        uint256 weightTotal;
        uint256 weightUsed;
        uint256 weightAvailable;
        IVotingSnapshot.Vote[] votes;
    }
    struct StakingPoolRewardTokens {
        address stakingPoolAddress;
        IUserProxy.RewardToken[] rewardTokens;
    }
    struct MigrateablePool {
        address fromPenPoolAddress;
        address toPenPoolAddress;
        address fromStakingPoolAddress;
        uint256 balanceOf;
    }

    // Initialization
    function initializeProxyStorage(
        address _penPoolFactoryAddress,
        address _userProxyFactoryAddress,
        address _dystopiaLensAddress,
        address _penAddress,
        address _vlPenAddress,
        address _penDystAddress,
        address _penDystRewardsPoolAddress,
        address _rewardsDistributorAddress,
        address _partnersRewardsPoolAddress,
        address _userProxyInterfaceAddress
    ) public checkProxyInitialized {
        treasuryAddress = msg.sender;

        // Set addresses and interfaces
        dystopiaLensAddress = _dystopiaLensAddress;
        dystopiaLens = IDystopiaLens(dystopiaLensAddress);
        gaugesFactoryAddress = dystopiaLens.gaugesFactoryAddress();
        minterAddress = dystopiaLens.minterAddress();
        penAddress = _penAddress;
        pen = IPen(penAddress);
        penPoolFactoryAddress = _penPoolFactoryAddress;
        penPoolFactory = IPenPoolFactory(penPoolFactoryAddress);
        penDystAddress = _penDystAddress;
        penDyst = IPenDyst(penDystAddress);
        penDystRewardsPoolAddress = _penDystRewardsPoolAddress;
        penDystRewardsPool = IMultiRewards(penDystRewardsPoolAddress);
        partnersRewardsPoolAddress = _partnersRewardsPoolAddress;
        poolsFactoryAddress = dystopiaLens.poolsFactoryAddress();
        rewardsDistributorAddress = _rewardsDistributorAddress;
        dystAddress = dystopiaLens.dystAddress();
        dyst = IDyst(dystAddress);
        userProxyFactoryAddress = _userProxyFactoryAddress;
        userProxyFactory = IUserProxyFactory(userProxyFactoryAddress);
        userProxyInterfaceAddress = _userProxyInterfaceAddress;
        veAddress = dystopiaLens.veAddress();
        ve = IVe(veAddress);
        vlPenAddress = _vlPenAddress;
        vlPen = IVlPen(vlPenAddress);
        voterProxyAddress = penPoolFactory.voterProxyAddress();
        voterProxy = IVoterProxy(voterProxyAddress);
        voterAddress = dystopiaLens.voterAddress();
        votingSnapshotAddress = voterProxy.votingSnapshotAddress();
        votingSnapshot = IVotingSnapshot(votingSnapshotAddress);
        tokensAllowlistAddress = penPoolFactory.tokensAllowlist();
        tokensAllowlist = ITokensAllowlist(tokensAllowlistAddress);
    }

    /**
     * @notice Transfers treasury
     */
    function transferTreasury(address _newTreasury) external {
        require(
            msg.sender == treasuryAddress,
            "Only treasury can transfer treasury"
        );
        treasuryAddress = _newTreasury;
    }

    /*******************************************************
     *                     Protocol metadata
     *******************************************************/

    /**
     * @notice Fetch metadata about Dystopia and Penrose
     */
    function protocolAddresses()
        external
        view
        returns (ProtocolAddresses memory)
    {
        return
            ProtocolAddresses({
                penPoolFactoryAddress: penPoolFactoryAddress,
                dystopiaLensAddress: dystopiaLensAddress,
                penAddress: penAddress,
                vlPenAddress: vlPenAddress,
                penDystAddress: penDystAddress,
                voterProxyAddress: voterProxyAddress,
                dystAddress: dystAddress,
                voterAddress: voterAddress,
                poolsFactoryAddress: poolsFactoryAddress,
                gaugesFactoryAddress: gaugesFactoryAddress,
                minterAddress: minterAddress,
                veAddress: veAddress,
                userProxyInterfaceAddress: userProxyInterfaceAddress,
                votingSnapshotAddress: votingSnapshotAddress,
                penV1RewardsAddress: penV1RewardsAddress,
                penV1RedeemAddress: penV1RedeemAddress,
                penV1Address: penV1Address,
                tokensAllowlistAddress: tokensAllowlistAddress
            });
    }

    /**
     * @notice OXD total supply
     */
    function penTotalSupply() external view returns (uint256) {
        return IERC20(penAddress).totalSupply();
    }

    /**
     * @notice Fetch VoterProxy's primary token ID
     */
    function tokenId() external view returns (uint256) {
        return voterProxy.primaryTokenId();
    }

    /**
     * @notice Fetch DYST's inflation since inception
     */
    function dystInflationSinceInception() external view returns (uint256) {
        return voterProxy.dystInflationSinceInception();
    }

    /*******************************************************
     *                      Reward tokens
     *******************************************************/

    /**
     * @notice Fetch reward token earnings and position given an account address, staking pool address and rewards token address
     * @param accountAddress The account to fetch a position for
     * @param stakingPoolAddress Address of the staking pool
     * @param rewardTokenAddress Address of the reward token
     * @return Returns a list of reward token positions
     */
    function rewardTokenPositionOf(
        address accountAddress,
        address stakingPoolAddress,
        address rewardTokenAddress
    ) public view returns (IUserProxy.RewardToken memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        return
            IUserProxy.RewardToken({
                rewardTokenAddress: rewardTokenAddress,
                rewardRate: multiRewards
                    .rewardData(rewardTokenAddress)
                    .rewardRate,
                rewardPerToken: multiRewards.rewardPerToken(rewardTokenAddress),
                getRewardForDuration: multiRewards.getRewardForDuration(
                    rewardTokenAddress
                ),
                earned: multiRewards.earned(
                    userProxyAddress,
                    rewardTokenAddress
                )
            });
    }

    /**
     * @notice Fetch multiple reward token positions for an account and staking pool address
     * @param accountAddress The account to fetch positions for
     * @param stakingPoolAddress Address of the staking pool
     * @return Returns multiple staking pool positions assocaited with an account/pool
     */
    function rewardTokensPositionsOf(
        address accountAddress,
        address stakingPoolAddress
    ) public view returns (IUserProxy.RewardToken[] memory) {
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        uint256 rewardTokensLength = multiRewards.rewardTokensLength();

        IUserProxy.RewardToken[]
            memory _rewardTokensPositionsOf = new IUserProxy.RewardToken[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = multiRewards.rewardTokens(
                rewardTokenIndex
            );
            _rewardTokensPositionsOf[rewardTokenIndex] = rewardTokenPositionOf(
                accountAddress,
                stakingPoolAddress,
                rewardTokenAddress
            );
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch rewards data given a number of staking contract
     * @param stakingPoolsAddresses Addresses of the staking pools to fetch data for
     * @return Returns reward data for all reward tokens for given staking pools
     */
    function rewardTokensDatas(address[] memory stakingPoolsAddresses)
        external
        view
        returns (IPenLens.RewardTokenData[][] memory)
    {
        IPenLens.RewardTokenData[][]
            memory _rewardTokensDatas = new IPenLens.RewardTokenData[][](
                stakingPoolsAddresses.length
            );

        for (
            uint256 stakingPoolIndex;
            stakingPoolIndex < stakingPoolsAddresses.length;
            stakingPoolIndex++
        ) {
            address stakingPoolAddress = stakingPoolsAddresses[
                stakingPoolIndex
            ];
            IPenLens.RewardTokenData[] memory rewardsData = rewardTokensData(
                stakingPoolAddress
            );
            _rewardTokensDatas[stakingPoolIndex] = rewardsData;
        }
        return _rewardTokensDatas;
    }

    /**
     * @notice Fetch rewards data for staking contract
     * @param stakingPoolAddress Address of the staking pool
     * @return Returns reward data for all reward tokens
     */
    function rewardTokensData(address stakingPoolAddress)
        public
        view
        returns (IPenLens.RewardTokenData[] memory)
    {
        IMultiRewards multiRewards = IMultiRewards(stakingPoolAddress);
        uint256 rewardTokensLength = multiRewards.rewardTokensLength();

        IPenLens.RewardTokenData[]
            memory _rewardTokensPositionsOf = new IPenLens.RewardTokenData[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = multiRewards.rewardTokens(
                rewardTokenIndex
            );
            IMultiRewards.Reward memory reward = multiRewards.rewardData(
                rewardTokenAddress
            );
            _rewardTokensPositionsOf[rewardTokenIndex] = IPenLens
                .RewardTokenData({
                    id: rewardTokenAddress,
                    rewardRate: reward.rewardRate,
                    periodFinish: reward.periodFinish
                });
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch all reward token positions given an account address
     * @param accountAddress The account to fetch positions for
     * @dev Utilizes a per-user staking pool position map to find positions with O(n) efficiency
     */
    function rewardTokensPositionsOf(address accountAddress)
        external
        view
        returns (StakingPoolRewardTokens[] memory)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        address[] memory _stakingPoolsAddresses = IUserProxy(userProxyAddress)
            .stakingAddresses();
        StakingPoolRewardTokens[]
            memory stakingPoolsRewardsTokens = new StakingPoolRewardTokens[](
                _stakingPoolsAddresses.length
            );
        for (
            uint256 stakingPoolIndex;
            stakingPoolIndex <
            IUserProxy(userProxyAddress).stakingPoolsLength();
            stakingPoolIndex++
        ) {
            address stakingPoolAddress = _stakingPoolsAddresses[
                stakingPoolIndex
            ];
            stakingPoolsRewardsTokens[
                stakingPoolIndex
            ] = StakingPoolRewardTokens({
                stakingPoolAddress: stakingPoolAddress,
                rewardTokens: rewardTokensPositionsOf(
                    accountAddress,
                    stakingPoolAddress
                )
            });
        }
        return stakingPoolsRewardsTokens;
    }

    /*******************************************************
     *                     LP Positions
     *******************************************************/

    /**
     * @notice Dystopia pools positions
     * @param accountAddress Account to fetch positions for
     */
    function poolsPositions(address accountAddress)
        external
        view
        returns (IDystopiaLens.PositionPool[] memory)
    {
        return dystopiaLens.poolsPositionsOf(accountAddress);
    }

    /**
     * @notice Dystopia pools positions
     * @param accountAddress Account to fetch positions for
     * @param startIndex Start index
     * @param endIndex End index
     */
    function poolsPositions(
        address accountAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IDystopiaLens.PositionPool[] memory) {
        return
            dystopiaLens.poolsPositionsOf(accountAddress, startIndex, endIndex);
    }

    /**
     * @notice Find a staking pool position for an account given an account address and staking pool address
     * @param accountAddress The account to fetch positions for
     * @param stakingPoolAddress The address of the staking pool to check
     */
    function stakingPoolPosition(
        address accountAddress,
        address stakingPoolAddress
    ) public view returns (IUserProxy.PositionStakingPool memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        address penPoolAddress = IMultiRewards(stakingPoolAddress)
            .stakingToken();
        uint256 balanceOf = IMultiRewards(stakingPoolAddress).balanceOf(
            userProxyAddress
        );
        address dystPoolAddress = IPenPool(penPoolAddress).dystPoolAddress();

        IUserProxy.RewardToken[] memory rewardTokens = rewardTokensPositionsOf(
            accountAddress,
            stakingPoolAddress
        );

        return
            IUserProxy.PositionStakingPool({
                stakingPoolAddress: stakingPoolAddress,
                penPoolAddress: penPoolAddress,
                dystPoolAddress: dystPoolAddress,
                balanceOf: balanceOf,
                rewardTokens: rewardTokens
            });
    }

    /**
     * @notice Find all staking pool positions for msg.sender
     */
    function stakingPoolsPositions()
        external
        view
        returns (IUserProxy.PositionStakingPool[] memory)
    {
        return stakingPoolsPositions(msg.sender);
    }

    /**
     * @notice Find all staking pool positions given an account address
     * @param accountAddress The account to fetch positions for
     */
    function stakingPoolsPositions(address accountAddress)
        public
        view
        returns (IUserProxy.PositionStakingPool[] memory)
    {
        IUserProxy.PositionStakingPool[] memory stakingPositions;

        address userProxyAddress = userProxyByAccount(accountAddress);
        if (userProxyAddress == address(0)) {
            return stakingPositions;
        }

        address[] memory _stakingPoolsAddresses = IUserProxy(userProxyAddress)
            .stakingAddresses();

        stakingPositions = new IUserProxy.PositionStakingPool[](
            _stakingPoolsAddresses.length
        );

        for (
            uint256 stakingPoolAddressIdx;
            stakingPoolAddressIdx < _stakingPoolsAddresses.length;
            stakingPoolAddressIdx++
        ) {
            address stakingPoolAddress = _stakingPoolsAddresses[
                stakingPoolAddressIdx
            ];
            IUserProxy.PositionStakingPool
                memory stakingPosition = stakingPoolPosition(
                    accountAddress,
                    stakingPoolAddress
                );
            stakingPositions[stakingPoolAddressIdx] = stakingPosition;
        }
        return stakingPositions;
    }

    /*******************************************************
     *                   penPools positions
     *******************************************************/

    /**
     * @notice Fetch a list of penPools that need migration
     * @param accountAddress Account address to find migrations for
     */
    function migrateablePenPools(address accountAddress)
        external
        view
        returns (MigrateablePool[] memory)
    {
        IUserProxy _userProxy = userProxy(accountAddress);
        IUserProxy.PositionStakingPool[]
            memory stakingPools = stakingPoolsPositions(accountAddress);
        uint256 stakingPoolsLength = stakingPools.length;
        MigrateablePool[] memory migrateablePools = new MigrateablePool[](
            stakingPoolsLength
        );
        uint256 currentIndex;
        for (
            uint256 stakingPoolIndex;
            stakingPoolIndex < stakingPoolsLength;
            stakingPoolIndex++
        ) {
            IUserProxy.PositionStakingPool memory stakingPool = stakingPools[
                stakingPoolIndex
            ];
            address fromPenPoolAddress = stakingPool.penPoolAddress;
            address toPenPoolAddress = penPoolsMigrationMapping[
                fromPenPoolAddress
            ];
            bool penPoolNeedsMigration = toPenPoolAddress != address(0);
            if (penPoolNeedsMigration) {
                migrateablePools[currentIndex] = MigrateablePool({
                    fromPenPoolAddress: fromPenPoolAddress,
                    toPenPoolAddress: toPenPoolAddress,
                    fromStakingPoolAddress: stakingPool.stakingPoolAddress,
                    balanceOf: stakingPool.balanceOf
                });
                currentIndex++;
            }
        }
        bytes memory encodedMigrations = abi.encode(migrateablePools);
        assembly {
            mstore(add(encodedMigrations, 0x40), currentIndex)
        }
        return abi.decode(encodedMigrations, (MigrateablePool[]));
    }

    /**
     * @notice Fetch the total number of synced penPools
     */
    function penPoolsLength() public view returns (uint256) {
        return penPoolFactory.penPoolsLength();
    }

    /**
     * @notice Fetch all penPools addresses
     * @return Returns all penPool addresses
     * @dev Warning: at some point this method will no longer work (we will run out of gas) and pagination must be used
     */
    function penPoolsAddresses() public view returns (address[] memory) {
        uint256 _penPoolsLength = penPoolsLength();
        address[] memory _penPoolsAddresses = new address[](_penPoolsLength);
        for (uint256 penPoolIdx; penPoolIdx < _penPoolsLength; penPoolIdx++) {
            _penPoolsAddresses[penPoolIdx] = penPoolFactory.penPools(penPoolIdx);
        }
        return _penPoolsAddresses;
    }

    /**
     * @notice Find metadata about an penPool given an penPoolAddress
     * @param penPoolAddress The address of the penPool to fetch metadata for
     */
    function penPoolData(address penPoolAddress)
        public
        view
        returns (PenPoolData memory)
    {
        IPenPool penPool = IPenPool(penPoolAddress);
        address stakingAddress = penPool.stakingAddress();
        address dystPoolAddress = penPool.dystPoolAddress();
        uint256 totalSupply = penPool.totalSupply();
        uint256 stakedTotalSupply = IMultiRewards(stakingAddress).totalSupply();
        IDystopiaLens.Pool memory poolData = dystopiaLens.poolInfo(
            dystPoolAddress
        );
        return
            PenPoolData({
                id: penPoolAddress,
                stakingAddress: stakingAddress,
                stakedTotalSupply: stakedTotalSupply,
                totalSupply: totalSupply,
                poolData: poolData
            });
    }

    /**
     * @notice Fetch penPool metadata given an array of penPool addresses
     * @param _penPoolsAddresses A list of penPool addresses
     * @dev This method is intended for pagination
     */
    function penPoolsData(address[] memory _penPoolsAddresses)
        public
        view
        returns (PenPoolData[] memory)
    {
        PenPoolData[] memory _penPoolsData = new PenPoolData[](
            _penPoolsAddresses.length
        );
        for (
            uint256 penPoolIdx;
            penPoolIdx < _penPoolsAddresses.length;
            penPoolIdx++
        ) {
            address penPoolAddress = _penPoolsAddresses[penPoolIdx];
            _penPoolsData[penPoolIdx] = penPoolData(penPoolAddress);
        }
        return _penPoolsData;
    }

    /**
     * @notice Find metadata for all penPools
     * @dev Warning: at some point this method will no longer work (we will run out of gas) and pagination must be used
     * @return Returns metadata for all penPools
     */
    function penPoolsData() external view returns (PenPoolData[] memory) {
        address[] memory _penPoolsAddresses = penPoolsAddresses();
        return penPoolsData(_penPoolsAddresses);
    }

    /*******************************************************
     *                       Voting
     *******************************************************/

    /**
     * @notice Find voting metadata and positions for an account
     * @param accountAddress The address to fetch voting metadata for
     */
    function votePositionsOf(address accountAddress)
        public
        view
        returns (VotesData memory)
    {
        uint256 weightTotal = votingSnapshot.voteWeightTotalByAccount(
            accountAddress
        );
        uint256 weightUsed = votingSnapshot.voteWeightUsedByAccount(
            accountAddress
        );
        uint256 weightAvailable = votingSnapshot.voteWeightAvailableByAccount(
            accountAddress
        );
        address delegateAddress = votingSnapshot.voteDelegateByAccount(
            accountAddress
        );
        IVotingSnapshot.Vote[] memory votes = votingSnapshot.votesByAccount(
            accountAddress
        );
        return
            VotesData({
                delegateAddress: delegateAddress,
                weightTotal: weightTotal,
                weightUsed: weightUsed,
                weightAvailable: weightAvailable,
                votes: votes
            });
    }

    /*******************************************************
     *                   Dystopia positions
     *******************************************************/

    /**
     * @notice Find the amount of DYST owned by an account
     * @param accountAddress The address to check balance of
     * @return Returns DYST balance of account
     */
    function dystBalanceOf(address accountAddress)
        public
        view
        returns (uint256)
    {
        return dyst.balanceOf(accountAddress);
    }

    /*******************************************************
     *                    penDYST positions
     *******************************************************/

    /**
     * @notice Find the amount of penDYST owned by an account
     * @param accountAddress The address to check balance of
     * @return Returns penDYST balance of account
     */
    function penDystBalanceOf(address accountAddress)
        public
        view
        returns (uint256)
    {
        return penDyst.balanceOf(accountAddress);
    }

    /**
     * @notice Find the amount of staked penDYST for an account
     * @param accountAddress The address to check staked balance of
     * @return stakedBalance Returns staked penDYST balance of account
     */
    function stakedPenDystBalanceOf(address accountAddress)
        public
        view
        returns (uint256 stakedBalance)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        if (isPartner(userProxyAddress)) {
            stakedBalance = IPartnersRewards(partnersRewardsPoolAddress)
                .balanceOf(userProxyAddress);
        } else {
            stakedBalance = penDystRewardsPool.balanceOf(userProxyAddress);
        }
        return stakedBalance;
    }

    /**
     * @notice Find the amount of penDYST staked in the OXDv1 rewards pool for an account
     * @param accountAddress The address to check staked balance of
     * @return stakedBalance Returns staked penDYST balance of account
     */
    function penV1StakedPenDystBalanceOf(address accountAddress)
        public
        view
        returns (uint256 stakedBalance)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        stakedBalance = IMultiRewards(penV1RewardsAddress).balanceOf(
            userProxyAddress
        );
        return stakedBalance;
    }

    /**
     * @notice Find the amount of penDYST that can be added to the OXDv1 rewards pool for an account
     * @param accountAddress The address to check staked balance of
     * @return stakableAmount Returns the additional stakable amount
     */
    function penV1StakedPenDystStakableAmount(address accountAddress)
        public
        view
        returns (uint256 stakableAmount)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);

        // get staked balance and stakingCap
        uint256 stakedBalance = IPenV1Rewards(penV1RewardsAddress).balanceOf(
            userProxyAddress
        );
        uint256 stakingCap = IPenV1Rewards(penV1RewardsAddress).stakingCap(
            userProxyAddress
        );

        // check stakingCap > stakedBalance to prevent reverts, returns 0 if otherwise
        if (stakingCap > stakedBalance) {
            return stakingCap - stakedBalance;
        }
    }

    /**
     * @notice Find penDYST reward pool data for an account
     * @param accountAddress The address to check reward pool data for
     */
    function penDystRewardPoolPosition(address accountAddress)
        public
        view
        returns (IUserProxy.RewardToken[] memory)
    {
        //determin partner status
        if (isProxyPartner(accountAddress)) {
            return
                rewardTokensPositionsOf(
                    accountAddress,
                    partnersRewardsPoolAddress
                );
        }
        return
            rewardTokensPositionsOf(accountAddress, penDystRewardsPoolAddress);
    }

    /*******************************************************
     *                    vlOXD positions
     *******************************************************/

    /**
     * @notice Fetch vlOXD metadata and locks for an account
     * @param accountAddress The address to check
     */
    function vlPenLocksData(address accountAddress)
        public
        view
        returns (IVlPen.LocksData memory)
    {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        IVlPen.LockedBalance[] memory locks;
        (total, unlockable, locked, locks) = vlPen.lockedBalances(
            accountAddress
        );
        return
            IVlPen.LocksData({
                total: total,
                unlockable: unlockable,
                locked: locked,
                locks: locks
            });
    }

    /**
     * @notice Fetch vlOXD reward token positions for an account
     * @param accountAddress The address to check
     */
    function vlPenRewardTokenPositionsOf(address accountAddress)
        public
        view
        returns (IUserProxy.RewardToken[] memory)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IVlPen _vlPen = vlPen;
        uint256 rewardTokensLength = _vlPen.rewardTokensLength();
        IVlPen.EarnedData[] memory claimable = vlPen.claimableRewards(
            userProxyAddress
        );
        IUserProxy.RewardToken[]
            memory _rewardTokensPositionsOf = new IUserProxy.RewardToken[](
                rewardTokensLength
            );

        for (
            uint256 rewardTokenIndex;
            rewardTokenIndex < rewardTokensLength;
            rewardTokenIndex++
        ) {
            address rewardTokenAddress = _vlPen.rewardTokens(rewardTokenIndex);
            _rewardTokensPositionsOf[
                rewardTokenIndex
            ] = vlPenRewardTokenPositionOf(accountAddress, rewardTokenAddress);
            _rewardTokensPositionsOf[rewardTokenIndex].earned = claimable[
                rewardTokenIndex
            ].amount;
        }
        return _rewardTokensPositionsOf;
    }

    /**
     * @notice Fetch vlOXD reward token position of a specific token address for an account
     * @param accountAddress The address to check
     * @param rewardTokenAddress The token to check
     */
    function vlPenRewardTokenPositionOf(
        address accountAddress,
        address rewardTokenAddress
    ) public view returns (IUserProxy.RewardToken memory) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        IVlPen _vlPen = vlPen;

        return
            IUserProxy.RewardToken({
                rewardTokenAddress: rewardTokenAddress,
                rewardRate: _vlPen.rewardData(rewardTokenAddress).rewardRate,
                rewardPerToken: _vlPen.rewardPerToken(rewardTokenAddress),
                getRewardForDuration: _vlPen.getRewardForDuration(
                    rewardTokenAddress
                ),
                earned: 0
            });
    }

    /*******************************************************
     *                     veNFT positions
     *******************************************************/

    /**
     * @notice Calculate total veNFT balance summation given an array of ve positions
     */
    function veTotalBalanceOf(IDystopiaLens.PositionVe[] memory positions)
        public
        pure
        returns (uint256)
    {
        uint256 _veotalBalanceOf;
        for (
            uint256 positionIdx;
            positionIdx < positions.length;
            positionIdx++
        ) {
            IDystopiaLens.PositionVe memory position = positions[positionIdx];
            _veotalBalanceOf += position.balanceOf;
        }
        return _veotalBalanceOf;
    }

    /*******************************************************
     *                   Global user positions
     *******************************************************/

    /**
     * @notice Find all positions for an account
     * @param accountAddress The address to check
     * @dev Warning: it's possible this may revert at some point (due to out-of-gas) if the user has too many positions
     */
    function positionsOf(address accountAddress)
        external
        view
        returns (UserPosition memory)
    {
        UserPosition memory _userPosition;
        address userProxyAddress = userProxyByAccount(accountAddress);
        // Sectioning to avoid stack-too-deep (there has to be a std joke somewhere in here)
        {
            IDystopiaLens.PositionVe[] memory vePositions = dystopiaLens
                .vePositionsOf(accountAddress);
            IUserProxy.PositionStakingPool[]
                memory stakingPools = stakingPoolsPositions(accountAddress);

            uint256 _veTotalBalanceOf = veTotalBalanceOf(vePositions);
            uint256 _penDystBalanceOf = penDystBalanceOf(accountAddress);
            IUserProxy.RewardToken[]
                memory _penDystRewardPoolPosition = penDystRewardPoolPosition(
                    accountAddress
                );
            IUserProxy.RewardToken[]
                memory _penV1PenDystRewardPoolPosition = rewardTokensPositionsOf(
                    accountAddress,
                    penV1RewardsAddress
                );

            IUserProxy _userProxy = userProxy(accountAddress);
            if (userProxyAddress != address(0)) {
                _userPosition.userProxyImplementationsAddresses = _userProxy
                    .implementationsAddresses();
            }
            _userPosition.userProxyAddress = userProxyAddress;
            _userPosition.veTotalBalanceOf = _veTotalBalanceOf;
            _userPosition.vePositions = vePositions;
            _userPosition.stakingPools = stakingPools;
            _userPosition.penDystBalanceOf = _penDystBalanceOf;
            _userPosition
                .penDystRewardPoolPosition = _penDystRewardPoolPosition;
            _userPosition
                .penV1PenDystRewardPoolPosition = _penV1PenDystRewardPoolPosition;
        }
        {
            uint256 _dystBalanceOf = dystBalanceOf(accountAddress);
            uint256 penBalanceOf = IERC20(penAddress).balanceOf(accountAddress);
            uint256 penV1BalanceOf = IERC20(penV1Address).balanceOf(
                accountAddress
            );
            uint256 vlPenBalanceOf = IVlPen(vlPenAddress).lockedBalanceOf(
                userProxyAddress
            );
            IUserProxy.RewardToken[]
                memory _vlPenRewardPoolPosition = vlPenRewardTokenPositionsOf(
                    accountAddress
                );

            uint256 _stakedPenDystBalanceOf = stakedPenDystBalanceOf(
                accountAddress
            );
            uint256 _penV1StakedPenDystBalanceOf = penV1StakedPenDystBalanceOf(
                accountAddress
            );
            IVlPen.LocksData memory _vlPenLocksData = vlPenLocksData(
                userProxyAddress
            );
            VotesData memory votesData = votePositionsOf(userProxyAddress);

            uint256 _penV1StakedPenDystStakableAmount = penV1StakedPenDystStakableAmount(
                    accountAddress
                );

            _userPosition.stakedPenDystBalanceOf = _stakedPenDystBalanceOf;
            _userPosition
                .penV1StakedPenDystBalanceOf = _penV1StakedPenDystBalanceOf;
            _userPosition.penBalanceOf = penBalanceOf;
            _userPosition.dystBalanceOf = _dystBalanceOf;
            _userPosition.vlPenBalanceOf = vlPenBalanceOf;
            _userPosition.vlPenLocksData = _vlPenLocksData;
            _userPosition.vlPenRewardPoolPosition = _vlPenRewardPoolPosition;
            _userPosition.votesData = votesData;
            _userPosition.penV1BalanceOf = penV1BalanceOf;
            _userPosition
                .penV1StakedPenDystStakableAmount = _penV1StakedPenDystStakableAmount;
        }
        return _userPosition;
    }

    /*******************************************************
     *                      User Proxy
     *******************************************************/

    /**
     * @notice Given an account address fetch the user's UserProxy interface
     * @dev Internal convenience method
     */
    function userProxy(address accountAddress)
        internal
        view
        returns (IUserProxy)
    {
        address userProxyAddress = userProxyByAccount(accountAddress);
        return IUserProxy(userProxyAddress);
    }

    /**
     * @notice Fetch total number of user proxies
     */
    function userProxiesLength() public view returns (uint256) {
        return userProxyFactory.userProxiesLength();
    }

    /**
     * @notice Fetch a user's UserProxy address given an account address
     */
    function userProxyByAccount(address accountAddress)
        public
        view
        returns (address)
    {
        return userProxyFactory.userProxyByAccount(accountAddress);
    }

    /**
     * @notice Find a user proxy address given an index
     */
    function userProxyByIndex(uint256 index) public view returns (address) {
        return userProxyFactory.userProxyByIndex(index);
    }

    /*******************************************************
     *                    Helper utilities
     *******************************************************/

    /**
     * @notice Given an penPoolAddress fetch the corresponding dyst pool address
     */
    function dystPoolByPenPool(address penPoolAddress)
        public
        view
        returns (address)
    {
        return penPoolFactory.dystPoolByPenPool(penPoolAddress);
    }

    /**
     * @notice Given a DYST pool address fetch the corresponding penPool address
     */
    function penPoolByDystPool(address dystPoolAddress)
        public
        view
        returns (address)
    {
        return penPoolFactory.penPoolByDystPool(dystPoolAddress);
    }

    /**
     * @notice Given a DYST pool address find the corresponding gauge address
     * @param dystPoolAddress Input address
     */
    function gaugeByDystPool(address dystPoolAddress)
        public
        view
        returns (address)
    {
        return dystopiaLens.gaugeAddressByPoolAddress(dystPoolAddress);
    }

    /**
     * @notice Given an penPool address find the corresponding staking rewards address
     * @param penPoolAddress Input address
     */
    function stakingRewardsByPenPool(address penPoolAddress)
        public
        view
        returns (address)
    {
        IPenPool penPool = IPenPool(penPoolAddress);
        address stakingAddress = penPool.stakingAddress();
        return stakingAddress;
    }

    /**
     * @notice Given a DYST pool address find the corresponding staking pool address
     * @param dystPoolAddress Input address
     */
    function stakingRewardsByDystPool(address dystPoolAddress)
        external
        view
        returns (address)
    {
        address penPoolAddress = penPoolByDystPool(dystPoolAddress);
        address stakingAddress = stakingRewardsByPenPool(penPoolAddress);
        return stakingAddress;
    }

    /**
     * @notice Determine whether or not a pool is a valid penPool
     */
    function isPenPool(address penPoolAddress) public view returns (bool) {
        return penPoolFactory.isPenPool(penPoolAddress);
    }

    /**
     * @notice Determine whether or not a given account address is a partner
     * @param userProxyAddress User proxy address
     */
    function isPartner(address userProxyAddress) public view returns (bool) {
        return
            IPartnersRewards(partnersRewardsPoolAddress).isPartner(
                userProxyAddress
            );
    }

    /**
     * @notice Determine whether or not a given user's proxy address is a partner
     * @param accountAddress User address
     */
    function isProxyPartner(address accountAddress) public view returns (bool) {
        address userProxyAddress = userProxyByAccount(accountAddress);
        return
            IPartnersRewards(partnersRewardsPoolAddress).isPartner(
                userProxyAddress
            );
    }

    /*******************************************************
     *                    Administrative
     *******************************************************/
    function setMigration(address fromPenPoolAddress, address toPenPoolAddress)
        public
        onlyTreasury
    {
        penPoolsMigrationMapping[fromPenPoolAddress] = toPenPoolAddress;
    }

    function setMigrations(
        address[] memory fromPenPoolsAddresses,
        address[] memory toPenPoolsAddresses
    ) external {
        require(
            fromPenPoolsAddresses.length == toPenPoolsAddresses.length,
            "Invalid inputs"
        );
        for (
            uint256 penPoolIndex;
            penPoolIndex < fromPenPoolsAddresses.length;
            penPoolIndex++
        ) {
            address fromPenPoolAddress = fromPenPoolsAddresses[penPoolIndex];
            address toPenPoolAddress = toPenPoolsAddresses[penPoolIndex];
            setMigration(fromPenPoolAddress, toPenPoolAddress);
        }
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
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author Penrose
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMultiRewards {
    struct Reward {
        address rewardsDistributor;
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function stake(uint256) external;

    function withdraw(uint256) external;

    function getReward() external;

    function stakingToken() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function initialize(address, address) external;

    function rewardRate(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function rewardPerToken(address) external view returns (uint256);

    function rewardData(address) external view returns (Reward memory);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);

    function addReward(
        address _rewardsToken,
        address _rewardsDistributor,
        uint256 _rewardsDuration
    ) external;

    function notifyRewardAmount(address, uint256) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration)
        external;

    function exit() external;

    function nominateNewOwner(address _owner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPen is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPenV1Redeem {
    function penV1Burnt(address account) external view returns (uint256);

    function redeem(uint256 amount) external;

    function oxdV1() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IMultiRewards.sol";

interface IPenV1Rewards is IMultiRewards {
    function stakingCap(address account) external view returns (uint256 cap);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IPen.sol";
import "./IVlPen.sol";
import "./IPenPoolFactory.sol";
import "./IPenDyst.sol";
import "./IDyst.sol";
import "./IDystopiaLens.sol";
import "./IUserProxy.sol";
import "./IVe.sol";
import "./IVotingSnapshot.sol";
import "./IVoterProxy.sol";
import "./IPenV1Rewards.sol";
import "./ITokensAllowlist.sol";

interface IPenLens {
    struct ProtocolAddresses {
        address penPoolFactoryAddress;
        address DystopiaLensAddress;
        address PenAddress;
        address vlPenAddress;
        address penDystAddress;
        address voterProxyAddress;
        address dystAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
        address veAddress;
        address userProxyInterfaceAddress;
        address votingSnapshotAddress;
    }

    struct UserPosition {
        address userProxyAddress;
        uint256 veTotalBalanceOf;
        IDystopiaLens.PositionVe[] vePositions;
        IDystopiaLens.PositionPool[] poolsPositions;
        IUserProxy.PositionStakingPool[] stakingPools;
        uint256 penDystBalanceOf;
        uint256 penBalanceOf;
        uint256 dystBalanceOf;
        uint256 vlPenBalanceOf;
    }

    struct TokenMetadata {
        address id;
        string name;
        string symbol;
        uint8 decimals;
        uint256 priceUsdc;
    }

    struct PenPoolData {
        address id;
        address stakingAddress;
        uint256 stakedTotalSupply;
        uint256 totalSupply;
        IDystopiaLens.Pool poolData;
    }

    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
    }

    struct RewardTokenData {
        address id;
        uint256 rewardRate;
        uint256 periodFinish;
    }

    /* ========== PUBLIC VARS ========== */

    function penPoolFactoryAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function userProxyFactoryAddress() external view returns (address);

    function dystopiaLensAddress() external view returns (address);

    function penAddress() external view returns (address);

    function vlPenAddress() external view returns (address);

    function penDystAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function veAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function penDystRewardsPoolAddress() external view returns (address);

    function partnersRewardsPoolAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function cvlPenAddress() external view returns (address);

    function penV1RewardsAddress() external view returns (address);

    function penV1RedeemAddress() external view returns (address);

    function penV1Address() external view returns (address);

    function tokensAllowlistAddress() external view returns (address);

    /* ========== PUBLIC VIEW FUNCTIONS ========== */

    function voterAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function protocolAddresses()
        external
        view
        returns (ProtocolAddresses memory);

    function positionsOf(address accountAddress)
        external
        view
        returns (UserPosition memory);

    function rewardTokensPositionsOf(address, address)
        external
        view
        returns (IUserProxy.RewardToken[] memory);

    function veTotalBalanceOf(IDystopiaLens.PositionVe[] memory positions)
        external
        pure
        returns (uint256);

    function penPoolsLength() external view returns (uint256);

    function userProxiesLength() external view returns (uint256);

    function userProxyByAccount(address accountAddress)
        external
        view
        returns (address);

    function userProxyByIndex(uint256 index) external view returns (address);

    function gaugeByDystPool(address) external view returns (address);

    function dystPoolByPenPool(address penPoolAddress)
        external
        view
        returns (address);

    function penPoolByDystPool(address dystPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsByDystPool(address dystPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsByPenPool(address dystPoolAddress)
        external
        view
        returns (address);

    function isPenPool(address penPoolAddress) external view returns (bool);

    function penPoolsAddresses() external view returns (address[] memory);

    function penPoolData(address penPoolAddress)
        external
        view
        returns (PenPoolData memory);

    function penPoolsData(address[] memory _penPoolsAddresses)
        external
        view
        returns (PenPoolData[] memory);

    function penPoolsData() external view returns (PenPoolData[] memory);

    function penDyst() external view returns (IPenDyst);

    function pen() external view returns (IPen);

    function vlPen() external view returns (IVlPen);

    function penPoolFactory() external view returns (IPenPoolFactory);

    function dyst() external view returns (IDyst);

    function ve() external view returns (IVe);

    function voterProxy() external view returns (IVoterProxy);

    function votingSnapshot() external view returns (IVotingSnapshot);

    function tokensAllowlist() external view returns (ITokensAllowlist);

    function isPartner(address userProxyAddress) external view returns (bool);

    function stakedPenDystBalanceOf(address accountAddress)
        external
        view
        returns (uint256 stakedBalance);

    function dystInflationSinceInception() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPenDyst is IERC20 {
    function mint(address, uint256) external;

    function convertNftToPenDyst(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IDystopiaLens.sol";

interface IPenPool {
    function stakingAddress() external view returns (address);

    function dystPoolAddress() external view returns (address);

    function dystPoolInfo() external view returns (IDystopiaLens.Pool memory);

    function depositLpAndStake(uint256) external;

    function depositLp(uint256) external;

    function withdrawLp(uint256) external;

    function syncBribeTokens() external;

    function notifyBribeOrFees() external;

    function initialize(
        address,
        address,
        address,
        string memory,
        string memory,
        address,
        address
    ) external;

    function gaugeAddress() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPenPoolFactory {
    function penPoolsLength() external view returns (uint256);

    function isPenPool(address) external view returns (bool);

    function isPenPoolOrLegacyPenPool(address) external view returns (bool);

    function PEN() external view returns (address);

    function syncPools(uint256) external;

    function penPools(uint256) external view returns (address);

    function penPoolByDystPool(address) external view returns (address);

    function vlPenAddress() external view returns (address);

    function dystPoolByPenPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function dystopiaLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDyst {
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function router() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDystopiaLens {
    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
        uint256 totalSupply;
    }

    struct PoolReserveData {
        address id;
        address token0Address;
        address token1Address;
        uint256 token0Reserve;
        uint256 token1Reserve;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolsPositionsOf(
        address,
        uint256,
        uint256
    ) external view returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address penPoolAddress;
        address dystPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToPenDyst(uint256) external;

    function convertDystToPenDyst(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakePenLp(address, uint256) external;

    function unstakePenLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakePenDyst(uint256) external;

    function unstakePenDyst(uint256) external;

    function unstakePenDyst(address, uint256) external;

    function convertDystToPenDystAndStake(uint256) external;

    function convertNftToPenDystAndStake(uint256) external;

    function claimPenDystStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlPenRewards() external;

    function depositPen(uint256, uint256) external;

    function withdrawPen(bool, uint256) external;

    function voteLockPen(uint256, uint256) external;

    function withdrawVoteLockedPen(uint256, bool) external;

    function relockVoteLockedPen(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migratePenDystToPartner() external;

    function stakePenDystInPenV1(uint256) external;

    function unstakePenDystInPenV1(uint256) external;

    function redeemPenV1(uint256) external;

    function redeemAndStakePenV1(uint256) external;

    function implementationsAddresses()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxyFactory {
    function createAndGetUserProxy(address) external returns (address);

    function penLensAddress() external view returns (address);

    function userProxyByAccount(address) external view returns (address);

    function userProxyByIndex(uint256) external view returns (address);

    function userProxyInterfaceAddress() external view returns (address);

    function userProxiesLength() external view returns (uint256);

    function isUserProxy(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVe {
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function balanceOfAtNFT(uint256, uint256) external view returns (uint256);

    function locked(uint256) external view returns (uint256);

    function createLock(uint256, uint256) external returns (uint256);

    function approve(address, uint256) external;

    function merge(uint256, uint256) external;

    function token() external view returns (address);

    function voter() external view returns (address);

    function voted(uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVlPen {
    struct LocksData {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        LockedBalance[] locks;
    }

    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Reward {
        bool useBoost;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
        address rewardsDistributor;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function processExpiredLocks(
        bool _relock,
        uint256 _spendRatio,
        address _withdrawTo
    ) external;

    function lockedBalanceOf(address) external view returns (uint256 amount);

    function lockedBalances(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            LockedBalance[] memory
        );

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewardData(address) external view returns (Reward memory);

    function rewardPerToken(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function getReward() external;

    function checkpointEpoch() external;

    function updateRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(address _penPool, address[] memory _tokens)
        external;

    function depositNft(uint256) external;

    function veAddress() external returns (address);

    function veDistAddress() external returns (address);

    function lockDyst(uint256 amount) external;

    function primaryTokenId() external view returns (uint256);

    function vote(address[] memory, int256[] memory) external;

    function votingSnapshotAddress() external view returns (address);

    function dystInflationSinceInception() external view returns (uint256);

    function getRewardFromBribe(
        address penPoolAddress,
        address[] memory _tokensAddresses
    ) external returns (bool allClaimed, bool[] memory claimed);

    function getFeeTokensFromBribe(address penPoolAddress)
        external
        returns (bool allClaimed);

    function claimDyst(address penPoolAddress)
        external
        returns (bool _claimDyst);

    function setVoterProxyAssetsAddress(address _voterProxyAssetsAddress)
        external;

    function detachNFT(uint256 startingIndex, uint256 range) external;

    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;
pragma experimental ABIEncoderV2;

interface IVotingSnapshot {
    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function removeVote(address) external;

    function resetVotes() external;

    function resetVotes(address) external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function voteDelegateByAccount(address) external view returns (address);

    function votesByAccount(address) external view returns (Vote[] memory);

    function voteWeightTotalByAccount(address) external view returns (uint256);

    function voteWeightUsedByAccount(address) external view returns (uint256);

    function voteWeightAvailableByAccount(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IMultiRewards.sol";

interface IPartnersRewards is IMultiRewards {
    function isPartner(address userProxyAddress) external view returns (bool);

    function setOperator(address candidate, bool status) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokensAllowlist {
    function tokenIsAllowed(address) external view returns (bool);

    function bribeTokensSyncPageSize() external view returns (uint256);

    function bribeTokensNotifyPageSize() external view returns (uint256);

    function bribeSyncLagLimit() external view returns (uint256);

    function notifyFrequency()
        external
        view
        returns (uint256 bribeFrequency, uint256 feeFrequency);

    function feeClaimingDisabled(address) external view returns (bool);

    function periodBetweenClaimDyst() external view returns (uint256);

    function periodBetweenClaimFee() external view returns (uint256);

    function periodBetweenClaimBribe() external view returns (uint256);

    function tokenIsAllowedInPools(address) external view returns (bool);

    function setTokenIsAllowedInPools(
        address[] memory tokensAddresses,
        bool allowed
    ) external;

    function oogLoopLimit() external view returns (uint256);

    function notifyDystThreshold() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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