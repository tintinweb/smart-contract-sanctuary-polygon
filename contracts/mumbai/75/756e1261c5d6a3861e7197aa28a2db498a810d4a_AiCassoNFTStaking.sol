// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IERC721.sol';
import './ERC721Receiver.sol';
import './IAiCassoNFTStaking.sol';

contract AiCassoNFTStaking is IAiCassoNFTStaking, Ownable, ERC721Receiver {
    using Strings for uint256;

    struct Staker {
        uint256[] tokenIds;
        uint256 stakerIndex;
        uint256 balance;
        uint256 lastRewardCalculate;
        uint256 rewardCalculated;
        uint256 rewardWithdrawed;
    }

    struct Reward {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 perMinute;
    }

    struct Withdraw {
        uint256 date;
        uint256 amount;
    }

    mapping (address => Staker) public stakers;
    mapping (uint256 => Reward) public rewards;
    mapping (uint256 => Withdraw) public withdraws;
    address[] public stakersList;

    uint256 public stakedCount;
    uint256 public rewardsCount;
    uint256 public withdrawsCount;

    address public AiCassoNFT;

    modifier onlyParent() {
        require(AiCassoNFT == msg.sender);
        _;
    }

    constructor(address _AiCassoNFT) {
        AiCassoNFT = _AiCassoNFT;
    }

    function deposit() public onlyOwner payable {
        addReward(msg.value);
    }

    function withdrawForOwner(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Insufficient funds');
        payable(msg.sender).transfer(amount);
    }

    function withdraw() public {
        updateReward(msg.sender);

        unchecked {
            Staker storage _staker = stakers[msg.sender];
            Withdraw storage _withdraw = withdraws[withdrawsCount];

            uint256 toWithdraw = _staker.rewardCalculated - _staker.rewardWithdrawed;
            uint256 balance = address(this).balance;

            require(balance >= toWithdraw, 'The function is not available at the moment, try again later');
            _staker.rewardWithdrawed += toWithdraw;

            withdrawsCount += 1;
            _withdraw.date = block.timestamp;
            _withdraw.amount = toWithdraw;

            payable(msg.sender).transfer(toWithdraw);
        }
    }

    function stake(uint256 _tokenId, address _owner) public onlyParent virtual override {
        updateRewardAll();

        unchecked {
            Staker storage _staker = stakers[_owner];

            if (_staker.balance == 0 && _staker.lastRewardCalculate == 0) {
                _staker.lastRewardCalculate = block.timestamp;
                _staker.stakerIndex = stakersList.length;
                stakersList.push(_owner);
            }

            _staker.balance += 1;
            _staker.tokenIds.push(_tokenId);

            stakedCount += 1;
        }
    }

    function unstake(uint256 numberOfTokens) public {
        unchecked {
            Staker storage _staker = stakers[msg.sender];

            require(_staker.balance >= numberOfTokens);

            updateReward(msg.sender);

            for (uint256 i = 0; i < numberOfTokens; i++) {
                _staker.balance -= 1;

                uint256 lastIndex = _staker.tokenIds.length - 1;
                uint256 lastIndexKey = _staker.tokenIds[lastIndex];
                _staker.tokenIds.pop();

                stakedCount -= 1;

                IERC721(AiCassoNFT).transferFrom(
                    address(this),
                    msg.sender,
                    lastIndexKey
                );
            }
        }
    }

    function addReward(uint256 amount) private {
        unchecked {
            Reward storage _reward = rewards[rewardsCount];
            rewardsCount += 1;
            _reward.start = block.timestamp;
            _reward.end = block.timestamp + 30 days;
            _reward.amount = amount;
            _reward.perMinute = amount / 30 days * 60;
        }
    }

    function updateRewardAll() private {
        for (uint256 i = 0; i < stakersList.length; i++) {
            updateReward(stakersList[i]);
        }
    }

    function updateReward(address _user) private {
        unchecked {
            Staker storage _staker = stakers[_user];
            uint256 _rewardCalculated = _getReward(_user);
            _staker.lastRewardCalculate = block.timestamp;
            _staker.rewardCalculated += _rewardCalculated;
        }
    }

    function _getReward(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            uint256 rewardCalculated = 0;

            unchecked {
                for (uint256 i = 0; i < rewardsCount; i++) {
                    Reward storage _reward = rewards[i];
                    if (_reward.end > _staker.lastRewardCalculate) {
                        uint256 startCalculate = _staker.lastRewardCalculate;
                        if (_reward.start > _staker.lastRewardCalculate) {
                            startCalculate = _reward.start;
                        }

                        uint256 minutesReward = (block.timestamp - startCalculate) / 60;
                        uint256 totalReward = minutesReward * _reward.perMinute;
                        uint256 userReward = ((_staker.balance * 10_000 / stakedCount) * totalReward) / 10_000;

                        rewardCalculated += userReward;
                    }
                }
            }

            return rewardCalculated;
        }

        return 0;
    }

    function totalStaked() public view returns (uint256) {
        return stakedCount;
    }


    function totalLastWeekWithdraws() public view returns (uint256) {
        uint256 weekStart = block.timestamp - 7 days;
        uint256 total = 0;

        for (uint256 i = 0; i < withdrawsCount; i++) {
            Withdraw storage _withdraw = withdraws[i];
            if (_withdraw.date >= weekStart) {
                total += _withdraw.amount;
            }
        }
        return total;
    }

    function totalRewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated;
    }

    function percentOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            return (_staker.balance * 10000 / stakedCount) / 100;
        }
        return 0;
    }

    function balanceOf(address _user) public view override returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _staker.balance;
    }

    function rewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated - _staker.rewardWithdrawed;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}