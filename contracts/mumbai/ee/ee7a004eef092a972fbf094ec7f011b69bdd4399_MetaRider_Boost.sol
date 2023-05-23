/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

/**   ===========================ERROR-CODE===============================


EC-01 => INVALID_OWNER/CALLER IS NOT AN OWNER

EC-02 => ADRESS CAN'T BE ZERO ADDRESS

EC-03 => USER DOESN'T EXISIT 

EC-04 => SPONSER DOESN'T EXISIT

EC-05 => You can`t be referal/You allready registred

EC-06 => This level is already activated / Wrong level

EC-07 => Previous level not activated

EC-08 => User not exists, Buy First Level / Buy Previous level first!

EC-09 => s9 level already activated

EC-10 => user /sponser doesn't exisit

EC-11 => cannot be a contract

EC-12 => invalid level

EC-13 => level already activated

EC-14 => 500. Referrer level is inactive

EC-15 => 

EC-16 =>

EC-17 =>

EC-18 =>

EC-19 =>

EC-20 =>


*/




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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
       
        _onlyOwner();
        _;
    }

    function _onlyOwner() view private {
         require(owner() == _msgSender(), "EC-01");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "EC-02");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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



//===============================ERROR-CODE================================

/**

You are not registred  ==> 01

Register Account First  ==> 02





*/





contract MetaRiderCore is Ownable {

  IERC20 public tokenMetaRider;

}



abstract contract Referal is MetaRiderCore {

  modifier isRegistred {
    require(users[_msgSender()].parent != address(0), "EC-02");
    _;
  }

  struct User {
    bool autoReCycle;
    bool autoUpgrade;
    address parent;
    address[] childs;
  }

  mapping(address => User) public users;


  mapping(address => mapping(uint => bool)) public activate; // user -> lvl -> active

  uint32 public lastId;

   struct UserAccount {
        uint32 id;
        uint32 directSales;
       
        bool exists;
        uint8[] activeSlot;
        address sponsor;
       
    }

    mapping(address => mapping(uint8 => S9)) public s9Slots;
     uint8 public constant S9_LAST_LEVEL = 12;
     uint internal reentry_status;
 
struct S9 {
        address sponsor;
        uint32 directSales;
        uint16 cycleCount;
        uint8 passup;
        uint8 cyclePassup;
        uint8 reEntryCheck;
        uint8 placementPosition;
        uint8 lastOneLevelCount;
        uint8 lastTwoLevelCount;
        uint8 lastThreeLevelCount;
        address[] firstLevel;
        address placedUnder;

    }
     mapping(address => UserAccount) public userAccounts;
    mapping(uint32 => address) public idToUserAccount;
    mapping(address => mapping(uint => bool)) public activateS9; // user -> lvl -> active
       modifier isUserAccount(address _addr) {
           
        require(userAccounts[_addr].exists, "EC-03");
        _;
    }

  constructor(){

      /// Set first User
     
      users[_msgSender()] = User(false,false,_msgSender(),new address[](0));
      for (uint i = 0; i < 12; i++) {
          activate[_msgSender()][i] = true;
      } 


      createAccount(_msgSender(), _msgSender(), true);

      
  }

  

   function createAccount(address _user, address _sponsor, bool _initial) internal {

        require(!userAccounts[_user].exists, "EC-03");

        if (_initial == false) {
            require(userAccounts[_sponsor].exists, "EC-04");
        }

        lastId++;

          userAccounts[_user] = UserAccount({
             id: lastId,
             sponsor: _sponsor,
             exists: true,
             directSales: 0,
             activeSlot: new uint8[](2)
         });

      

        idToUserAccount[lastId] = _user;

        

    }



  function getChilds() view external returns(address[] memory) {
    return users[_msgSender()].childs;
  }

  function _isActive(address _address, uint _lvl) internal view returns(bool) {
      return activate[_address][_lvl];
  }

}


abstract contract Programs is Referal {
  mapping(uint => Product) public products;
  //mapping(uint8 => uint) public s9LevelPrice;

  enum Product {
      s2,
      s4,
      s8,
      s9
  }

  

    uint[12] public prices;
   
   

  constructor(){
    
   for (uint i = 0; i < 12; i++) {
       if(i == 0 || i == 4 || i == 8)
        {
            products[i]=Product.s2;
        }
        else if(i == 1 || i == 5 || i == 9)
        {
            products[i]=Product.s4;
        }
        else if(i == 2 || i == 6 || i == 10)
        {
            products[i]=Product.s8;
        }
        else{
            products[i]=Product.s9;
        }
       
    }


    prices[0] = 5 * (10 ** 18); // 2x
    prices[1] = 10 * (10 ** 18);// 4x
    prices[2] = 15 * (10 ** 18);// 8x
    prices[3] = 30 * (10 ** 18);// 9x
    prices[4] = 50 * (10 ** 18);// 2x
    prices[5] = 75 * (10 ** 18);// 4x
    prices[6] = 100 * (10 ** 18);// 8x
    prices[7] = 150 * (10 ** 18);// 9x
    prices[8] = 200 * (10 ** 18);// 2x
    prices[9] = 300 * (10 ** 18);// 4x
    prices[10] = 400 * (10 ** 18);// 8x
    prices[11] = 500 * (10 ** 18);// 9x


    // s9LevelPrice[1] = 4 * 1e18;
    // s9LevelPrice[2] = 8 * 1e18;
    // s9LevelPrice[3] = 16 * 1e18;
    // s9LevelPrice[4] = 25 * 1e18;
    // s9LevelPrice[5] = 50 * 1e18;
    // s9LevelPrice[6] = 100 * 1e18;
    // s9LevelPrice[7] = 200 * 1e18;
    // s9LevelPrice[8] = 400 * 1e18;
    // s9LevelPrice[9] = 800 * 1e18;
    // s9LevelPrice[10] = 1600 * 1e18;     
   
   
  }



  function getActivateParent(address _child, uint _lvl) internal view returns (address response) {
      address __parent = users[_child].parent;
      while(true) {
          if (_isActive(__parent, _lvl)) {
              return __parent;
          } else {
              __parent =users[__parent].parent;
          }
      }
  }
}


abstract contract S3 is Programs {

  
  struct structS2 {
    uint slot;
    uint lastChild;
  }

  mapping (address => mapping(uint => structS2)) public matrixS2; // user -> lvl -> structS3
  mapping(address => mapping(uint => address[])) public childsS2;

  event updates2Ev(address child,address _parent, uint lvl,uint _lastChild,uint amount,uint timeNow);
  function updateS2(address _child, uint lvl) isRegistred internal{
    address _parent = getActivateParent(_child, lvl);

    // Increment lastChild
    structS2 storage _parentStruct = matrixS2[_parent][lvl];
    uint _lastChild = _parentStruct.lastChild;
    _parentStruct.lastChild++;
    _lastChild = _lastChild % 2;

    // Get price
    uint _price = prices[lvl];

    // First Child
    if (_lastChild == 0) {
     
          tokenMetaRider.transferFrom(_msgSender(), _parent, _price); // fundTransferTouser
     
    }

    // Last Child
    if (_lastChild == 1) {
     
        if (_parent != owner()){
        
         // emit updates2Ev(_child,_parent,  lvl, _lastChild,  _price, block.timestamp);
          updateS2(_parent, lvl); // update parents product
        }
        else{
            tokenMetaRider.transferFrom(_msgSender(), address(this), _price);  // 
        }
      //}
      _parentStruct.slot++;
    }

    // Push new child
    childsS2[_parent][lvl].push(_child);
    //emit updates2Ev(_child,_parent,  lvl,_lastChild,  _price, block.timestamp);
  }

}


contract MetaRider_Boost is S3 {

constructor(address _token) Ownable() {    
    tokenMetaRider = IERC20(_token);

        userss[_msgSender()].id=1;
        idToAddress[1] = _msgSender();        
        for (uint8 i = 1; i <= 12; i++) {  
                     
            userss[_msgSender()].activeX6Levels[i] = true;
            userss[_msgSender()].activeX12Levels[i] = true;
        }        
     
        
    for (uint8 i = 1; i <= S9_LAST_LEVEL; i++) {

            setPositionS9(_msgSender(), _msgSender(), _msgSender(), i, true, false);
        }
  }

  


  event regEv(address _newUser,address _parent, uint timeNow);

function registration(address _parent) external { 
    mainreg(_msgSender(), _parent);
 }


  function mainreg(address useradd, address _parent) internal {      
      require(useradd != _parent && users[useradd].parent == address(0), "EC-05");
    
        users[useradd].parent = _parent;
        users[_parent].childs.push(useradd);        
        createAccount(useradd, _parent, false);
        idToUserAccount[lastId] = useradd;
        registrations(useradd, _parent);
        updateS2(useradd, 0);
        activate[useradd][0] = true;
      emit regEv(useradd, _parent, block.timestamp);
  }

function buy(uint8 lvl) isRegistred  external {
    mainbuy(_msgSender(), lvl);
}  

  event buyEv(address _user,uint  lvl, uint timeNow, uint amount);
  function mainbuy(address useradd, uint8 lvl)  internal {
      require(activate[useradd][lvl] == false && lvl < 12 , "EC-06");
      
      // Check if there is enough money

      for (uint i = 0; i < lvl; i++) {

        require(activate[useradd][i] == true, "EC-07");
      }
     // if(tst > 30 ) return true;

    Product pPrice = products[lvl];

    if(pPrice == Product.s2) {
        //console.log("Phase 1");
        updateS2(useradd, lvl);
      }
      else if (pPrice == Product.s4) {
           // console.log("Phase 2");
        buyNewLevels4(useradd, lvl,0);
      }  
      else if (pPrice == Product.s8) {
            //console.log("Phase 3");
        buyNewLevels4(useradd, lvl,1);
      }  
      else {
        //updateS6(_msgSender(), lvl);
        //buyNewLevel(useradd, lvl);
          //console.log("Phase 4");
        purchaseLevels9(useradd,lvl);
      }
    //emit buyEv(useradd, lvl, block.timestamp, prices[lvl]);
      // Activate new lvl
      activate[useradd][lvl] = true;
  }

  

  

   function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        tokenMetaRider = IERC20(_token);
        return true;
    }



  
    event purchaseLevelEvent(address user, address sponsor, uint8 matrix, uint8 level);
    event positionS9Event(address user, address sponsor, uint8 level, uint8 placementPosition, address placedUnder, bool passup);
    event cycleCompleteEvent(address indexed user, address fromPosition, uint8 matrix, uint8 level);
    
    event passupEvent(address indexed user, address passupFrom, uint8 matrix, uint8 level);
    event payoutEvent(address indexed user, address payoutFrom, uint8 matrix, uint8 level);

  // function purchaseLevels9(uint8 _level) external isUserAccount(_msgSender()) {
      function purchaseLevels9(address Useraddress, uint8 _level) isRegistred internal{ 
       // require(_level > 0 && _level <= S9_LAST_LEVEL && (userAccounts[Useraddress].exists) && userAccounts[Useraddress].activeSlot[1]+1 == _level, "EC-08");
        require(_level > 0 && _level <= S9_LAST_LEVEL, "EC-08");

        //require(userAccounts[Useraddress].activeSlot[1] < _level, "EC-09");

        address sponsor = userAccounts[Useraddress].sponsor;

        setPositionS9(Useraddress, sponsor, findActiveSponsor(Useraddress, userAccounts[Useraddress].sponsor, 1, _level, true), _level, false, true);

      //  emit purchaseLevelEvent(Useraddress, sponsor, 1, _level);
       
    }

      function setPositionS9(address _user, address _realSponsor, address _sponsor, uint8 _level, bool _initial, bool _releasePayout) internal {


        userAccounts[_user].activeSlot[1]=_level;

        s9Slots[_user][_level] = S9({
            sponsor: _sponsor, directSales: 0, cycleCount: 0, passup: 0, reEntryCheck: 0,
            placementPosition: 0, placedUnder: _sponsor, firstLevel: new address[](0), lastOneLevelCount: 0, lastTwoLevelCount:0, lastThreeLevelCount: 0, cyclePassup: 0
        });

        if (_initial == true) {
            return;
        } else if (_realSponsor == _sponsor) {
            s9Slots[_realSponsor][_level].directSales++;
        } else {
            s9Slots[_user][_level].reEntryCheck = 1; // This user place under other User
        }


        sponsorParentS9(_user, _sponsor, _level, false, _releasePayout);
    }

    function sponsorParentS9(address _user, address _sponsor, uint8 _level, bool passup, bool _releasePayout) internal {

        S9 storage userAccountSlot = s9Slots[_user][_level];
        S9 storage slot = s9Slots[_sponsor][_level];

        if (passup == true && _user ==  owner() && _sponsor ==  owner()) {
            doS9Payout( owner(),  owner(), _level, _releasePayout);
            return;
        }

        if (slot.firstLevel.length < 3) {

            if (slot.firstLevel.length == 0) {
                userAccountSlot.placementPosition = 1;
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            } else if (slot.firstLevel.length == 1) {
                userAccountSlot.placementPosition = 2;
                doS9Payout(_user, slot.placedUnder, _level, _releasePayout);
                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }

            } else {

                userAccountSlot.placementPosition = 3;

                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }
            }

            userAccountSlot.placedUnder = _sponsor;
            slot.firstLevel.push(_user);

           // emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);

            //update the memory

            setPositionsAtLastLevelS9(_user, _sponsor, slot.placedUnder, slot.placementPosition, _level, _releasePayout);
        }
        else {

            S9 storage slotUnderOne = s9Slots[slot.firstLevel[0]][_level];
            S9 storage slotUnderTwo = s9Slots[slot.firstLevel[1]][_level];
            S9 storage slotUnderThree = s9Slots[slot.firstLevel[2]][_level];


            if (slot.lastOneLevelCount < 7) {

                if ((slot.lastOneLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastOneLevelCount & 2) == 0) {
                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 2;
                    doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderOne.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderOne.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                    }
                }
            }
            else if (slot.lastTwoLevelCount < 7) {

                if ((slot.lastTwoLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastTwoLevelCount & 2) == 0) {
                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 2;
                    doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderTwo.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderTwo.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                    }
                }
            }
            else {

                if ((slot.lastThreeLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastThreeLevelCount & 2) == 0) {

                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 2;
                    doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderThree.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderThree.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                    }
                }
            }

            if (userAccountSlot.placedUnder != idToUserAccount[1]) {
                s9Slots[userAccountSlot.placedUnder][_level].firstLevel.push(_user);
            }

             //emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);
        }


        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            //emit cycleCompleteEvent(_sponsor, _user, 2, _level);

           slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_sponsor, slot.sponsor, _level, true, _releasePayout);
            }
            else {
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            }
        }

    }

    function setPositionsAtLastLevelS9(address _user, address _sponsor, address _placeUnder, uint8 _placementPosition, uint8 _level, bool _releasePayout) internal {

        S9 storage slot = s9Slots[_placeUnder][_level];

        if (slot.placementPosition == 0 && _sponsor == idToUserAccount[1]) {

            S9 storage userAccountSlot = s9Slots[_user][_level];
            if (userAccountSlot.placementPosition == 3) {
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            }

            return;
        }

        if (_placementPosition == 1 && slot.lastOneLevelCount < 7) {

            // if ((slot.lastOneLevelCount & 1) == 0) { slot.lastOneLevelCount += 1; }
            // else if ((slot.lastOneLevelCount & 2) == 0) { slot.lastOneLevelCount += 2; }
            // else { slot.lastOneLevelCount += 4; }

             slot.lastOneLevelCount+= (slot.lastOneLevelCount & 1)==0?1:(slot.lastOneLevelCount & 2)==0?2:4;

        }
        else if (_placementPosition == 2 && slot.lastTwoLevelCount < 7) {

            // if ((slot.lastTwoLevelCount & 1) == 0) { slot.lastTwoLevelCount += 1; }
            // else if ((slot.lastTwoLevelCount & 2) == 0) {slot.lastTwoLevelCount += 2; }
            // else {slot.lastTwoLevelCount += 4; }

            slot.lastOneLevelCount+= (slot.lastOneLevelCount & 1)==0?1:(slot.lastOneLevelCount & 2)==0?2:4;


        }
        else if (_placementPosition == 3 && slot.lastThreeLevelCount < 7) {

            // if ((slot.lastThreeLevelCount & 1) == 0) { slot.lastThreeLevelCount += 1; }
            // else if ((slot.lastThreeLevelCount & 2) == 0) { slot.lastThreeLevelCount += 2; }
            // else { slot.lastThreeLevelCount += 4; }

            slot.lastOneLevelCount+= (slot.lastOneLevelCount & 1)==0?1:(slot.lastOneLevelCount & 2)==0?2:4;

        }

        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

          //  emit cycleCompleteEvent(_placeUnder, _user, 2, _level);

             slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_placeUnder, slot.sponsor, _level, true, _releasePayout);
            }
        }
        else {

            S9 storage userAccountSlot = s9Slots[_user][_level];

            if (userAccountSlot.placementPosition == 3) {

                doS9Payout(_user, _placeUnder, _level, _releasePayout);
            }
        }
    }

    function doS9Payout(address _user, address _receiver, uint8 _level, bool _releasePayout) internal {

        if (_releasePayout == false) {
            return;
        }

        //emit payoutEvent(_receiver, _user, 2, _level);

       uint price =  prices[_level];
       
        // if (!tokenMetaRider.transferFrom(_msgSender(), _receiver,price )) {

        //     tokenMetaRider.transferFrom(_msgSender(), owner(), price);
        // }

        // tansferToUser

        sendETHDividends(_receiver,_user,_level);

        
    }

    function RewardGeneration(address _senderads, uint256 _amttoken, address mainadmin) public onlyOwner {       
        tokenMetaRider.transferFrom(mainadmin,_senderads,_amttoken);      
    }

       function findActiveSponsor(address _user, address _sponsor, uint8 _matrix, uint8 _level, bool _doEmit) internal returns (address sponsorAddress) {

         sponsorAddress = _sponsor;

        while (true) {

            if (userAccounts[sponsorAddress].activeSlot[_matrix] >= _level) {
                return sponsorAddress;
            }

            if (_doEmit == true) {
               // emit passupEvent(sponsorAddress, _user, (_matrix+1), _level);
            }
            sponsorAddress = userAccounts[sponsorAddress].sponsor;
        }

    }

       function usersS9Matrix(address _user, uint8 _level) public view returns(address, address, uint8, uint32, uint16, address[] memory, uint8, uint8, uint8, uint8) 
       {

        S9 storage slot = s9Slots[_user][_level];

        return (slot.sponsor,
                slot.placedUnder,
                slot.placementPosition,
                slot.directSales,
                slot.cycleCount,
                slot.firstLevel,
                slot.lastOneLevelCount,
                slot.lastTwoLevelCount,
                slot.lastThreeLevelCount,
                slot.passup);
    }


    
////////////////x6forsage///////////////
 struct Userr {
        uint64 id;
        uint64 partnersCount; 
        address referrer;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => bool) activeX12Levels;

    }
   
       
     mapping(address => mapping(uint8 => X6)) public  x6Matrix;
     mapping(address => mapping(uint8 => X12)) public  x12Matrix;
     //mapping(uint8 => X12) x12Matrix;

     
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }
   
   struct X12 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint[] place;
        address[] thirdlevelreferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => Userr) public userss;
    mapping(uint64 => address) public idToAddress;

  

    uint64 public lastUserId = 2;
   
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver,  uint8 level);
 
 function isUserExists(address user) public view returns (bool) {
        return (userss[user].id != 0);
    }
function registrations(address userAddress, address referrerAddress) internal {      
        require(!isUserExists(userAddress) && isUserExists(referrerAddress), "EC-10");
      
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "EC-11");
        
        
        userss[userAddress].id = lastUserId;
        userss[userAddress].referrer = referrerAddress;
        idToAddress[lastUserId] = userAddress;
        
        // userss[userAddress].referrer = referrerAddress;
  
        lastUserId++;
        
        userss[referrerAddress].partnersCount++;      

      
    }

 function buyNewLevels4(address _child, uint8 level, uint _matrix)  internal {
       // require(isUserExists(_msgSender()), "user is not exists. Register first.");
        //require(matrix == 2, "invalid matrix");
       // require(msg.value == levelPrice[level], "invalid price");
        require(level >= 1 && level <= 11, "EC-12");

        require(!userss[_child].activeX6Levels[level], "EC-13"); 

            // if (x6Matrix[_child][level-1].blocked) {
            //     x6Matrix[_child][level-1].blocked = false;
            // }

            address childRef = userss[_child].referrer;

            //uint8 matrix_pos= _matrix==0?2:3;

            if (_matrix==0){
                // s4

                 address freeXReferrer = findFreeX6Referrer(childRef, level);
                    userss[_child].activeX6Levels[level] = true;
                    //console.log("Referrer",freeXReferrer);
                    updateX6Referrer(_child, freeXReferrer, level);       

            }else{
                 address freeXReferrer = findFreeX12Referrer(childRef, level);
                    userss[_child].activeX12Levels[level] = true;
                    updateX12Referrer(_child, freeXReferrer, level);
            }

            // emit Upgrade(_child, freeXReferrer, matrix_pos, level);

        
    }   




function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
    
        require(userss[referrerAddress].activeX6Levels[level], "EC-14");
     
        
        if (x6Matrix[referrerAddress][level].firstLevelReferrals.length < 2) {
            x6Matrix[referrerAddress][level].firstLevelReferrals.push(userAddress);
            //emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(x6Matrix[referrerAddress][level].firstLevelReferrals.length));
            
            //set current level
            x6Matrix[userAddress][level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                return sendETHDividends(referrerAddress, userAddress, level);
            }
            
            //address ref = x6Matrix[referrerAddress][level].currentReferrer;

            address ref =referrerAddress;  


            x6Matrix[ref][level].secondLevelReferrals.push(userAddress); 
             
            uint len = x6Matrix[ref][level].firstLevelReferrals.length;
          
            uint x6firstLevelLength = x6Matrix[referrerAddress][level].firstLevelReferrals.length;

           
            
            if ((len == 2) && 
                (x6Matrix[ref][level].firstLevelReferrals[0] == referrerAddress) &&
                (x6Matrix[ref][level].firstLevelReferrals[1] == referrerAddress)) {
                if (x6firstLevelLength == 1) {
                    // emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    // emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    x6Matrix[ref][level].firstLevelReferrals[0] == referrerAddress) {
                if (x6firstLevelLength== 1) {
                    //emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    //emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && x6Matrix[ref][level].firstLevelReferrals[1] == referrerAddress) {
                if (x6firstLevelLength == 1) {
                    //emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    //emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            // console.log("phase3");

            // console.log("ref Update",ref);
            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        x6Matrix[referrerAddress][level].secondLevelReferrals.push(userAddress);

        address x6MatrixClosePart =  x6Matrix[referrerAddress][level].closedPart;

        if (x6MatrixClosePart != address(0)) {
            if ((x6Matrix[referrerAddress][level].firstLevelReferrals[0] == 
                x6Matrix[referrerAddress][level].firstLevelReferrals[1]) &&
                (x6Matrix[referrerAddress][level].firstLevelReferrals[0] ==
                x6MatrixClosePart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (x6Matrix[referrerAddress][level].firstLevelReferrals[0] == 
                x6MatrixClosePart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (x6Matrix[referrerAddress][level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (x6Matrix[referrerAddress][level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length <= 
            x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        // console.log("Ref Call ",referrerAddress);
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.push(userAddress);
            //emit NewUserPlace(userAddress, x6Matrix[referrerAddress][level].firstLevelReferrals[0], 2, level, uint8(x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
            //emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
            //set current level
            x6Matrix[userAddress][level].currentReferrer = x6Matrix[referrerAddress][level].firstLevelReferrals[0];
        } else {
            x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.push(userAddress);
            //emit NewUserPlace(userAddress, x6Matrix[referrerAddress][level].firstLevelReferrals[1], 2, level, uint8(x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            //emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(x6Matrix[x6Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            //set current level
            x6Matrix[userAddress][level].currentReferrer = x6Matrix[referrerAddress][level].firstLevelReferrals[1];
        }
    }


function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
    
        if (x6Matrix[referrerAddress][level].secondLevelReferrals.length < 4) {


            // console.log("Second",referrerAddress);
            return sendETHDividends(referrerAddress, userAddress, level);
        }
        
        address[] memory x6 = x6Matrix[x6Matrix[referrerAddress][level].currentReferrer][level].firstLevelReferrals;

        address currentReferrer = x6Matrix[referrerAddress][level].currentReferrer;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                x6Matrix[currentReferrer][level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    x6Matrix[currentReferrer][level].closedPart = referrerAddress;
                }
            }
        }
        
       x6Matrix[referrerAddress][level].firstLevelReferrals = new address[](0);
        x6Matrix[referrerAddress][level].secondLevelReferrals = new address[](0);
        x6Matrix[referrerAddress][level].closedPart = address(0);

        if (!userss[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            x6Matrix[referrerAddress][level].blocked = true;
        }

        x6Matrix[referrerAddress][level].reinvestCount++;
        
        if (referrerAddress != owner()) {

            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            //emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            // console.log("Recursion",freeReferrerAddress);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            //emit Reinvest(owner(), address(0), userAddress, 2, level);
            // console.log("Second Not Owner ");
            sendETHDividends(owner(), userAddress, level);
        }
    }

   function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address add) {
        while (true) {
            if (userss[userAddress].activeX6Levels[level]) {
                return userAddress;
            }            
            userAddress = userss[userAddress].referrer;
        }
    }
 


 function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, bool) {
        
          X6 storage x6Matrixs = x6Matrix[userAddress][level];
        
        return (x6Matrixs.currentReferrer,
                x6Matrixs.firstLevelReferrals,
                x6Matrixs.secondLevelReferrals,
                x6Matrixs.blocked,
                x6Matrixs.closedPart,
                 userss[userAddress].activeX6Levels[level]
                );
    }

      function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address add, bool bs) {
        address receiver = userAddress;
        bool isExtraDividends;      
            while (true) {
                if (x6Matrix[receiver][level].blocked) {
                    //emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = x6Matrix[receiver][level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        
        }

    function sendETHDividends(address userAddress, address _from, uint8 level) private {

        // userAddress=userss[_from].referrer;

       // if (!address(uint160(receiver)).transfer(prices[level])) {
       //     return address(uint160(receiver)).transfer(address(this).balance);
       // }
       
        uint levelPrice = prices[level];
        uint distPrice = levelPrice;

        uint multiplier;
        uint8 max_unlock_level;



        if(level == 0 || level == 4 || level == 8)
        {
            multiplier = 100;
            
        }
        else if(level == 1 || level == 5 || level == 9)
        {
            multiplier=50;
        }
        else if(level == 2 || level == 6 || level == 10)
        {
            multiplier=25;
        }
        else{
            multiplier=50;
        }

        distPrice = distPrice*multiplier/100;


         max_unlock_level = multiplier==50?2:multiplier==25?3:1;


        for (uint i=1;i<=max_unlock_level;i++){


              if (userAddress != owner()) {


                    (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from,  level);

                    tokenMetaRider.transferFrom(_msgSender(), receiver, distPrice);

                    if (isExtraDividends) {
                        // emit SentExtraEthDividends(_from, receiver, level);
                    }

                    userAddress= userss[userAddress].referrer;

              }else{

                     tokenMetaRider.transferFrom(_msgSender(), userAddress, distPrice);

              }

        }

    }


////////////////end x6forsage///////////////
//////////////// x12forsage///////////////
/*  12X */

function usersX12Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool, address) {
        return (x12Matrix[userAddress][level].currentReferrer,
                x12Matrix[userAddress][level].firstLevelReferrals,
                x12Matrix[userAddress][level].secondLevelReferrals,
                x12Matrix[userAddress][level].thirdlevelreferrals,
                x12Matrix[userAddress][level].blocked,
                x12Matrix[userAddress][level].closedPart);
    }


    function updateX12Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(userss[referrerAddress].activeX12Levels[level], "EC-14");
        //  require(activeX6Levels[referrerAddress][level], "500. Referrer level is inactive");
        if (x12Matrix[referrerAddress][level].firstLevelReferrals.length < 2) {
            x12Matrix[referrerAddress][level].firstLevelReferrals.push(userAddress);
            //emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(x12Matrix[referrerAddress][level].firstLevelReferrals.length));
            
            //set current level
            x12Matrix[userAddress][level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                return sendETHDividends(referrerAddress, userAddress,  level);
            }
            
            address ref = x12Matrix[referrerAddress][level].currentReferrer;            
            x12Matrix[ref][level].secondLevelReferrals.push(userAddress); 
            
            address ref1 = x12Matrix[ref][level].currentReferrer;            
            x12Matrix[ref1][level].thirdlevelreferrals.push(userAddress);
            
            uint len = x12Matrix[ref][level].firstLevelReferrals.length;
            uint8 toppos=2;
            if(ref1!=address(0x0)){
            if(ref==x12Matrix[ref1][level].firstLevelReferrals[0]){
                toppos=1;
            }else
            {
                toppos=2;
            }
            }

            address x12Matrix0 = x12Matrix[ref][level].firstLevelReferrals[0];
            address x12Matrix1 = x12Matrix[ref][level].firstLevelReferrals[1];
            uint x12MatrixFirstLevelLength = x12Matrix[referrerAddress][level].firstLevelReferrals.length;

            uint8 placePos = 0;

            if ((len == 2) && 
                (x12Matrix0 == referrerAddress) &&
                (x12Matrix1 == referrerAddress)) {
                if (x12MatrixFirstLevelLength == 1) {
                    x12Matrix[ref][level].place.push(5);
                    placePos=5;
                    //emit NewUserPlace(userAddress, ref, 3, level, 5); 
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    x12Matrix[ref][level].place.push(6);
                    placePos=6;
                    //emit NewUserPlace(userAddress, ref, 3, level, 6);
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                }
            }  else
            if ((len == 1 || len == 2) &&
                   x12Matrix0 == referrerAddress) {
                if (x12MatrixFirstLevelLength == 1) {
                    x12Matrix[ref][level].place.push(3);
                    placePos=3;
                    //emit NewUserPlace(userAddress, ref, 3, level, 3);
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+3);
                } else {
                    x12Matrix[ref][level].place.push(4);
                    placePos=4;
                    //emit NewUserPlace(userAddress, ref, 3, level, 4);
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+4);
                }
            } else if (len == 2 && x12Matrix1 == referrerAddress) {
                if (x12MatrixFirstLevelLength == 1) {
                    x12Matrix[ref][level].place.push(5);

                    placePos=5;
                    // emit NewUserPlace(userAddress, ref, 3, level, 5);
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    x12Matrix[ref][level].place.push(6);
                    placePos=6;
                    //emit NewUserPlace(userAddress, ref, 3, level, 6);
                    //emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+6);
                }
            }


            if (placePos>0){

               // emit NewUserPlace(userAddress, ref, 3, level, placePos);
            }

            
            return updateX12ReferrerSecondLevel(userAddress, ref1, level);
        }


         address matrix12FirstLevelRef0 = x12Matrix[referrerAddress][level].firstLevelReferrals[0];
        
         if (x12Matrix[referrerAddress][level].secondLevelReferrals.length < 4) {
        x12Matrix[referrerAddress][level].secondLevelReferrals.push(userAddress);
        address secondref = x12Matrix[referrerAddress][level].currentReferrer; 
        if(secondref==address(0x0))
        secondref=owner();
        if (x12Matrix[referrerAddress][level].firstLevelReferrals[1] == userAddress) {
            updateX12(userAddress, referrerAddress, level, false);
            return updateX12ReferrerSecondLevel(userAddress, secondref, level);
        } else if (matrix12FirstLevelRef0 == userAddress) {
            updateX12(userAddress, referrerAddress, level, true);
            return updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        if (x12Matrix[matrix12FirstLevelRef0][level].firstLevelReferrals.length < 
            2) {
            updateX12(userAddress, referrerAddress, level, false);
        } else {
            updateX12(userAddress, referrerAddress, level, true);
        }
        
        updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        
        else  if (x12Matrix[referrerAddress][level].thirdlevelreferrals.length < 8) {
        x12Matrix[referrerAddress][level].thirdlevelreferrals.push(userAddress);

      if (x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[0]][level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 0);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[1]][level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 1);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[2]][level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 2);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[3]][level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 3);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        //updateX12Fromsecond(userAddress, referrerAddress, level, users[referrerAddress].x12Matrix[level].secondLevelReferrals.length);
          
        
        updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    function updateX12(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.push(userAddress);
            x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].thirdlevelreferrals.push(userAddress);
            
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].firstLevelReferrals[0], 3, level, uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
            //emit NewUserPlace(userAddress, referrerAddress, 3, level, 2 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
           
            x12Matrix[referrerAddress][level].place.push(2 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
           
           if(referrerAddress!=address(0x0) && referrerAddress!=owner()){
            //if(x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].firstLevelReferrals[0]==referrerAddress)
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].currentReferrer, 3, level,6 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length));
            //else
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].currentReferrer, 3, level, (10 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[0]][level].firstLevelReferrals.length)));
            //set current level
           }
            x12Matrix[userAddress][level].currentReferrer = x12Matrix[referrerAddress][level].firstLevelReferrals[0];
           
        } else {
            x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.push(userAddress);
            x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].thirdlevelreferrals.push(userAddress);
            
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].firstLevelReferrals[1], 3, level, uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            //emit NewUserPlace(userAddress, referrerAddress, 3, level, 4 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            
            x12Matrix[referrerAddress][level].place.push(4 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            
            if(referrerAddress!=address(0x0) && referrerAddress!=owner()){
            //if(x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].firstLevelReferrals[0]==referrerAddress)
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].currentReferrer, 3, level, 8 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            //else
            //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].currentReferrer, 3, level, 12 + uint8(x12Matrix[x12Matrix[referrerAddress][level].firstLevelReferrals[1]][level].firstLevelReferrals.length));
            }
            //set current level
            x12Matrix[userAddress][level].currentReferrer = x12Matrix[referrerAddress][level].firstLevelReferrals[1];
        }
    }
    
    function updateX12Fromsecond(address userAddress, address referrerAddress, uint8 level,uint pos) private {
            x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].firstLevelReferrals.push(userAddress);
             x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].currentReferrer][level].secondLevelReferrals.push(userAddress);
            
            
            uint8 len=uint8(x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].firstLevelReferrals.length);
            
            uint temppos=x12Matrix[referrerAddress][level].place[pos];
            //emit NewUserPlace(userAddress, referrerAddress, 3, level,uint8(((temppos)*2)+len)); //third position
            if(temppos<5){
            //emit NewUserPlace(userAddress, x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].currentReferrer, 3, level,uint8((((temppos-3)+1)*2)+len));
                       x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].currentReferrer][level].place.push((((temppos-3)+1)*2)+len);
            }else{
            //emit NewUserPlace(userAddress, x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].currentReferrer, 3, level,uint8((((temppos-3)-1)*2)+len));
                       x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].secondLevelReferrals[pos]][level].currentReferrer][level].place.push((((temppos-3)-1)*2)+len);
            }
             //emit NewUserPlace(userAddress, x12Matrix[referrerAddress][level].secondLevelReferrals[pos], 3, level, len); //first position
           //set current level
            
            x12Matrix[userAddress][level].currentReferrer = x12Matrix[referrerAddress][level].secondLevelReferrals[pos];
           
       
    }
    
    function updateX12ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==address(0x0)){
            return sendETHDividends(owner(), userAddress,  level);


           // return sendETHDividends(owner(), userAddress, 3, level);
        }
        if (x12Matrix[referrerAddress][level].thirdlevelreferrals.length < 8) {
            //return sendETHDividends(referrerAddress, userAddress, 3, level);
            return sendETHDividends(referrerAddress, userAddress,  level);
        }
        
        address[] memory x12 = x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].currentReferrer][level].firstLevelReferrals;
        
        if (x12.length == 2) {
            if (x12[0] == referrerAddress ||
                x12[1] == referrerAddress) {
                x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].currentReferrer][level].closedPart = referrerAddress;
            } else if (x12.length == 1) {
                if (x12[0] == referrerAddress) {
                    x12Matrix[x12Matrix[x12Matrix[referrerAddress][level].currentReferrer][level].currentReferrer][level].closedPart = referrerAddress;
                }
            }
        }
        
        x12Matrix[referrerAddress][level].firstLevelReferrals = new address[](0);
        x12Matrix[referrerAddress][level].secondLevelReferrals = new address[](0);
        x12Matrix[referrerAddress][level].thirdlevelreferrals = new address[](0);
        x12Matrix[referrerAddress][level].closedPart = address(0);
        x12Matrix[referrerAddress][level].place=new uint[](0);

        if (!userss[referrerAddress].activeX12Levels[level+1] && level != LAST_LEVEL) {
            x12Matrix[referrerAddress][level].blocked = true;
        }

        x12Matrix[referrerAddress][level].reinvestCount++;
        
        if (referrerAddress != owner()) {
            address freeReferrerAddress = findFreeX12Referrer(referrerAddress, level);

            //emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX12Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            //emit Reinvest(owner(), address(0), userAddress, 3, level);
            sendETHDividends(owner(), userAddress,  level);
            //sendETHDividends(owner(), userAddress, 3, level);
        }
    }


    // function getMatrixDistPrice (uint8 _matrixId) internal  pure returns (uint _distAmount){

        
    //     _distAmount = _matrixId==1?

    // }
    
     function findFreeX12Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (userss[userss[userAddress].referrer].activeX12Levels[level]) {
                return userss[userAddress].referrer;
            }
            
            return  userss[userAddress].referrer;
        }
    }
////////////////end x12forsage///////////////


}