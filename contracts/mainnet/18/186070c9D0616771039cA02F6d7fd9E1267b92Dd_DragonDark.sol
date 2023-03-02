/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

//https://dragondark.xyz/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed _from, uint256 _amount);
    event ReferralRewardClaimed(address indexed user, uint256 amount);
    event Referred(address indexed user, address indexed referrer);
    event RewardClaimed(address indexed user, uint256 amount);

}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
        return c;
    }
}


pragma solidity 0.8.12;


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}

pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

pragma solidity 0.8.12;


contract ERC20 is Context, IERC20, IERC20Metadata, ReentrancyGuard {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralRewards;
    mapping(address => bool) private hasClaimedReferralReward;
    mapping(address => uint256) public referredCount;
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
    address private _owner;
    bool public tradeStatus = true;
    bool public airdropStatus = true;
    bool public referralStatus = true;
    IERC20 public token;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastClaim;
    mapping(address => Reward) public rewards;
    mapping (address => bool) private _hasClaimed;
    uint256 public rewardInterval = 1 days;
    uint256 public rewardAPY = 8;
    uint256 public depositFee = 5;
    uint256 public withdrawalFee = 5;
    address payable private feeReceiver_;
    uint256 public constant CLAIM_AMOUNT = 20000000000000000000000;
    uint256 public constant MAX_AMOUNT = 0.00001 ether; 
    uint256 public constant MIN_AMOUNT = 0.000001 ether;
    uint256 public claimCount;
    uint256 public maxClaims = 2000;


struct Reward {
    uint256 rewardEarned;
    uint256 nextClaimTime;
}



    constructor (string memory name_, string memory symbol_,uint256 initialBalance_,uint256 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialBalance_* 10**decimals_;
        _balances[msg.sender] = _totalSupply;
        _decimals = decimals_;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function ChangeStatus(bool _power) public onlyOwner returns (bool) {
        tradeStatus = _power;
        return true;
    }
    function disableAirdrop(bool _airdrop) public onlyOwner returns (bool) {
    airdropStatus = _airdrop;
    return true;
}

   function disablereferral(bool _referral) public onlyOwner returns (bool) {
    referralStatus = _referral;
    return true;
}

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public returns(bool) {
        require(_balances[msg.sender] >= amount, "Amount exceeded");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        return true;
    }

     function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function information() public pure returns(string memory) {
        return "This is not a scam, buy more!";
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

    require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
    }
}

function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {

    require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");

    uint256 SCCC = tokens * addresses.length;

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens);
    }
}
function getTokenBalance() external view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
}

function claimAirdrop() external payable nonReentrant {
    require(airdropStatus == true, "Airdrop is not currently enabled");
    require(msg.value >= MIN_AMOUNT, "Amount too low");
    require(msg.value <= MAX_AMOUNT, "Amount too high");
    require(!_hasClaimed[msg.sender], "Already claimed");
   
    uint256 tokensToTransfer = msg.value.mul(CLAIM_AMOUNT).div(1 ether);
   
    require(tokensToTransfer > 0, "Insufficient amount");
    require(tokensToTransfer <= IERC20(token).balanceOf(address(this)), "Not enough tokens in contract");
   
    IERC20(token).transfer(msg.sender, tokensToTransfer);
    _hasClaimed[msg.sender] = true;
    claimCount = claimCount.add(1);
    if (claimCount == maxClaims) {
        airdropStatus = false;
    }
}

function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

fallback () external payable {
}
receive () external payable {
}

function deposit() public payable {
    require(msg.value > 0, "deposit ether");
    emit Deposit(msg.sender, msg.value);
}
function referUser(address _referrer) public {
    require(referralStatus == true, "referUser is not currently enabled");
    require(referredCount[_referrer] < 50, "Referrer has reached maximum referrals");
    
    referrals[msg.sender] = _referrer;
    emit Referred(msg.sender, _referrer);
    
    if (referralRewards[_referrer] == 0) {
        return;
    }
    
    uint256 referredUsers = 0;
    address currentAddress = _referrer;
    
    while (currentAddress != address(0)) {
        referredUsers++;
        currentAddress = referrals[currentAddress];
    }
    
    uint256 reward = 0;
    
    if (referredUsers >= 50) {
        reward = 50000000000000000000000;
    } else if (referredUsers >= 40) {
        reward = 40000000000000000000000;
    } else if (referredUsers >= 30) {
        reward = 30000000000000000000000;
    } else if (referredUsers >= 20) {
        reward = 20000000000000000000000;
    } else if (referredUsers >= 10) {
        reward = 10000000000000000000000;
    }
    
    referralRewards[_referrer] += reward;
    referredCount[_referrer]++;
}
function getReferralLink() public view returns (string memory) {
    address userAddress = msg.sender;
    string memory link = "https://dragondark.xyz/?ref=";
    link = string(abi.encodePacked(link, toAsciiString(userAddress)));

    return link;
}

function toAsciiString(address x) public pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
}
function char(bytes1 b) public pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
}

function claimReferralReward() public nonReentrant {
    require(referralStatus == true, "referUser is not currently enabled");
    require(referralRewards[msg.sender] > 0, "No referral reward to claim");
    require(!hasClaimedReferralReward[msg.sender], "You have already claimed your referral reward");
    uint256 rewardAmount = referralRewards[msg.sender];
    referralRewards[msg.sender] = 0;
    require(rewardAmount <= IERC20(token).balanceOf(address(this)), "Not enough tokens in contract");
    require(token.transfer(msg.sender, rewardAmount), "Token transfer failed");
    emit ReferralRewardClaimed(msg.sender, rewardAmount);
}

function clearETH(address payable _withdrawal) public onlyOwner {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}

 function staking() external payable {
    require(msg.value > 0, "Amount must be greater than zero");
    uint256 fee = (msg.value * depositFee) / 100;
    require(fee <= msg.value, "Fee cannot exceed deposit");
    require(address(this).balance >= fee, "Insufficient balance for fee");
    uint256 amountAfterFee = msg.value - fee;
    require(amountAfterFee > 0, "Amount after fee must be greater than zero");
    balances[msg.sender] += amountAfterFee;
    lastClaim[msg.sender] = block.timestamp;
    feeReceiver_.transfer(fee);
}


function withdraw() external payable nonReentrant {
    require(msg.value > 0, "Amount must be greater than zero");
    require(msg.value <= balances[msg.sender], "Insufficient balance");
    uint256 fee = (msg.value * withdrawalFee) / 100;
    uint256 amountAfterFee = msg.value - fee;
    require(amountAfterFee > 0, "Amount after fee must be greater than zero");
    require(address(this).balance >= fee, "Insufficient contract balance for fee");
    (bool success, ) = msg.sender.call{value: amountAfterFee}("");
    require(success, "Transfer failed");
    balances[msg.sender] -= amountAfterFee;
    lastClaim[msg.sender] = block.timestamp;
    if (fee > 0) {
        (bool feeSuccess, ) = feeReceiver_.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
    }
}

function claimReward() external nonReentrant {
    require(block.timestamp >= rewards[msg.sender].nextClaimTime, "Error: reward not available yet");
    
    uint256 reward = calculateReward(msg.sender);
    require(reward > 0, "Error: no reward to claim");
    require(token.balanceOf(msg.sender) >= reward, "Error: failed to transfer reward tokens");

    
    rewards[msg.sender].rewardEarned = rewards[msg.sender].rewardEarned.sub(reward);
    rewards[msg.sender].nextClaimTime = block.timestamp.add(rewardInterval);
    require(token.balanceOf(address(this)) >= reward, "Error: insufficient reward balance in contract");
    require(token.transfer(msg.sender, reward), "Error: failed to transfer reward tokens");
    
    emit RewardClaimed(msg.sender, reward);
}

function calculateReward(address _account) public view returns (uint256) {
    uint256 timeDiff = block.timestamp - lastClaim[_account];
    uint256 rewardPerSecond = balances[_account] * rewardAPY / 100 / 365 / 86400;
    return timeDiff * rewardPerSecond;
}

function getMATICBalance() external view returns (uint256) {
   return address(this).balance;
}
}

pragma solidity ^0.8.0;


contract DragonDark is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address payable feeReceiver_
    ) payable ERC20(name_, symbol_,initialBalance_,decimals_) {
        feeReceiver_ = feeReceiver_;
        token = IERC20(address(this));
    }
}