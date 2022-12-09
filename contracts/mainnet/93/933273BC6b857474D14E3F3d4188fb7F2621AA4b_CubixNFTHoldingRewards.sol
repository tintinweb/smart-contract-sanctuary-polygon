/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *
 * Cubix NFT holding rewards
 * URL: cubixpro.world/
 *
 */
pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface ERC720 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);
}

interface ERC721 {
    function totalSupply() external view returns (uint256 totalSupply);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CubixNFTHoldingRewards {
    using SafeMath for uint256;

    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingTime;
        uint256 balance;
        uint256 rewardsReleased;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256) public lastSyncOn;
    address[] public optInAddress;
    mapping(address => bool) public optInAddressSaved;

    uint256 public stakingTime = 24 hours;
    uint256 public tokens = 2 * 10**18;

    bool public canClaimTokens = true;
    bool public canStake = true;
    address public ownerAddress;
    address public managerAddress;
    ERC721 public nft;
    ERC720 public token;
    uint256 public tokenDecimals;

    event Claimed(address owner, uint256 amount, uint256 time);
    event NFTStaked(uint256 tokenId, address owner, uint256 enrolled);

    constructor(address _nft, address _token) {
        nft = ERC721(_nft);
        token = ERC720(_token);
        ownerAddress = msg.sender;
        managerAddress = msg.sender;
        tokenDecimals = token.decimals();
    }

modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Only owner');
        _;
    }

    modifier onlyManagement() {
        require(msg.sender == managerAddress, 'Only manager');
        _;
    }

    function changeOwnerShip(address _owner) external onlyOwner {
        ownerAddress = _owner;
    }

    function updateTokens(uint256 _tokens) external onlyManagement {
        tokens = _tokens * 10**18;
    }

    function updateStakingTime(uint256 _stakingTime) external onlyManagement {
        stakingTime = _stakingTime.mul(1 hours);
    }

    function stake(uint256[] calldata tokenIds) public {
        require(canStake, 'Can not stake NFT');
        if (!optInAddressSaved[msg.sender]) {
            optInAddress.push(msg.sender);
            optInAddressSaved[msg.sender] = true;
        }
        for (uint256 index = 0; index < tokenIds.length; index++) {
            _stake(msg.sender, tokenIds[index]);
        }
    }

    function _stake(address _address, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            'You are not owner of NFT'
        );
        if (tokenOwners[_tokenId] != msg.sender) {
            Staker storage staker = stakers[_address];
            staker.tokenIds.push(_tokenId);
            staker.tokenStakingTime[staker.tokenIds.length - 1] = block.timestamp;

            tokenOwners[_tokenId] = msg.sender;

            emit NFTStaked(_tokenId, msg.sender, block.timestamp);
        }
    }
function syncRewards(address _address) public {
        Staker storage staker = stakers[_address];
        uint256[] storage tokenIds = stakers[_address].tokenIds;

        for (uint256 index = 0; index < tokenIds.length; index++) {
            if (tokenOwners[tokenIds[index]] != nft.ownerOf(tokenIds[index])) {
                _unstake(index, _address);
                continue;
            } else if (
                block.timestamp >= 
                staker.tokenStakingTime[index] + stakingTime && 
                staker.tokenStakingTime[index] > 0
            ) {
                uint256 stakedDays = (
                    block.timestamp.sub(staker.tokenStakingTime[index])
                ).div(stakingTime);

                staker.balance = staker.balance.add(tokens.mul(stakedDays));

                uint256 partialTime = (
                    block.timestamp.sub(staker.tokenStakingTime[index])
                ) % stakingTime;

                staker.tokenStakingTime[index] = block.timestamp - partialTime;
            }
        }
        lastSyncOn[_address] = block.timestamp;
    }

    function claim(address _address) public {
        uint256 amount = stakers[_address].balance;
        require(amount > 0, 'No reward found yet');
        stakers[_address].rewardsReleased = stakers[_address]
            .rewardsReleased
            .add(amount);
        token.transfer(_address, amount);
        stakers[_address].balance = 0;
        emit Claimed(_address, amount, block.timestamp);
    }
function checkAndChangeOwner(uint256 _tokenId) public {
        address _owner = nft.ownerOf(_tokenId);
        tokenOwners[_tokenId] = _owner;
    }

    function unstake(uint256[] calldata tokenIds) public {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            _unstake(index, msg.sender);
        }
    }

    function _unstake(uint256 _index, address _address) internal {
        require(_index < stakers[_address].tokenIds.length);
        uint256 lastIndex = stakers[_address].tokenIds.length - 1;

        stakers[_address].tokenIds[_index] = stakers[_address].tokenIds[
            lastIndex
        ];
        stakers[_address].tokenStakingTime[_index] = stakers[_address]
            .tokenStakingTime[lastIndex];

        stakers[_address].tokenIds.pop();
        stakers[_address].tokenStakingTime[lastIndex] = 0;

        if (stakers[_address].tokenIds.length <= 0) {
            delete stakers[_address];
            optInAddressSaved[msg.sender] = false;
        }
    }

    function syncRewardsAll() public {
        for (uint256 index = 0; index < optInAddress.length; index++) {
            if (optInAddressSaved[optInAddress[index]]) {
                syncRewards(optInAddress[index]);
            }
        }
    }

    function getTokenStakingTime(address _address, uint256 index)
        public
        view
        returns (uint256)
    {
        return stakers[_address].tokenStakingTime[index];
    }

    function getTokenId(address _address, uint256 index)
        public
        view
        returns (uint256)
    {
        return stakers[_address].tokenIds[index];
    }

    function getTokenIds(address _address)
        public
        view
        returns (uint256[] memory)
    {
        return stakers[_address].tokenIds;
    }

    function retainUnsedCubix(uint256 amount) external onlyOwner {
        token.transfer(ownerAddress, amount);
    }
}