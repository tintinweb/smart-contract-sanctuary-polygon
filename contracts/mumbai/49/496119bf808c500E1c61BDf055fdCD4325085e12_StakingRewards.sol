// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface A0TheStupidestKidsNFTs {

  receive () external payable;

  function mint(address _to, uint256 _id) external payable;
  function mintLegendary(uint256 _id) external;
  function needToUpdateCost (uint256 _id) external;
  function payForNFTUtilities(address _user, uint _payment) external;
  function renewAttacks() external;
  function attach() external;

  function earnedRewardPointsCounter() external;
  function burnRewardPoints(address _address) external returns (uint);

  function onlyMintNFTs(bool _bool) external;
  function setURI(uint _id, string memory _uri) external;
  function activateSecondPresale () external;
  function ActivateClaimReward(bool _bool)external;
  function reveal() external;

  function uPoints(address _user) external view returns (uint);
  function getAllNFTs() external view returns(uint[] memory);
  function uri(uint _id) external view returns (string memory);
  function areAvailableNFTs () external view returns (bool[] memory );
  function getRewardPoints(address _address) external view returns (uint);
  function getFuturePoints(address _address)external view returns(uint);

  function _burnBatch(
      address from,
      uint256[] memory ids,
      uint256[] memory amounts
  ) external;
  function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
  
  function getTotalNFTs(address _address)external view returns(uint);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract StakingRewards {
    
    using SafeMath for uint256;
    
    IERC20 public rewardsToken;
    A0TheStupidestKidsNFTs public stakingToken;
    
    uint public rewardRate; // seconds
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    
    address owner;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(uint => mapping(address => uint)) public userStakingToken;

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    
    constructor() {}
    
    function setToken(A0TheStupidestKidsNFTs _stakingToken, address _rewardsToken, uint _rate) public onlyOwner {
        stakingToken = A0TheStupidestKidsNFTs(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        owner = msg.sender;
        setRewardRate(_rate);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setRewardRate (uint _rate) internal onlyOwner{
        rewardRate = _rate.div(1000);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored.add(((block.timestamp.sub(lastUpdateTime)) .mul(rewardRate).mul(1e18)).div(_totalSupply));
    }

    function earned(address account) public view returns (uint) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    // TODO hace falta darle approve a este contrato para manejar el nft
    // TODO crear un mapping y asi consultar si tiene ya en nft en staking, sino se suma al staking
    function stake(uint _amount) external updateReward(msg.sender) {
        uint userAllNFTs = stakingToken.getTotalNFTs(msg.sender);
        require(userAllNFTs <= _balances[msg.sender], "You've all your NFTs in staking");
        
        require(_amount > 0, "Cannot stake 0");
        // stakingToken.safeTransferFrom(msg.sender, address(this), _id, _amount, "");
        
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        // stakingToken.safeTransferFrom(address(this), msg.sender, _id, _amount, "");
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}