//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IGrasslandStrategy.sol";

contract GrasslandChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // total of shares the user has on the pool if it is a vault
    }

    struct PoolInfo {
        IERC20 stakeToken;
        IGrasslandStrategy strategy;
        uint16 withdrawFee;
    }

    address public feeAddress;
    address public gasAddress;
    address public performanceAddress;

    uint256 private constant MAX_INT_TYPE = type(uint256).max;
    uint256 private constant FEES_DIVIDER = 10000;

    uint256 public constant MAX_WITHDRAW_FEES = 50;

    // Info of each Pool
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => bool) public strategyExistence; // map used to ensure strategies cannot be added twice

    mapping(address => bool) public operators;

    modifier nonDuplicatedStrategy(IGrasslandStrategy _strategy) {
        require(
            strategyExistence[address(_strategy)] == false,
            "nonDuplicated: duplicated"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            operators[msg.sender],
            "onlyOperator: Caller is not the operator"
        );
        _;
    }

    modifier onlyEndUser() {
        require(!Address.isContract(msg.sender) && tx.origin == msg.sender);
        _;
    }

    event AddPool(address indexed strat);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetGasAddress(address indexed user, address indexed newAddress);
    event SetPerformanceAddress(
        address indexed user,
        address indexed newAddress
    );
    event SetOperator(address indexed operator, bool indexed status);
    event SetStrategySwapPath(
        IGrasslandStrategy _strategy,
        address _token0,
        address _token1,
        address[] _path
    );

    constructor(
        address _feeAddress,
        address _gasAddress,
        address _performanceAddress
    ) {
        operators[msg.sender] = true;
        feeAddress = _feeAddress;
        gasAddress = _gasAddress;
        performanceAddress = _performanceAddress;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(IGrasslandStrategy _strategy, uint16 _withdrawFee)
        external
        onlyOwner
        nonReentrant
        nonDuplicatedStrategy(_strategy)
    {
        require(
            _withdrawFee <= MAX_WITHDRAW_FEES,
            "add: invalid withdraw fee basis points"
        );
        IERC20 stakeToken = IERC20(_strategy.stakeToken());
        poolInfo.push(
            PoolInfo({
                stakeToken: stakeToken,
                strategy: _strategy,
                withdrawFee: _withdrawFee
            })
        );
        strategyExistence[address(_strategy)] = true;
        resetSingleAllowance(poolInfo.length.sub(1));
        emit AddPool(address(_strategy));
    }

    /**
     * @notice view function that returns the amount of staked tokens by a user
     * @param _pid the pool id
     * @param _user address of the user
     */
    function stakedTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        IGrasslandStrategy strategy = pool.strategy;

        uint256 sharesTotal = strategy.sharesTotal();
        uint256 totalStakeTokens = strategy.totalTokens();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(totalStakeTokens).div(sharesTotal);
    }

    /**
     * Transfer tokens from the user to the strategy and executes strategy deposit function
     * to stake them in the underlying farm
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        _deposit(_pid, _amount, msg.sender);
    }

    // For unique contract calls
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external nonReentrant onlyOperator {
        _deposit(_pid, _amount, _to);
    }

    /**
     * Calls strategy earn function to harvest rewards from the underlying farm
     * Transfers amount to the strategy and calls strategy deposit function to calculate
     * the shares assigned to the user
     */
    function _deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) internal {
        require(_amount > 0, "desposit: amount should be greater than zero");
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];

        if (pool.strategy.sharesTotal() > 0) {
            _tryEarn(pool.strategy);
        }

        uint256 balanceBefore = pool.stakeToken.balanceOf(
            address(pool.strategy)
        );
        pool.stakeToken.safeTransferFrom(
            address(msg.sender),
            address(pool.strategy),
            _amount
        );
        _amount = pool.stakeToken.balanceOf(address(pool.strategy)).sub(
            balanceBefore
        );

        uint256 sharesAdded = pool.strategy.deposit(_amount);
        user.shares = user.shares.add(sharesAdded);

        emit Deposit(_to, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        _withdraw(_pid, _amount, msg.sender);
    }

    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) internal {
        require(_amount > 0, "_withdraw: amount must be greater than zero");
        UserInfo storage user = userInfo[_pid][_to];
        require(
            user.shares > 0,
            "_withdraw: user.shares shoul be greater than zero"
        );
        PoolInfo memory pool = poolInfo[_pid];
        IGrasslandStrategy strategy = pool.strategy;

        uint256 sharesTotal = strategy.sharesTotal();
        require(
            sharesTotal > 0,
            "_withdraw: sharesTotal should be greater than zero"
        );

        _tryEarn(strategy);

        uint256 amount = user.shares.mul(strategy.totalTokens()).div(
            sharesTotal
        );

        if (_amount > amount) {
            _amount = amount;
        }

        if (_amount > 0) {
            uint256 sharesRemoved = strategy.withdraw(
                _amount,
                _to,
                pool.withdrawFee
            );

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }
        }
        emit Withdraw(_to, _pid, _amount);
    }

    // Withdraw everything from pool for yourself
    function withdrawAll(uint256 _pid) external nonReentrant {
        _withdraw(_pid, MAX_INT_TYPE, msg.sender);
    }

    function setFeeAddress(address _feeAddress) external {
        require(
            _feeAddress != address(0) &&
                (msg.sender == feeAddress || msg.sender == owner()),
            "setFeeAddress: forbidden"
        );
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setGasAddress(address _gasAddress) external {
        require(
            _gasAddress != address(0) &&
                (msg.sender == gasAddress || msg.sender == owner()),
            "setFeeAddress: forbidden"
        );
        gasAddress = _gasAddress;
        emit SetGasAddress(msg.sender, _gasAddress);
    }

    function setPerformanceAddress(address _performanceAddress) external {
        require(
            _performanceAddress != address(0) &&
                (msg.sender == performanceAddress || msg.sender == owner()),
            "setFeeAddress: forbidden"
        );
        performanceAddress = _performanceAddress;
        emit SetPerformanceAddress(msg.sender, _performanceAddress);
    }

    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit SetOperator(_operator, _status);
    }

    function _tryEarn(IGrasslandStrategy _strategy) internal nonReentrant {
        try _strategy.earn() {} catch {}
    }

    function setStrategySwapPath(
        IGrasslandStrategy _strategy,
        address _token0,
        address _token1,
        address[] calldata _path
    ) external onlyOwner {
        require(
            _path.length > 1,
            "setStrategySwapPath: Path must have more than 1 elements "
        );
        // the first element must be token0 and the last one token1
        require(
            _path[0] == _token0 && _path[_path.length - 1] == _token1,
            "setStrategySwapPath: Invalid path"
        );

        _strategy.setSwapPath(_token0, _token1, _path);
        emit SetStrategySwapPath(_strategy, _token0, _token1, _path);
    }

    function resetSingleAllowance(uint256 _pid) public onlyOwner {
        PoolInfo memory pool = poolInfo[_pid];
        pool.stakeToken.safeApprove(address(pool.strategy), uint256(0));
        pool.stakeToken.safeIncreaseAllowance(
            address(pool.strategy),
            MAX_INT_TYPE
        );
    }

    function resetAllowances() external onlyOwner {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo memory pool = poolInfo[i];
            pool.stakeToken.safeApprove(address(pool.strategy), uint256(0));
            pool.stakeToken.safeIncreaseAllowance(
                address(pool.strategy),
                MAX_INT_TYPE
            );
        }
    }
}