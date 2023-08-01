/**
 *Submitted for verification at polygonscan.com on 2023-07-30
*/

// SPDX-License-Identifier: MIT

/*
The Rebasefy Protocol
Rebasefy is a DAO governance protocol with a set of management features to 
protect the asset and earn profit with each new rebase.

Website and dApp:
    https://rebasefy.com

Doc's and support
    docs.rebasefy.com
    [email protected]
*/

pragma solidity 0.8.18;


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 */
 library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}  

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);
  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);
  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

/**
 * @dev Provide basic functionality for integration with the rebase contract
 */
interface IERC20Rebase {
    function mint(address _to, uint256 _value) external returns (bool); 
    function burn(address _account, uint256 _value) external returns (bool); 
    function rebase(uint256 _perc) external returns (bool); 
}

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


/*
* The SysCtrl service acts as an interface to manage the smart contract project 
* through secure multisig contracts or DAO-signed timelocks.
*/
contract SysCtrl is Context {

  address public communityDAO;
  bool public rebasePaused = false;

  constructor() {
      communityDAO = _msgSender();
  }

  modifier onlyDAO() {
    require(_msgSender() == communityDAO, "Only for DAO community");
    _;
  }

  modifier notPaused() {
    require(!rebasePaused, "Contract paused by DAO");
    _;
  }

  function setDAO(address _new) public onlyDAO {
    communityDAO = _new;
  }
  
  function rebasePause(bool _paused) external onlyDAO {
        rebasePaused = _paused;
  }
  
}

/*
* Management agreement for ecosystem tokens signed by DAO
*/
contract CoinsRebase is SysCtrl {
    
    using SafeMath for uint256;

    event NewLeader(uint256 indexed coinID, address indexed leader, uint256 stake, address indexed old_leader);
    event NewBonus(uint256 indexed coinID, address indexed leader, uint256 bonus, uint256 old_bonus);

    uint256 nextCoin = 1;   
    struct CoinStruct {
        bool active;           
        bool native;           
        address token;         
        address leader;
        uint256 leader_bonus;
        uint256 leader_stake;
    }

    mapping (uint256 => CoinStruct) public coins;

    function addCoin(bool _native, address _token) external onlyDAO returns (bool) {
        CoinStruct memory coinStruct;
        coinStruct = CoinStruct({
            active: true,
            native: _native,
            token: _token,
            leader: address(0),
            leader_bonus: 0, 
            leader_stake: 0  
        });
        coins[nextCoin] = coinStruct;    
        nextCoin++;
        return true;
    }

    function activeCoin(uint256 _coinID) external onlyDAO returns (bool) {
        coins[_coinID].active = true;
        return true;
    }

    function desactiveCoin(uint256 _coinID) external onlyDAO returns (bool) {
        coins[_coinID].active = false;
        return true;
    }

    function adjustCoin(uint256 _coinID, bool _native, address _token) external onlyDAO returns (bool) {
        coins[_coinID].native = _native;
        coins[_coinID].token = _token;
        return(true);
    }

}

/**
 * @title DAO rebasefy management contract
 * @dev see https://github.com/rebasefy
 */
contract rebasefy is CoinsRebase{

    using SafeMath for uint256;

    event Exchange(
        address indexed account, 
        uint256 indexed coinIN, 
        uint256 indexed coinOUT, 
        uint256 amount,
        uint256 fee,
        uint256 epoch
    );

    event Rebase (
        uint256 indexed epoch, 
        address indexed exec, 
        uint256 supplyR,
        uint256 supplyG, 
        uint256 supplyB,
        uint256 rebaseR,
        uint256 rebaseG,
        uint256 rebaseB,
        uint256 lcR,
        uint256 lcG,
        uint256 lcB
    );

    event BuyRebase(
        uint256 indexed coin,
        address indexed buy,
        uint256 value,
        uint256 indexed epoch
    );
    
    event SellRebase(
        uint256 indexed coin,
        address indexed sell,
        uint256 value,
        uint256 fee,
        uint256 indexed epoch
    );

    uint256 epoch = 1;
    uint256 lastRebase = 0;
    uint256 minTimeRebase;
    uint256 minTimeFee;
    uint256 minTimeLock;   
    uint256 exfee24h;
    uint256 sellfee;
    uint256 rebasePerc1;
    uint256 rebasePerc2;
    uint256 rebasePerc3;
    uint256 maxleader_bonus; 
    uint256 public minOrder;
     
    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier waitRebase {
        require(lastRebase+minTimeRebase > block.timestamp,"Wait for rebase operation");
         _;
    }
    modifier waitTimeFee {
        require(lastRebase+(minTimeRebase-(minTimeFee+minTimeLock)) > block.timestamp,"Wait for hard period");
         _;
    }
    modifier waitTimeLock {
        require(lastRebase+(minTimeRebase-minTimeLock) > block.timestamp,"Wait for time lock period");
         _;
    }

    constructor() {
        minTimeRebase = (25*60*60);
        minTimeFee = (45*60);  
        minTimeLock = (15*60);             
        exfee24h = 500;           
        sellfee  = 25000;         
        rebasePerc1 = 1000;      
        rebasePerc2 = 500;        
        rebasePerc3 = 250;        
        maxleader_bonus = 1000;  
        minOrder = 0; 
    }

    function buyRebase(uint256 _coin) external payable reentrancyGuard notPaused waitRebase returns (bool){
        require(coins[_coin].native, "Unsupported coin");
        require(coins[_coin].active, "Coin deactivated");
        require(msg.value > minOrder, "Value cannot be empty");
        
        IERC20Rebase(coins[_coin].token).mint(_msgSender(),msg.value);
        emit BuyRebase(
            _coin,
            _msgSender(),
            msg.value,
            epoch
        );
        return true;
    }

    function sellRebase(uint256 _coin, uint256 _amount) external reentrancyGuard notPaused waitRebase returns (bool){
        require(coins[_coin].native, "Unsupported coin");
        require(coins[_coin].active, "Coin deactivated");
        require(_amount > 0, "Value cannot be empty");
        require(IERC20(coins[_coin].token).balanceOf(_msgSender()) >= _amount,"Insufficient funds");
        
        IERC20Rebase(coins[_coin].token).burn(_msgSender(),_amount); 
        payable(msg.sender).transfer(_amount - (_amount.div(100000).mul(sellfee)));
        
        emit SellRebase(
            _coin,
            _msgSender(),
            _amount,
            sellfee,
            epoch
        );
        return true;
    }

    function swap(uint256 _coinIN, uint256 _coinOUT, uint256 _amount) external reentrancyGuard notPaused waitTimeLock returns (bool){
        require(coins[_coinIN].native && coins[_coinOUT].native,"Unsupported coin");
        require(coins[_coinIN].active && coins[_coinOUT].active,"Coin deactivated");
        require(_amount > 0, "Value cannot be empty");
        require(IERC20(coins[_coinIN].token).balanceOf(_msgSender()) >= _amount,"Insufficient funds");

        // A fee is applied when the operation takes place after 24 hours of the previous rebase
        uint256 exfee = 0;
        if(lastRebase+(minTimeRebase-(minTimeFee+minTimeLock)) < block.timestamp){
          exfee = _amount.div(100000).mul(exfee24h);
        }

        IERC20Rebase(coins[_coinIN].token).burn(_msgSender(),_amount); 
        IERC20Rebase(coins[_coinOUT].token).mint(_msgSender(),_amount-exfee);

        emit Exchange(_msgSender(), _coinIN, _coinOUT, _amount, exfee, epoch);
      
        return(true);
    }

    function rebase() external reentrancyGuard notPaused returns (bool){
        require(lastRebase+minTimeRebase <= block.timestamp, "Rebase not allowed, time not expired");
        require (coins[1].active, "non-active token 1");
        require (coins[2].active, "non-active token 2");
        require (coins[3].active, "non-active token 3");
        return _rebase();
    }
      
    function election(uint256 _coinID, uint256 _amount) external reentrancyGuard notPaused waitTimeLock returns (bool){
        require(_coinID > 0 && _coinID <= 3, "This coin is not applied to a leader");
        require (coins[_coinID].active, "non-active coin");
        require(_amount >= ((coins[_coinID].leader_stake*105)/100), "Value below the minimum to become a leader");  // Need 5% or more

        IERC20(coins[_coinID].token).transferFrom(_msgSender(), address(this), _amount);

        // Returns stacked amount of the old leader
        if(coins[_coinID].leader_stake > 0){
            IERC20(coins[_coinID].token).transfer(coins[_coinID].leader, coins[_coinID].leader_stake);
        }

        emit NewLeader(_coinID, _msgSender(), _amount, coins[_coinID].leader);

        // New data for new leader
        coins[_coinID].leader = _msgSender();
        coins[_coinID].leader_stake = _amount;
        
        return true;
    }

    function bonusLeader(uint _coinID, uint256 _bonus) external notPaused waitTimeFee returns (bool){

        require(coins[_coinID].leader == _msgSender(),"Action allowed only by the leader");
        require(_bonus <= maxleader_bonus,"Greater than the maximum allowed");
        
        uint256 old_bonus = coins[_coinID].leader_bonus;
        coins[_coinID].leader_bonus = _bonus;

        emit NewBonus(_coinID, coins[_coinID].leader, _bonus, old_bonus);

        return(true);
    }

    function info() external view returns (
        uint256 _nextCoin,
        uint256 _epoch,
        uint256 _lastRebase,
        uint256 _minTimeRebase,
        uint256 _minTimeFee,
        uint256 _minTimeLock,   
        uint256 _exfee24h,
        uint256 _sellfee,
        uint256 _rebasePerc1,
        uint256 _rebasePerc2,
        uint256 _rebasePerc3,
        uint256 _maxleader_bonus
    ) {
        _nextCoin = nextCoin;
        _epoch = epoch;
        _lastRebase = lastRebase;
        _minTimeRebase = minTimeRebase;
        _minTimeFee = minTimeFee;
        _minTimeLock = minTimeLock;
        _exfee24h = exfee24h;
        _sellfee = sellfee;
        _rebasePerc1 = rebasePerc1;
        _rebasePerc2 = rebasePerc2;
        _rebasePerc3 = rebasePerc3;
        _maxleader_bonus = maxleader_bonus;
    }

    function configDAO(
        uint256 _minTimeRebase,
        uint256 _minTimeFee,
        uint256 _minTimeLock,   
        uint256 _exfee24h,
        uint256 _sellfee,
        uint256 _rebasePerc1,
        uint256 _rebasePerc2,
        uint256 _rebasePerc3,
        uint256 _maxleader_bonus,
        uint256 _minOrder 
    ) external onlyDAO returns (bool){
        minTimeRebase = _minTimeRebase;
        minTimeFee = _minTimeFee;
        minTimeLock = _minTimeLock;
        exfee24h = _exfee24h;
        sellfee = _sellfee;
        rebasePerc1 = _rebasePerc1;
        rebasePerc2 = _rebasePerc2;
        rebasePerc3 = _rebasePerc3;
        maxleader_bonus = _maxleader_bonus;
        minOrder = _minOrder;
        return(true);
    }
  
    
    function _rebase() internal returns (bool success) {
        uint256 cR = 0;
        uint256 cG = 0;
        uint256 cB = 0;

        uint256 bR =  IERC20(coins[1].token).totalSupply();
        uint256 bG =  IERC20(coins[2].token).totalSupply();
        uint256 bB =  IERC20(coins[3].token).totalSupply();
            
        if(bR >= bG && bR >= bB) {
          cR = rebasePerc3;
          if(bG >= bB) {
            cG = rebasePerc2;
            cB = rebasePerc1;
          } else {
            cG = rebasePerc1;
            cB = rebasePerc2;
          }
        } else if (bG >= bR && bG >= bB) {
          cG = rebasePerc3;
          if(bR >= bB) {
            cR = rebasePerc2;
            cB = rebasePerc1;
          } else {
            cR = rebasePerc1;
            cB = rebasePerc2;
          }
        } else {
          cB = rebasePerc3;
          if(bR >= bG) {
            cR = rebasePerc2;
            cG = rebasePerc1;
          } else {
            cR = rebasePerc1;
            cG = rebasePerc2;
          }
        }    

        // Rebase for all 
        IERC20Rebase(coins[1].token).rebase(cR+coins[1].leader_bonus); 
        IERC20Rebase(coins[2].token).rebase(cG+coins[2].leader_bonus); 
        IERC20Rebase(coins[3].token).rebase(cB+coins[3].leader_bonus); 

        // Leaders payment
        IERC20Rebase(coins[1].token).mint(coins[1].leader, bR.div(100000).mul(maxleader_bonus-coins[1].leader_bonus));
        IERC20Rebase(coins[2].token).mint(coins[2].leader, bG.div(100000).mul(maxleader_bonus-coins[2].leader_bonus));
        IERC20Rebase(coins[3].token).mint(coins[3].leader, bB.div(100000).mul(maxleader_bonus-coins[3].leader_bonus));
      
        emit Rebase (
            epoch, 
            _msgSender(),
            bR,
            bG, 
            bB,
            cR,
            cG,
            cB,
            coins[1].leader_bonus,
            coins[2].leader_bonus,
            coins[3].leader_bonus
        );
        lastRebase = block.timestamp;
        epoch++;
        return true;
    }
}