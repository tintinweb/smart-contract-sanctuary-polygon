// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../interface/IVe.sol";
import "../../interface/IVoter.sol";
import "../../interface/IERC721.sol";
import "../../interface/IGauge.sol";
import "../../interface/IFactory.sol";
import "../../interface/IPair.sol";
import "../../interface/IBribeFactory.sol";
import "../../interface/IGaugeFactory.sol";
import "../../interface/IMinter.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IInternalBribe.sol";
import "../../interface/IMultiRewardsPool.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SatinVoterV1 is IVoter, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The ve token that governs these contracts
    address public override ve;
    /// @dev SatinFactory
    address public factory;
    address public veDist;
    address public token;
    address public gaugeFactory;
    address public bribeFactory;
    /// @dev Rewards are released over 7 days
    uint internal constant DURATION = 7 days;
    address public minter;
    address public owner;
    address public rebaseHandler;
    address internal SATIN_CASH_LP_GAUGE;

    /// @dev Total voting weight
    uint public totalWeight;

    /// @dev All pools viable for incentives
    address[] public pools;
    /// @dev pool => gauge
    mapping(address => address) public gauges;
    /// @dev gauge => pool
    mapping(address => address) public poolForGauge;
    /// @dev gauge => bribe
    mapping(address => address) public internal_bribes; // gauge => internal bribe (only fees)
    mapping(address => address) public external_bribes; // gauge => external bribe (real bribes)
    /// @dev pool => weight
    mapping(address => int256) public weights;
    /// @dev nft => pool => votes
    mapping(uint => mapping(address => int256)) public votes;
    /// @dev nft => pools
    mapping(uint => address[]) public poolVote;
    /// @dev nft => total voting weight of user
    mapping(uint => uint) public usedWeights;
    mapping(uint => uint) public lastVoted;
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public is4poolGauge;

    uint public index;
    uint public veShare;
    bool public onlyAdminCanVote;
    bool public xbribePaused;
    mapping(address => uint) public supplyIndex;
    mapping(address => uint) public claimable;
    mapping(address => uint) public maxVotesForPool;

    event GaugeCreated(address indexed gauge, address creator, address internal_bribe, address indexed external_bribe, address indexed pool);
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);

    // constructor(
    //     address _ve,
    //     address _factory,
    //     address _gaugeFactory,
    //     address _bribeFactory,
    //     address _token
    // ) {
    //     ve = _ve;
    //     factory = _factory;
    //     token = _token;
    //     gaugeFactory = _gaugeFactory;
    //     bribeFactory = _bribeFactory;
    //     minter = msg.sender;
    //     owner = msg.sender;
    // }

    function initialize(address _ve, address _factory, address _gaugeFactory, address _bribeFactory, address _token, address _veDist, address _rebaseHandler) public initializer {
        __ReentrancyGuard_init_unchained();
        ve = _ve;
        veDist = _veDist;
        factory = _factory;
        token = _token;
        gaugeFactory = _gaugeFactory;
        bribeFactory = _bribeFactory;
        minter = msg.sender;
        owner = msg.sender;
        rebaseHandler = _rebaseHandler;
        xbribePaused = true;
    }

    function postInitialize(address[] memory _tokens, address _minter) external {
        require(msg.sender == minter, "!minter");
        for (uint i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
        maxVotesForPool[IVe(ve).token()] = 20;
    }

    function setxBribePause(bool _state) external {
        require(msg.sender == owner);
        xbribePaused = _state;
    }

    // /// @dev Amount of tokens required to be hold for whitelisting.
    // function listingFee() external view returns (uint) {
    //     return _listingFee();
    // }

    // /// @dev 20% of circulation supply.
    // function _listingFee() internal view returns (uint) {
    //     return (IERC20Upgradeable(IVe(ve).token()).totalSupply()) / 5;
    // }

    /// @dev Remove all votes for given tokenId.
    function reset(uint _tokenId) external onlyNewEpoch(_tokenId) {
        require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
        lastVoted[_tokenId] = IMinter(minter).activePeriod();
        _reset(_tokenId);
        IVe(ve).abstain(_tokenId);
    }

    function _reset(uint _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_tokenId][_pool];
            _updateFor(gauges[_pool]);
            weights[_pool] -= _votes;
            votes[_tokenId][_pool] -= _votes;
            if (_votes > 0) {
                IInternalBribe(internal_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                IInternalBribe(external_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                _totalWeight += _votes;
            } else {
                _totalWeight -= _votes;
            }
            emit Abstained(_tokenId, _votes);
        }
        totalWeight -= uint(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
        _reset(_tokenId);
        uint _poolCnt = _poolVote.length;
        int256 _weight = int256(IVe(ve).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
        }

        for (uint i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                //<== CHECK IT'S A VALID GAUGE
                int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0, "duplicate pool");
                require(_poolWeight != 0, "zero power");
                _updateFor(_gauge);
                poolVote[_tokenId].push(_pool);
                weights[_pool] += _poolWeight;
                uint _poolWeights;
                if (weights[_pool] < 0) {
                    _poolWeights = uint(-weights[_pool]);
                } else {
                    _poolWeights = uint(weights[_pool]);
                }
                if (maxVotesForPool[_pool] != 0) {
                    require(_poolWeights <= _calculateMaxVotePossible(_pool), "Max votes exceeded");
                }
                votes[_tokenId][_pool] += _poolWeight;
                if (_poolWeight > 0) {
                    IInternalBribe(internal_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                    IInternalBribe(external_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                } else {
                    _poolWeight = -_poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVe(ve).voting(_tokenId);
        totalWeight += uint(_totalWeight);
        usedWeights[_tokenId] = uint(_usedWeight);
    }

    function _calculateMaxVotePossible(address _pool) internal view returns (uint) {
        uint totalVotingPower = IVe(ve).totalSupply();
        return ((totalVotingPower * maxVotesForPool[_pool]) / 100);
    }

    /// @dev Vote for given pools using a vote power of given tokenId. Reset previous votes.
    function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external onlyNewEpoch(tokenId) {
        require(IVe(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
        require(_poolVote.length == _weights.length, "!arrays");
        require(!onlyAdminCanVote || IVe(ve).isOwnerNFTID(tokenId), "Paused");
        lastVoted[tokenId] = IMinter(minter).activePeriod();
        _vote(tokenId, _poolVote, _weights);
    }

    /// @dev Add token to whitelist. Only pools with whitelisted tokens can be added to gauge.
    function whitelist(address _token) external {
        require(msg.sender == owner, "!VoterOwner");
        _whitelist(_token);
    }

    function removeWhitelist(address _token) external {
        require(msg.sender == owner, "!owner");
        isWhitelisted[_token] = false;
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token], "already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function viewSatinCashLPGaugeAddress() external view returns (address) {
        return SATIN_CASH_LP_GAUGE;
    }

    modifier onlyNewEpoch(uint _tokenId) {
        // ensure new epoch since last vote
        require((IMinter(minter).activePeriod()) > lastVoted[_tokenId], "TOKEN_ALREADY_VOTED_THIS_EPOCH");
        _;
    }

    /// @dev Add a token to a gauge/bribe as possible reward.
    function registerRewardToken(address _token, address _gaugeOrBribe) external {
        require(msg.sender == owner, "!VoterOwner");
        // require(_tokenId > 0, "!token");
        // require(msg.sender == IVe(ve).ownerOf(_tokenId), "!owner");
        // require(IVe(ve).balanceOfNFT(_tokenId) > _listingFee(), "!power");
        IMultiRewardsPool(_gaugeOrBribe).registerRewardToken(_token);
    }

    /// @dev Remove a token from a gauge/bribe allowed rewards list.
    function removeRewardToken(address _token, address _gaugeOrBribe) external {
        require(msg.sender == owner, "!VoterOwner");
        // require(_tokenId > 0, "!token");
        // require(msg.sender == IVe(ve).ownerOf(_tokenId), "!owner");
        // require(IVe(ve).balanceOfNFT(_tokenId) > _listingFee(), "!power");
        IMultiRewardsPool(_gaugeOrBribe).removeRewardToken(_token);
    }

    function createGauge4pool(address _4pool, address _dai, address _usdc, address _usdt, address _cash) external returns (address) {
        require(msg.sender == owner, "!VoterOwner");
        require(gauges[_4pool] == address(0x0), "exists");
        require(isWhitelisted[_dai] && isWhitelisted[_usdc] && isWhitelisted[_usdt] && isWhitelisted[_cash], "!whitelisted");
        address[] memory allowedRewards = new address[](5);
        address[] memory internalRewards = new address[](4);
        allowedRewards[0] = _dai;
        allowedRewards[1] = _usdc;
        allowedRewards[2] = _usdt;
        allowedRewards[3] = _cash;
        allowedRewards[4] = token;
        internalRewards[0] = _dai;
        internalRewards[1] = _usdc;
        internalRewards[2] = _usdt;
        internalRewards[3] = _cash;

        address _internal_bribe = IBribeFactory(bribeFactory).createInternalBribe(internalRewards);
        address _external_bribe = IBribeFactory(bribeFactory).createExternalBribe(allowedRewards);
        address _gauge = IGaugeFactory(gaugeFactory).createGauge(_4pool, _internal_bribe, _external_bribe, ve, allowedRewards, rebaseHandler);
        IInternalBribe(_internal_bribe).setGauge(_gauge);
        is4poolGauge[_gauge] = true;

        IERC20Upgradeable(token).safeIncreaseAllowance(_gauge, type(uint).max);
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_4pool] = _gauge;
        poolForGauge[_gauge] = _4pool;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_4pool);
        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _4pool);
        return _gauge;
    }

    /// @dev Create gauge for given pool. Only for a pool with whitelisted tokens.
    function createGauge(address _pool) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        require(IFactory(factory).isPair(_pool), "!pool");
        (address tokenA, address tokenB) = IPair(_pool).tokens();
        require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");

        address[] memory allowedRewards = new address[](3);
        address[] memory internalRewards = new address[](2);
        allowedRewards[0] = tokenA;
        allowedRewards[1] = tokenB;
        if (token != tokenA && token != tokenB) {
            allowedRewards[2] = token;
        }
        internalRewards[0] = tokenA;
        internalRewards[1] = tokenB;

        address _internal_bribe = IBribeFactory(bribeFactory).createInternalBribe(internalRewards);
        address _external_bribe = IBribeFactory(bribeFactory).createExternalBribe(allowedRewards);
        address _gauge = IGaugeFactory(gaugeFactory).createGauge(_pool, _internal_bribe, _external_bribe, ve, allowedRewards, rebaseHandler);
        IInternalBribe(_internal_bribe).setGauge(_gauge);
        IERC20Upgradeable(token).safeIncreaseAllowance(_gauge, type(uint).max);
        if (IVe(ve).token() == _pool) {
            SATIN_CASH_LP_GAUGE = _gauge;
        }
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
        return _gauge;
    }

    /// @dev A gauge should be able to attach a token for preventing transfers/withdraws.
    function attachTokenToGauge(uint tokenId, address account) external override {
        require(isGauge[msg.sender], "!gauge");
        if (tokenId > 0) {
            IVe(ve).attachToken(tokenId);
        }
        emit Attach(account, msg.sender, tokenId);
    }

    /// @dev Emit deposit event for easily handling external actions.
    function emitDeposit(uint tokenId, address account, uint amount) external override {
        require(isGauge[msg.sender], "!gauge");
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    /// @dev Detach given token.
    function detachTokenFromGauge(uint tokenId, address account) external override {
        require(isGauge[msg.sender], "!gauge");
        if (tokenId > 0) {
            IVe(ve).detachToken(tokenId);
        }
        emit Detach(account, msg.sender, tokenId);
    }

    /// @dev Emit withdraw event for easily handling external actions.
    function emitWithdraw(uint tokenId, address account, uint amount) external override {
        require(isGauge[msg.sender], "!gauge");
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    /// @dev Length of pools
    function poolsLength() external view returns (uint) {
        return pools.length;
    }

    /// @dev Add rewards to this contract. Usually it is SatinMinter.
    function notifyRewardAmount(uint amount) external override {
        require(amount != 0, "zero amount");
        uint _totalWeight = totalWeight;
        // without votes rewards can not be added
        require(_totalWeight != 0, "!weights");
        // transfer the distro in
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        // 1e18 adjustment is removed during claim
        uint _ratio = (amount * 1e18) / _totalWeight;
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, token, amount);
    }

    function setRebaseHandler(address _rebaseHandler) external {
        require(msg.sender == owner, "!VoterOwner");
        rebaseHandler = _rebaseHandler;
    }

    function setRebaseHandlerForGauge(address _gauge, address _rebaseHandler) external {
        require(msg.sender == owner, "!VoterOwner");
        IGauge(_gauge).changeRebaseHandler(_rebaseHandler);
    }

    /// @dev Update given gauges.
    function updateFor(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    /// @dev Update gauges by indexes in a range.
    function updateForRange(uint start, uint end) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    /// @dev Update all gauges.
    function updateAll() external {
        updateForRange(0, pools.length);
    }

    /// @dev Update reward info for given gauge.
    function updateGauge(address _gauge) external {
        _updateFor(_gauge);
    }

    function setOnlyAdminCanVote(bool _onlyAdminCanVote) external {
        require(msg.sender == owner, "!owner");
        onlyAdminCanVote = _onlyAdminCanVote;
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        int256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            // get global index for accumulated distro
            uint _index = index;
            // update _gauge current position to global position
            supplyIndex[_gauge] = _index;
            // see if there is any difference that need to be accrued
            uint _delta = _index - _supplyIndex;
            if (_delta > 0) {
                // add accrued difference for each supplied token
                uint _share = (uint(_supplied) * _delta) / 1e18;
                claimable[_gauge] += _share;
            }
        } else {
            // new users are set to the default global state
            supplyIndex[_gauge] = index;
        }
    }

    /// @dev Batch claim rewards from given gauges.
    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
        }
    }

    /// @dev Batch claim rewards from given bribe contracts for given tokenId.
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
        for (uint i = 0; i < _bribes.length; i++) {
            IInternalBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @dev Claim fees from given bribes.
    function claimFees(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
        require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
        for (uint i = 0; i < _bribes.length; i++) {
            IInternalBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    /// @dev Move fees from deposited pools to bribes for given gauges.
    function distributeFees(address[] memory _gauges) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).claimFees();
        }
    }

    /// @dev Get emission from minter and notify rewards for given gauge.
    function distribute(address _gauge) external override {
        _distribute(_gauge);
    }

    function getVeShare() external override {
        require(msg.sender == veDist);
        uint _veShare = veShare;
        veShare = 0;
        IERC20Upgradeable(token).safeTransfer(msg.sender, _veShare);
    }

    function _distribute(address _gauge) internal nonReentrant {
        IMinter(minter).updatePeriod();
        _updateFor(_gauge);
        uint _claimable = claimable[_gauge];
        if (SATIN_CASH_LP_GAUGE == _gauge && msg.sender == minter) {
            veShare = calculateSatinCashLPVeShare(_claimable);
            claimable[_gauge] -= veShare;
            _claimable -= veShare;
        }
        if (_claimable > IMultiRewardsPool(_gauge).left(token) && _claimable / DURATION > 0) {
            claimable[_gauge] = 0;
            if (is4poolGauge[_gauge]) {
                IGauge(_gauge).notifyRewardAmount(token, _claimable, true);
            } else {
                IGauge(_gauge).notifyRewardAmount(token, _claimable, false);
            }
            emit DistributeReward(msg.sender, _gauge, _claimable);
        }
    }

    /// @dev Distribute rewards for all pools.
    function distributeAll() external override {
        uint length = pools.length;
        for (uint x; x < length; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    function distributeForPoolsInRange(uint start, uint finish) external {
        for (uint x = start; x < finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    function distributeForGauges(address[] memory _gauges) external {
        for (uint x = 0; x < _gauges.length; x++) {
            _distribute(_gauges[x]);
        }
    }

    function calculateSatinCashLPVeShare(uint _claimable) public view returns (uint) {
        address satinCashLPtoken = IVe(ve).token();
        uint _veShare = IERC20Upgradeable(satinCashLPtoken).balanceOf(ve);
        uint totalSupply = IERC20Upgradeable(satinCashLPtoken).totalSupply();
        return (_claimable * _veShare) / totalSupply;
    }

    function setMaxVotesForPool(address _pool, uint _maxAmountInPercentage) external {
        require(msg.sender == owner, "!owner");
        maxVotesForPool[_pool] = _maxAmountInPercentage;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "!owner");
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVe {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint ts;
        uint blk; // block
    }
    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    function token() external view returns (address);

    function ownerOf(uint) external view returns (address);

    function balanceOfNFT(uint) external view returns (uint);

    function isApprovedOrOwner(address, uint) external view returns (bool);

    function createLockFor(uint, uint, address) external returns (uint);

    function userPointEpoch(uint tokenId) external view returns (uint);

    function epoch() external view returns (uint);

    function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

    function lockedEnd(uint _tokenId) external view returns (uint);

    function pointHistory(uint loc) external view returns (Point memory);

    function checkpoint() external;

    function depositFor(uint tokenId, uint value) external;

    function attachToken(uint tokenId) external;

    function detachToken(uint tokenId) external;

    function voting(uint tokenId) external;

    function abstain(uint tokenId) external;

    function totalSupply() external view returns (uint);

    function VeOwner() external view returns (address);

    function isOwnerNFTID(uint _tokenID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {
    function ve() external view returns (address);

    function attachTokenToGauge(uint _tokenId, address account) external;

    function detachTokenFromGauge(uint _tokenId, address account) external;

    function emitDeposit(uint _tokenId, address account, uint amount) external;

    function emitWithdraw(uint _tokenId, address account, uint amount) external;

    function distribute(address _gauge) external;

    function notifyRewardAmount(uint amount) external;

    function gauges(address _pool) external view returns (address);

    function isWhitelisted(address _token) external view returns (bool);

    function internal_bribes(address _gauge) external view returns (address);

    function external_bribes(address _gauge) external view returns (address);

    function getVeShare() external;

    function viewSatinCashLPGaugeAddress() external view returns (address);

    function xbribePaused() external view returns (bool);

    function distributeAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPair {
    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event FeesChanged(uint256 newValue);

    //Structure to capture time period observations every 30 minutes, used for local oracle
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function claimFees() external returns (uint256, uint256);

    function tokens() external view returns (address, address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        );
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFactory {
    function isPair(address pair) external view returns (bool);

    function treasury() external view returns (address);

    function pairCodeHash() external pure returns (bytes32);

    function getPair(address tokenA, address token, bool stable) external view returns (address);

    function paused(address _pool) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGauge {
    function notifyRewardAmount(address token, uint amount, bool is4pool) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint claimed0, uint claimed1);

    function changeRebaseHandler(address _rebaseHandler) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBribeFactory {
    function createInternalBribe(address[] memory) external returns (address);

    function createExternalBribe(address[] memory) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGaugeFactory {
    function createGauge(
        address _pool,
        address _internal_bribe,
        address _external_bribe,
        address _ve,
        address[] memory allowedRewards,
        address rebaseHandler
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMinter {
    function updatePeriod() external returns (uint);

    function activePeriod() external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IInternalBribe {
    function _deposit(uint amount, uint tokenId) external;

    function _withdraw(uint amount, uint tokenId) external;

    function getRewardForOwner(uint tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint amount) external;

    function left(address token) external view returns (uint);

    function setGauge(address _gauge) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiRewardsPool {

  function underlying() external view returns (address);

  function derivedSupply() external view returns (uint);

  function derivedBalances(address account) external view returns (uint);

  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function rewardTokens(uint id) external view returns (address);

  function isRewardToken(address token) external view returns (bool);

  function rewardTokensLength() external view returns (uint);

  function derivedBalance(address account) external view returns (uint);

  function left(address token) external view returns (uint);

  function earned(address token, address account) external view returns (uint);

  function registerRewardToken(address token) external;

  function removeRewardToken(address token) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDist {
    function checkpointToken() external;

    function checkpointTotalSupply() external;

    function claim(uint _tokenId) external returns (uint);

    function checkpointEmissions() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
interface IERC20PermitUpgradeable {
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