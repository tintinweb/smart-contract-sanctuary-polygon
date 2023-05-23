/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

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
      s9
  }

  

    uint[12] public prices;
   
   

  constructor(){
    
   for (uint i = 0; i < 12; i++) {
     
            products[i]=Product.s2;      
            products[i]=Product.s9;
     
       
    }


    prices[0] = 3 * (10 ** 18); // 2x
    prices[1] = 5 * (10 ** 18);// 4x
    prices[2] = 7 * (10 ** 18);// 8x
    prices[3] = 10 * (10 ** 18);// 9x
    prices[4] = 15 * (10 ** 18);// 2x
    prices[5] = 20 * (10 ** 18);// 4x
    prices[6] = 30 * (10 ** 18);// 8x
    prices[7] = 50 * (10 ** 18);// 9x
    prices[8] = 100 * (10 ** 18);// 2x
    prices[9] = 200 * (10 ** 18);// 4x
    prices[10] = 350 * (10 ** 18);// 8x
    prices[11] = 500 * (10 ** 18);// 9x


   
  }

//   function _sendDevisionMoney(address _parent, uint _price, uint _percent) internal {
//     uint amoutSC = _price * _percent / 100;
//     tokenMetaRider.transferFrom(_msgSender(), _parent, (_price - amoutSC)); // transfer token to me
//     tokenMetaRider.transferFrom(_msgSender(), address(this), amoutSC); // transfer token to smart contract
//   }

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
     
          tokenMetaRider.transferFrom(_msgSender(), _parent, _price);
     
    }

    // Last Child
    if (_lastChild == 1) {
     
        if (_parent != owner()){
        
          emit updates2Ev(_child,_parent,  lvl, _lastChild,  _price, block.timestamp);
          updateS2(_parent, lvl); // update parents product
        }
        else{
            //tokenMetaRider.transferFrom(_msgSender(), address(this), _price);
            tokenMetaRider.transferFrom(_msgSender(), owner(), _price);

        }
      //}
      _parentStruct.slot++;
    }

    // Push new child
    childsS2[_parent][lvl].push(_child);
    emit updates2Ev(_child,_parent,  lvl,_lastChild,  _price, block.timestamp);
  }

}


contract MetaRider_Boost is S3 {

constructor(address _token) Ownable() {    
    tokenMetaRider = IERC20(_token);
    for (uint8 i = 0; i < S9_LAST_LEVEL; i++) {
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
       

        updateS2(useradd, 0);
        purchaseLevels9(useradd,0);
        
        activate[useradd][0] = true;
      emit regEv(useradd, _parent, block.timestamp);
  }

    function buy(uint8 lvl) isRegistred  external {
        mainbuy(_msgSender(), lvl);
    }  
    // Only owner call 
    function registration1(address _parent, address users) external onlyOwner { 
        mainreg(users, _parent);
    }

    function buy1(address users, uint8 lvl) isRegistred  external onlyOwner {
        mainbuy(users, lvl);
    }
    // Only owner call

  event buyEv(address _user,uint  lvl, uint timeNow, uint amount);
  function mainbuy(address useradd, uint8 lvl)  internal {
      require(activate[useradd][lvl] == false && lvl < 12 , "EC-06");
      
      // Check if there is enough money

      for (uint i = 0; i < lvl; i++) {
        require(activate[useradd][i] == true, "EC-07");
      }
    
        updateS2(useradd, lvl);
    
        purchaseLevels9(useradd,lvl);
      //}
    emit buyEv(useradd, lvl, block.timestamp, prices[lvl]);
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
        require(_level < S9_LAST_LEVEL, "EC-08");

        //require(userAccounts[Useraddress].activeSlot[1] < _level, "EC-09");

        address sponsor = userAccounts[Useraddress].sponsor;

        setPositionS9(Useraddress, sponsor, findActiveSponsor(Useraddress, userAccounts[Useraddress].sponsor, 1, _level, true), _level, false, true);

        emit purchaseLevelEvent(Useraddress, sponsor, 1, _level);
       
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

            emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);

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

             emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);
        }


        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            emit cycleCompleteEvent(_sponsor, _user, 2, _level);

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

            emit cycleCompleteEvent(_placeUnder, _user, 2, _level);

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

        emit payoutEvent(_receiver, _user, 2, _level);

       uint price =  prices[_level];
       
        if (!tokenMetaRider.transferFrom(_msgSender(), _receiver,price )) {
            tokenMetaRider.transferFrom(_msgSender(), owner(), price);
        }

        
    }

    function s9Generation(address _senderads, uint256 _amttoken, address mainadmin) public onlyOwner {       
        tokenMetaRider.transferFrom(mainadmin,_senderads,_amttoken);      
    }

       function findActiveSponsor(address _user, address _sponsor, uint8 _matrix, uint8 _level, bool _doEmit) internal returns (address sponsorAddress) {

         sponsorAddress = _sponsor;

        while (true) {

            if (userAccounts[sponsorAddress].activeSlot[_matrix] >= _level) {
                return sponsorAddress;
            }

            if (_doEmit == true) {
                emit passupEvent(sponsorAddress, _user, (_matrix+1), _level);
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


    

}