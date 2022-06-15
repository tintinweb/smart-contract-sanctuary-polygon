// SPDX-License-Identifier: -- vitally.eth --

pragma solidity =0.8.14;

import "./TokenWrapper.sol";
import "./EIP712MetaTransaction.sol";

contract LiquidStaking is TokenWrapper, EIP712MetaTransaction {

    IERC20 public manaToken = IERC20(
        0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4
    );

    uint256 constant PRECISION = 1E18;
    address public ownerAddress;

    constructor()
        EIP712Base("LiquidStaking", "v0.1")
    {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress,
            "Ownable: INVALID_OWNER"
        );
        _;
    }

    uint256 public constant DURATION_MIN = 5 weeks;
    address public constant ZERO_ADDRESS = address(0);

    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(
        uint256 reward
    );

    event Staked(
        address indexed user,
        uint256 amount
    );

    event Withdrawn(
        address indexed user,
        uint256 amount
    );

    event RewardPaid(
        address indexed user,
        uint256 reward
    );

    modifier updateReward(
        address account
    ) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != ZERO_ADDRESS) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return block.timestamp < periodFinish
            ? block.timestamp
            : periodFinish;
    }

    function rewardPerToken()
        public
        view
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        uint256 timeFrame = lastTimeRewardApplicable()
            - lastUpdateTime;

        uint256 extraFund = timeFrame
            * rewardRate
            * PRECISION
            / totalSupply();

        return rewardPerTokenStored
            + extraFund;
    }

    function earned(
        address _walletAddress
    )
        public
        view
        returns (uint256)
    {
        uint256 difference = rewardPerToken()
            - userRewardPerTokenPaid[_walletAddress];

        return balanceOf(_walletAddress)
            * difference
            / PRECISION
            + rewards[_walletAddress];
    }

    function stake(
        uint256 _stakeAmount
    )
        public
        updateReward(msgSender())
    {
        require(
            _stakeAmount > 0,
            "lpStaking: INVALID_AMOUNT"
        );

        address senderAddress = msgSender();

        _stake(
            _stakeAmount,
            senderAddress
        );

        emit Staked(
            senderAddress,
            _stakeAmount
        );
    }

    function withdraw(
        uint256 _withdrawAmount
    )
        public
        updateReward(msgSender())
    {
        require(
            _withdrawAmount > 0,
            "lpStaking: INVALID_AMOUNT"
        );

        address senderAddress = msgSender();

        _withdraw(
            _withdrawAmount,
            senderAddress
        );

        emit Withdrawn(
            senderAddress,
            _withdrawAmount
        );
    }

    function exit()
        external
    {
        uint256 withdrawAmount = balanceOf(
            msgSender()
        );

        withdraw(
            withdrawAmount
        );

        getReward();
    }

    function getReward()
        public
        updateReward(msgSender())
        returns (uint256 rewardAmount)
    {
        address senderAddress = msgSender();

        rewardAmount = earned(
            senderAddress
        );

        if (rewardAmount == 0) return 0;

        rewards[senderAddress] = 0;

        safeTransfer(
            manaToken,
            senderAddress,
            rewardAmount
        );

        emit RewardPaid(
            senderAddress,
            rewardAmount
        );
    }

    function changeOwner(
        address _newOwner
    )
        external
        onlyOwner
    {
        ownerAddress = _newOwner;
    }

    function notifyRewardAmount(
        uint256 _rewardAmount
    )
        external
        onlyOwner
        updateReward(ZERO_ADDRESS)
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = _rewardAmount
                / DURATION_MIN;
        }
            else
        {
            uint256 remaining = periodFinish
                - block.timestamp;

            uint256 leftOver = remaining
                * rewardRate;

            uint256 newTotal = _rewardAmount
                + leftOver;

            rewardRate = newTotal
                / DURATION_MIN;
        }

        lastUpdateTime = block.timestamp;

        periodFinish = lastUpdateTime
            + DURATION_MIN;

        emit RewardAdded(
            _rewardAmount
        );
    }
}