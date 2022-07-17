/**
 *Submitted for verification at polygonscan.com on 2022-07-17
*/

// File: contracts/Creativez/token/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}
// File: contracts/Creativez/token/IERC20Metadata.sol


// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// File: contracts/Creativez/token/ERC20.sol


// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}
// File: contracts/Creativez/utils/Context.sol



pragma solidity >=0.7.0 <0.9.0;

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

// File: contracts/Creativez/access/Ownable.sol



pragma solidity >=0.7.0 <0.9.0;


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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/CreativezBIFI.sol



pragma solidity >=0.7.0 <0.9.0;




interface BIFI{
    function approve(address spender, uint256 value) external;
    function getReward() external;
    function balanceOf(address account) external view returns (uint256);
    function exit() external;
    function stake(uint256 amount) external;
    function transferFrom(address from, address to, uint256 value) external;
    function withdraw(uint wad) external;
}

interface External{    
    function approve(address guy, uint256 wad) external; //approve all spendings
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external; 
    function transferFrom(address src, address dst, uint256 rawAmount) external; //this is used to move tokens from one address to another
    function balanceOf(address owner) external view returns (uint); //this is used to check the balance of a specific contract address
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external; //swap to native token
    function userInfo(uint256 _pid, address to) external view returns (uint256, uint256);
    function depositAll() external;
    function stake(uint256 _amount) external;
    function getReward() external;
    function withdraw(uint256 _amount) external;
    function exit() external;
}

contract CreativezBIFI is Ownable{

    constructor(){
        _status = _NOT_ENTERED; 
        BIFI(BIFIContractAddress).approve(Owner, approvalAmount); //approve owner to withdraw BIFI for reinvestments  
        External(WMATIC).approve(QuickswapRouter, approvalAmount); //approve WMATIC on Quickswap
        External(BIFIContractAddress).approve(BeefyRewardPool, approvalAmount); //approve BIFI spend on BeefyRewardPool Contract 
        BIFI(BIFIContractAddress).approve(BeefyRewardPool,approvalAmount);    
    }

/////////////////////////////////////////////////////// Global Variables ///////////////////////////////////////////////////////

    address BeefyRewardPool = 0xDeB0a777ba6f59C78c654B8c92F80238c8002DD2; //this is the beefy finance reward pool we interact with
    address BIFIContractAddress = 0xFbdd194376de19a88118e84E279b977f165d01b8; //this is the BIFI token
    address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //this is the WMatic token
    address QuickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address Owner = 0xE0A4B75537D3840dEE1D49DC01754fEDEB373B10;
    address CreativezDeployerAddrs;
    uint256 BIFIBalance;
    uint256 approvalTopUp = 500;
    uint256 h = 2;
    uint256 i = 1;
    uint256 I = 2;
    uint256 II = 1;
    uint256 multiplier = 10;
    uint256 cumulativeMaticSentToDeployer;
    uint256 cumulativeMaticSentToDevWallet;
    uint256 reward = 200000000000000000; //reward payable to the msg.sender of pushTheButton
    uint256 approvalAmount = 1000000000000000000000000000000000000000000000000000;
    uint256 WMATICInvested;
    address lastPush;
    mapping(address => bool) private banned;

///////////////////////////////////////////////////// End Global Variables ////////////////////////////////////////////////////

//////////////////////////////////////////////////////////// Events ///////////////////////////////////////////////////////////

    //push the button - MATIC sent to Creativez development wallet and Creativez contract
    event WMATICDeposit (
        uint256 WMATICReinvested
    );
    
    event payDay (
        uint256 MaticSentToCreativezRewardPool,
        uint256 MaticSentToDevWallet,
        address buttonPusherAddrs,
        uint256 buttonPushReward,
        uint256 cumulativeMaticSentToDeployer,
        uint256 cumulativeMaticSentToDevWallet
    );

    event cycle (
        uint256 timelocked,
        address sender
    );

    //push the button (j) - WMatic sent to WMatic Distributor 
    event creativezRewardPoolI (
        uint256 WMaticSentToCreativezRewardPool,
        uint256 buttonPushReward,
        address buttonPusherAddrs
    );

///////////////////////////////////////////////////////// End Events //////////////////////////////////////////////////////////

/////////////////////////////////////////////////// Non-Specific Functions ////////////////////////////////////////////////////
    
    //fallback function - allow this contract to be sent WMatic
    function Receiver() public payable {
    }

    receive() external payable {}

    fallback() external payable {}

    //set Creativez.sol address
    function setCreativezDeployerAddrs(address _CreativezDeployerAddrs) public onlyOwner {
        CreativezDeployerAddrs = _CreativezDeployerAddrs;
    }

    //ban an address from participating in earn - manually remove bot addresses
    function banAddrs(address _banAddrs) public onlyOwner {
      banned[_banAddrs] = true;
    }

    //unban an address so they can continue participating in earn
    function unbanAddrs(address _unbanAddrs) public onlyOwner {
      banned[_unbanAddrs] = false;
    }

    //get the balance of BIFI in our contract
    function returnBIFIBalance() public view onlyOwner returns (uint256){
       return BIFI(BIFIContractAddress).balanceOf(address(this));
    }

    function returnWMATICBalance() public view onlyOwner returns (uint256) {
      return External(WMATIC).balanceOf(address(this));
    }

    function returnMATICBalance() public view onlyOwner returns (uint256) {
      return address(this).balance;
    }

    //swap BIFI for MATIC on Quickswap
    function BIFIToMatic() public payable onlyOwner {
                address[] memory path;
                path = new address[](2);
                path[0] = BIFIContractAddress;
                path[1] = WMATIC;
                External(QuickswapRouter).swapExactTokensForETH(External(BIFIContractAddress).balanceOf(address(this)), 1, path, address(this), block.timestamp+1800); 
    }

    //function to exit the BeefyRewardPool - take out the staked BIFI and claim the current WMatic rewards - this may be necessary if Beefy.Finance creates new pools for their token to stake into
    function exitRewardPool () external payable onlyOwner {
        BIFI(BeefyRewardPool).exit();
    }  

    //Reward paid to msg.sender//
    function changeRewardValue(uint _reward) public onlyOwner{
        reward = _reward;
    }

    //withdraw the native token from the smart contract back to owner of contract - can be used to move funds into new treasury investments 
    function withdrawNativeToken() public payable onlyOwner {
        payable (msg.sender).transfer(address(this).balance);
    }

    //withdraw the BIFI token from the smart contract back to owner of contract - can be used to move funds into new treasury investments
    function withdrawBIFIToken() public payable onlyOwner {
        BIFI(BIFIContractAddress).transferFrom(address(this), msg.sender, BIFI(BIFIContractAddress).balanceOf(address(this))); 
    }

    function changeMultiplier(uint256 _multiplier) public onlyOwner {
      multiplier = _multiplier;
    }


//////////////////////////////////////////////////// End Non-Specific Functions ////////////////////////////////////////////////////

////////////////////////////////////////////////////////// Timelock ////////////////////////////////////////////////////////////////

    uint256 _end = 1;
    uint256 _start;
    uint256 _timelocked = 172800; // = 2 days

    //owner can change the amount of time a function will be timelocked
    function timelocked (uint _newtime) public onlyOwner {
        _timelocked = _newtime;
    }

    function start() private {
        _start = block.timestamp;
    }

    function end() private {
        _end = _timelocked+_start;
    }

    //owner can remove timelock from a function that is currently timelocked i.e. require(_end => 0)
    function removeTimelock () public onlyOwner {
        _end = block.timestamp;
    }

    function getTimeLeft() public view returns (uint){
        return _end < block.timestamp ? 0 : _end-block.timestamp;
    }

////////////////////////////////////////////////////////// End timelock ///////////////////////////////////////////////////////////

///////////////////////////////////////////////////////// Reentrancy Guard ////////////////////////////////////////////////////////

    //Reentrancy guard variables
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;
    uint256 _status;

    //Reentrancy guard modifier
     modifier nonReentrant () {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
////////////////////////////////////////////////////// End Reentrancy Guard //////////////////////////////////////////////////////

/////////////////////////////////////////////////////// Push the button :) ///////////////////////////////////////////////////////

    function pushTheButton() public payable nonReentrant{
        require(block.timestamp>_end, "time remains or someone executed before you");
        require(address(this).balance > reward, "bal < reward");
        require(msg.sender != lastPush && banned[msg.sender] != true, "can't push the button twice in a row");
        start();
        if (External(WMATIC).balanceOf(address(this)) > reward*multiplier && I > II) { //change this balance - remember that 1 matic = 1 * 10 ** 18 - for now it is at a good value for testing
              //swap all WMATIC to BIFI
              WMATICInvested += External(WMATIC).balanceOf(address(this));
              emit WMATICDeposit(
                WMATICInvested
              );
              address[] memory path;
              path = new address[](2);
              path[0] = WMATIC;
              path[1] = BIFIContractAddress;
              External(QuickswapRouter).swapExactTokensForTokens(uint(External(WMATIC).balanceOf(address(this))), 1, path, address(this), block.timestamp+1800);
              II++;
              _start -= (_timelocked-120);
              lastPush=msg.sender;
              payable (lastPush).transfer(reward);
        } else if (I == II) {
              //stake BIFI
              BIFI(BeefyRewardPool).stake(BIFI(BIFIContractAddress).balanceOf(address(this)));        
              I++;
              _start -= (_timelocked-120);
              lastPush=msg.sender;
              payable (lastPush).transfer(reward); 
        }
        else if (h > i){
            BIFI(BeefyRewardPool).getReward(); //1.0. Get WMatic Rewards from BeefyStakingPool 
            BIFI(WMATIC).withdraw(BIFI(WMATIC).balanceOf(address(this))); 
            i++;
            lastPush=msg.sender;
            payable (lastPush).transfer(reward);
            }
        else if (i > approvalTopUp) {
                //this is run every 500 cycles to keep the spending allowance high enough for swaps in the QuickSwapRouter and BeQiLP contracts 
                BIFI(BIFIContractAddress).approve(Owner, approvalAmount); //approve owner to withdraw BIFI for reinvestments  
                External(WMATIC).approve(QuickswapRouter, approvalAmount); //approve WMATIC on Quickswap
                External(BIFIContractAddress).approve(BeefyRewardPool, approvalAmount); //approve BIFI spend on BeefyRewardPool Contract 
                BIFI(BIFIContractAddress).approve(BeefyRewardPool,approvalAmount);   
                approvalTopUp += 500;
                lastPush=msg.sender;
                payable (lastPush).transfer(reward); 
        } else {
                uint256 depositDevWallet = uint(address(this).balance*5/100);
                uint256 depositCreativezAddrs = uint(address(this).balance*95/100-reward*3);
                cumulativeMaticSentToDevWallet += depositDevWallet;
                cumulativeMaticSentToDeployer += depositCreativezAddrs;
                emit payDay(depositCreativezAddrs, depositDevWallet, msg.sender, reward, cumulativeMaticSentToDeployer, cumulativeMaticSentToDevWallet);
                payable (owner()).transfer(depositDevWallet); //2.0. Send 5% of Matic to Creativez team development wallet
                payable (CreativezDeployerAddrs).transfer(depositCreativezAddrs); //3.1. Send the remaining MATIC gained from rewards to the Creativez.sol contract for mass distribution - reward *3 to cover the rewards for the next three function calls
                h++;
                lastPush=msg.sender;
                payable (lastPush).transfer(reward);           
            }
            end();
            emit cycle (
                getTimeLeft(),
                msg.sender
            );      
    }
}