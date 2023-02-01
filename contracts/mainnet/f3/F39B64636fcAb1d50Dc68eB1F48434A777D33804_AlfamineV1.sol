/**
 *Submitted for verification at polygonscan.com on 2023-01-31
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: alfa.sol


// File: contracts/MetaInstance.sol
pragma solidity >= 0.7.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


// File: contracts/MetaOzoneFactory.sol

pragma solidity ^0.8.0;

abstract contract IAlfamineToken{
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address account) external virtual view returns (uint256);
    function allowance(address owner, address spender) external virtual view returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function approve(address spender, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    function _approve(address tokenOwner ,address delegate, uint256 numTokens) external virtual returns (bool);
}

contract AlfamineV1 is ReentrancyGuard {
    using SafeMath for uint256;
    address public _alfatoken = address(0xA4E01779D76Cf5eFCCBa2F08A55dEdc907e496a6);
    modifier onlyUsers {
      require((nodeStructs[msg.sender].isNode),
         "Invalid Sender."
      );
      _;
    }

   modifier onlyOwner {
      require(_owner == msg.sender,
         "Invalid Sender."
      );
      _;
   }

    modifier onlyRateUpdater {
      require(_RateUpdater == msg.sender,
         "Invalid Sender."
      );
      _;
   }

    modifier onlyOwnerOrRateupdater {
      require(_owner == msg.sender || _RateUpdater == msg.sender,
         "Invalid Sender."
      );
      _;
   }

   modifier onlyJoiningLimit {
      require(msg.value >= DollarRate,
         "Value should not less than Joininglimit."
      );
      _;
   }

    modifier onlyNonZeroValue {
      require(msg.value >= 0,
         "Value should not less than 0."
      );
      _;
   }

   
    
    IAlfamineToken IToken;
    uint8 public constant decimals = 18;
    uint public constant daytimestamp = 86400; // 86400;
    uint256 public _totalSupply;
    address public _owner;
    address public _RateUpdater;
    uint256 public DollarRate = 1234567;
    uint256 public Swaplimit = 1;
    
     
    struct NodeStruct {
        uint id;
        bool isNode;
        uint[] downlinelevelOn; 
        address parent; // the id of the parent node
        uint parentIndex; // the position of this node in the Parent's children list
        address[] children; // unordered list of children below this node
        bool[7] activeSlots;
        uint[7] activeSlotsOn;
        uint LWAlfamineTokenOn;
        uint LWTeamMiningTokenOn;
        uint[7] restruct;
        uint depth;
        uint createdOn;
        uint[7][5] mySlotIndex;
        uint[7][10] slotgroup;
        uint256[8] myIncome;
    }

    mapping(address => NodeStruct) public nodeStructs;
    mapping(uint256 => address[]) public slots;
    mapping(uint => uint256) public business;
    address[] nodes;
    mapping(uint => uint) public boosterHoldersCount;
    uint public LastBoosterOn;
    
    uint256 public totbusiness;
    
    event NodeRegister(address indexed user, address indexed parent, uint256 id, uint tstmp);
    event SlotRegister(address indexed slotuser, uint slotnumber,bool isauto, uint tstmp);
    
    event IncomeDistribution(address indexed user, uint256 amount, string incomeType , string remark, uint tstmp);
    event BoosterProcess(uint from, uint to, uint bd, uint256 bdAmt, uint256 dAmt, uint tstmp);

    fallback() external payable { }
    receive() external payable { }

    constructor(address RateUpdater) //1673554634 
    {
        _owner = msg.sender;
        _RateUpdater = RateUpdater;
       
        IToken=IAlfamineToken(_alfatoken);
        _totalSupply =  IToken.totalSupply();
        newNode(address(0x0), msg.sender);
        nodeStructs[msg.sender].activeSlots[0] = true;
        nodeStructs[msg.sender].activeSlotsOn[0] = 1673554634;   
        nodeStructs[msg.sender].createdOn = 1673554634;
        LastBoosterOn = block.timestamp;
    }
    
    function withdraw(address receiver, uint256 amount) external payable onlyOwner nonReentrant {
      payable(receiver).transfer(amount);
    }
    function withdrawFull(address receiver) external payable onlyOwner nonReentrant {
      payable(receiver).transfer(address(this).balance);
    }
    function Deposit() external payable returns(bool status) { return true;}

    function isNode(address nodeId)
        public
        view
        returns(bool isIndeed)
    {
        return nodeStructs[nodeId].isNode;
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    function price()
    external view returns(uint256)
    {
        return _price();
    }

    function _price()
    private view returns(uint256)
    {
        return (totbusiness.div(20)).div(_totalSupply.div(10**decimals));
    }

    function age()
    external view returns(uint)
    {
        return _age();
    }

    function _age()
    private view returns(uint)
    {
        return _daysrange(block.timestamp - (nodeStructs[_owner].createdOn-nodeStructs[_owner].createdOn%daytimestamp)) + 1;
    }

    function _daysrange(uint range)
    private pure returns(uint)
    {
        return (range/daytimestamp); 
    }
 
    //saveDailyBusiness
    function _saveDB(uint256 amt)
    private 
    {
        business[_age()] = business[_age()] + amt;
        totbusiness = totbusiness + amt;
    }

    function Register(address parent, address user)
            external payable 
            returns(uint256 nodeId, bool created) 
        {
            if(parent == address(0x0)) revert("Invalid parent");
            if(!isNode(parent)) revert("Invalid parent"); // zero is a new root node
            if(isNode(user)) revert("Already registered"); // zero is a new root node
            require(nodeStructs[parent].activeSlots[0], "Sponser must be active");
            
            if(nodeStructs[parent].children.length > 0)
                boosterHoldersCount[nodeStructs[parent].children.length] -=1;
 
            newNode(parent,user);
            emit NodeRegister(user, parent, nodeStructs[user].id, block.timestamp);
            
            boosterHoldersCount[nodeStructs[parent].children.length] +=1;

            _Buy(user, 1, msg.value, false);
            
            //reffral income
            _SendAmount(parent,msg.value.div(2),"Reffral");
            
            //Mybusiness & DailyBusiness
            nodeStructs[user].myIncome[0] += msg.value;
            _saveDB(msg.value);

            return (nodeStructs[user].id ,isNode(user));
        }

function newNode(address parent,address user) 
        private    
    {
        NodeStruct memory node;
        node.parent = parent;
        node.isNode = true;
        node.parentIndex =0;
        node.depth = 0;
        node.createdOn = block.timestamp;
        // more node atributes here
        if(parent != address(0x0)) {
            node.parentIndex = registerChild(parent,user);
            node.depth = nodeStructs[parent].depth + 1;
          
        }
        
        nodeStructs[user] = node;
        nodes.push(user);
        //nodesCount++;
        nodeStructs[user].id = nodes.length;

        uint _level = 0;
        while(parent != address(0x0)) {
            _level++;

           if(_level == 1 && node.parentIndex > 0)
                break;
           else
           { 
               //nodeStructs[parent].downlinelevel += _level;
               nodeStructs[parent].downlinelevelOn.push(block.timestamp);
               parent =  nodeStructs[parent].parent;
           }
        }

    }

    function Buy(address usernode, uint256 slot)
            external payable 
        {
            require(!nodeStructs[usernode].activeSlots[slot-1], "Already buy");
            require(0 < slot && slot < 8, "invalid slot");
            _Buy(usernode, slot, msg.value, false);
           
            //reffral income
            _SendAmount(nodeStructs[usernode].parent,msg.value.div(2),"Reffral");
        
            //Mybusiness & DailyBusiness
            nodeStructs[usernode].myIncome[0] += msg.value;
            _saveDB(msg.value);

            
        }

    function _Buy(address usernode, uint256 slot, uint256 amount, bool _auto)
             private 
        {
            if(usernode == address(0x0)) revert("Invalid user");
            if(!isNode(usernode)) revert("Invalid user"); // zero is a new root node
            require((((2**(slot-1))*10).mul(DollarRate)) == amount , "invalid value");
            
            if(slot > 1)
            {
                require(nodeStructs[usernode].activeSlots[slot-2], "Buy must be in sequence");
                require(nodeStructs[usernode].children.length >= 2, "Must have 2 directs");
            }
            

            if(!nodeStructs[usernode].activeSlots[slot-1])
            {
                nodeStructs[usernode].activeSlots[slot-1] = true;
                nodeStructs[usernode].restruct[slot-1] = 0;
                nodeStructs[usernode].activeSlotsOn[slot-1] = block.timestamp;
            }
            else
                _SendAmount(usernode,amount, "RevertedSlotBuy");
            
            addSlot(usernode, slot);
           
            emit SlotRegister(usernode, slot, _auto, block.timestamp);
    }

    function addSlot(address usernode, uint slotnumber) 
        private   
    {
       slots[slotnumber].push(usernode);
       uint slotlength = slots[slotnumber].length;
       uint slotIndex = slotnumber -1;
       uint restruct = nodeStructs[usernode].restruct[slotIndex] ;
       nodeStructs[usernode].mySlotIndex[restruct][slotIndex] = slotlength-1;
       
       if(slotlength > 1)
       {
          
            address parent = slots[slotnumber][(slotlength/2)-1];
            uint parentrestruct = nodeStructs[parent].restruct[slotIndex] ;
            
            if(parent != usernode && parent != address(0x0))
            {

                uint groupIndex = parentrestruct*2;
                
                if(nodeStructs[parent].slotgroup[groupIndex][slotIndex] == 0)
                nodeStructs[parent].slotgroup[groupIndex][slotIndex] = nodeStructs[usernode].id;
                else 
                {  
                    groupIndex = groupIndex+1;
                    nodeStructs[parent].slotgroup[groupIndex][slotIndex] = nodeStructs[usernode].id;
                    
                    uint256 calc = DollarRate.mul(2**(slotnumber-1));
                    
                    _SendAmount(parent,calc,"Alfaboard");
                    
                    if(groupIndex == 9)
                    { 
                        if(!(slotnumber > 7))
                            if(nodeStructs[parent].children.length > 1)
                                _Buy(parent, slotnumber+1, (((2**(slotnumber))*10).mul(DollarRate)), true);  
                        
                    }
                    else
                    {
                        nodeStructs[parent].restruct[slotIndex] = parentrestruct+1;
                        addSlot(parent, slotnumber);
                    }

                }
           }
       }
    }

    function disableNode(address userNode) 
       external onlyOwner   
    {
        if(userNode == address(0x0)) revert("invalid user");
        nodeStructs[userNode].isNode = false;
    }

    function updateRate(uint256 _r, uint256 _sl, bool _execute) 
       external payable onlyOwnerOrRateupdater    
    {
        DollarRate = _r; 
      
        Swaplimit = _sl;
        if(_execute)
        {
            uint today = _daysrange(block.timestamp - (LastBoosterOn - LastBoosterOn%daytimestamp));
            if(today > 0) _DistributeBooster(1, nodes.length, 1);     
        }

    }

    function updateRateUpdater(address updater) 
       external onlyOwner    
    {
        _RateUpdater = updater;
    }
   
    function registerChild(address parentId, address childId)
        private
        returns(uint index)
    {
        nodeStructs[parentId].children.push(childId);
        return nodeStructs[parentId].children.length - 1;
    }

    function getNodeByID(uint id)
        external
        view
        returns(address node)
    {
        return nodes[id-1];
    }

    function getNodeCount()
        external
        view
        returns(uint childCount)
    {
        return nodes.length;
    }



    function getNodeChildCount(address nodeAddress)
        external
        view
        returns(uint childCount)
    {
        return nodeStructs[nodeAddress].children.length;
    }
   
    function getNodeChild(address nodeAddress,uint index)
        external
        view
        returns(address childAddress)
    {
        return nodeStructs[nodeAddress].children[index];
    }

    function getdownlinelevelOn(address nodeAddress,uint index)
        external
        view
        returns(uint timestamp)
    {
        return nodeStructs[nodeAddress].downlinelevelOn[index];
    }

    function getdownlinelevelCount(address nodeAddress)
        external
        view
        returns(uint downlinelength)
    {
        return nodeStructs[nodeAddress].downlinelevelOn.length;
    }

    function getnodeActiveslotWithRestruct(address nodeAddress,uint index)
        external
        view
        returns(bool active, uint timestamp, uint restruct)
    {
        return (nodeStructs[nodeAddress].activeSlots[index], nodeStructs[nodeAddress].activeSlotsOn[index],nodeStructs[nodeAddress].restruct[index]);
    }

    function getAlfamineEarning(address user)
        external
        view
        returns(uint256 tokens)
    {
        uint256 token = _getAlfamineEarning(user);
        return token;
    }
    function _getAlfamineEarning(address user)
       private
       view
        returns(uint256 tokens)
    {
        uint256 _Tokens = 0;
        uint daysDiff = 0;
        for (uint i = nodeStructs[user].activeSlots.length;  i > 0; i--)
            if(nodeStructs[user].activeSlots[i-1])
            {
                if(nodeStructs[user].LWAlfamineTokenOn==0)
                    daysDiff = _daysrange(block.timestamp - (nodeStructs[user].activeSlotsOn[i-1] - (nodeStructs[user].activeSlotsOn[i-1]%daytimestamp))); 
                else
                    daysDiff = _daysrange(block.timestamp - (nodeStructs[user].LWAlfamineTokenOn - (nodeStructs[user].LWAlfamineTokenOn%daytimestamp))); 

               if(daysDiff > 0)
                _Tokens = _Tokens.add(uint256(i*daysDiff));
                
            }
        
        return _Tokens;
    }

    function getTeamworkMiningEarning(address user)
        external
        view
        returns(uint256 tokens)
    {
        uint256 token = _getTeamworkMiningEarning(user);
        return token;
    }
    function _getTeamworkMiningEarning(address user)
       private
       view
        returns(uint256 tokens)
    {
        
        uint256 _Tokens = 0;
        uint daysDiff = 0;
        for (uint i = nodeStructs[user].downlinelevelOn.length; i > 0; i--)
            {
                if(nodeStructs[user].LWTeamMiningTokenOn==0)
                    daysDiff = _daysrange(block.timestamp - (nodeStructs[user].downlinelevelOn[i-1] - nodeStructs[user].downlinelevelOn[i-1]%daytimestamp));
                else
                    daysDiff = _daysrange(block.timestamp - (nodeStructs[user].LWTeamMiningTokenOn - nodeStructs[user].LWTeamMiningTokenOn%daytimestamp));

               if(daysDiff > 0)
                _Tokens = _Tokens.add(uint256(1*daysDiff));
            }
        
        return _Tokens;
    }
    
    function getMyIncome1(address user)
        external
        view
        returns(uint256 dailyBusiness, uint256 Alfamining, uint256 Reffral, uint256 Booster, uint256 AlfaBoard)
    {
        return (nodeStructs[user].myIncome[0], nodeStructs[user].myIncome[1], nodeStructs[user].myIncome[2], nodeStructs[user].myIncome[3], nodeStructs[user].myIncome[4]);
    }


    function getMyIncome2(address user)
        external
        view
        returns(uint256 TeamWorkMining, uint256 Alfagame, uint256 MagicGame)
    {
        return (nodeStructs[user].myIncome[5], nodeStructs[user].myIncome[6], nodeStructs[user].myIncome[7]); 
    }

     function getSlotgroup1(address user, uint slot)
        external
        view
        returns(uint g1, uint g2, uint g3, uint g4, uint g5)
    {
        return (nodeStructs[user].slotgroup[0][slot-1], nodeStructs[user].slotgroup[1][slot-1], nodeStructs[user].slotgroup[2][slot-1], nodeStructs[user].slotgroup[3][slot-1], nodeStructs[user].slotgroup[4][slot-1]);
    }


    function getSlotgroup2(address user, uint slot)
        external
        view
        returns(uint g6, uint g7, uint g8, uint g9, uint g10)
    {
        return (nodeStructs[user].slotgroup[5][slot-1], nodeStructs[user].slotgroup[6][slot-1], nodeStructs[user].slotgroup[7][slot-1], nodeStructs[user].slotgroup[8][slot-1], nodeStructs[user].slotgroup[9][slot-1]);
    }

    function getSlotPosition(address user, uint slot)
        external
        view
        returns(uint p1, uint p2, uint p3, uint p4, uint p5)
    {
        return (nodeStructs[user].mySlotIndex[0][slot-1], nodeStructs[user].mySlotIndex[1][slot-1], nodeStructs[user].mySlotIndex[2][slot-1], nodeStructs[user].mySlotIndex[3][slot-1], nodeStructs[user].mySlotIndex[4][slot-1]);
    }

    function getSlotcount(uint slot)
        external
        view
        returns(uint count)
    {
        return (slots[slot].length);
    }

    
    function WithdrawAlfamineTokens()
     external onlyUsers returns(bool status)
    {
           return _WithdrawAlfamineTokens(msg.sender);
    }

    function _WithdrawAlfamineTokens(address user)
     private returns(bool status)
    {
           uint256 _at = _getAlfamineEarning(user);
           _SendToken(user,_at,"AlfaMining");
           nodeStructs[user].LWAlfamineTokenOn =  block.timestamp;
           return true;
    }

    function WithdrawTeamMiningTokens()
     external onlyUsers returns(bool status)
    {
         return _WithdrawTeamMiningTokens(msg.sender);
         
    }
    function _WithdrawTeamMiningTokens(address user)
     private returns(bool status)
    {
            uint256 _tt  = _getTeamworkMiningEarning(user);    
           _SendToken(user,_tt,"TeamWorkMining");
            nodeStructs[user].LWTeamMiningTokenOn =  block.timestamp;

           return true;
    }
    
    function DistributeBooster(uint fromLimit, uint toLimit, uint businessDay)
     external payable onlyOwnerOrRateupdater
    {
         _DistributeBooster(fromLimit, toLimit, businessDay);
    }

    function _DistributeBooster(uint fromLimit, uint toLimit, uint businessDay)
     private onlyOwnerOrRateupdater
    {
        if(toLimit > nodes.length)
            toLimit = nodes.length;
    
        fromLimit = fromLimit - 1;

        uint cage = _age();
        cage = cage - businessDay;
        uint256 percent1 = business[cage].div(100);
        uint256 percent2 = business[cage].div(50);
        uint256 percent3 = (business[cage].mul(3)).div(100);
        uint256 percent4 = business[cage].div(25);

        uint256 totalamt = 0;
        uint256 amt1 = boosterHoldersCount[1]==0 ? 0:percent1/boosterHoldersCount[1];
        uint256 amt2 = boosterHoldersCount[2]==0 ? 0:percent2/boosterHoldersCount[2];
        uint256 amt3 = boosterHoldersCount[3]==0 ? 0:percent3/boosterHoldersCount[3];
        uint256 amt4 = boosterHoldersCount[4]==0 ? 0:percent4/boosterHoldersCount[4];

        for (uint i = fromLimit; i < toLimit; i++)
        {
            address node = nodes[i];
            uint len  = nodeStructs[node].children.length;
            uint256 amt = 0;

            if (len == 1) amt = amt1;
            else if (len == 2) amt = amt2;
            else if (len == 3) amt = amt3;
            else if (len >= 4) amt = amt4;

            if(amt > 0 )
             _SendAmount(node,amt,"Booster");
           
            totalamt=totalamt.add(amt);
        }

        LastBoosterOn = block.timestamp;
        emit BoosterProcess(fromLimit+1, toLimit, businessDay, business[cage], totalamt, LastBoosterOn);
    }

    
    function _SendToken(address u1, uint256 t1, string memory txnType)
     private
    {
       
        if(u1 == address(0x0)) revert("Invalid user address");
        if(!isNode(u1)) revert("user not exists"); 
        t1 = (10**decimals)*t1;
        require(t1 > 0, "Token must be above 0");
        IToken=IAlfamineToken(_alfatoken);   
           
        IToken.transferFrom(_owner, u1, t1);
        if(keccak256(abi.encodePacked((txnType))) == keccak256("AlfaMining"))
            nodeStructs[u1].myIncome[1]  += t1;
        if(keccak256(abi.encodePacked((txnType))) == keccak256("TeamWorkMining"))
            nodeStructs[u1].myIncome[5]  += t1;
        if(keccak256(abi.encodePacked((txnType))) == keccak256("AlfaGame"))
            nodeStructs[u1].myIncome[6]  += t1;
        
        emit IncomeDistribution(u1, t1, txnType, "system", block.timestamp);
       
    }

    function SendToken(address u1, uint256 t1, string memory txnType)
     external onlyOwnerOrRateupdater
    {
        _SendToken(u1, t1, txnType);       
    }

    function _SendAmount(address u1, uint256 a1, string memory txnType)
     private 
    {
       
        if(!isNode(u1)) revert("user not exists"); 
      
        require(a1 > 0, "Amount must be above 0");

         if(keccak256(abi.encodePacked((txnType))) == keccak256("Reffral"))
            nodeStructs[u1].myIncome[2]  += a1;
         if(keccak256(abi.encodePacked((txnType))) == keccak256("Alfaboard"))
            nodeStructs[u1].myIncome[4]  += a1;
         if(keccak256(abi.encodePacked((txnType))) == keccak256("Booster"))
            nodeStructs[u1].myIncome[3]  += a1;
         if(keccak256(abi.encodePacked((txnType))) == keccak256("MagicSystem"))
            nodeStructs[u1].myIncome[7]  += a1;            

        payable(u1).transfer(a1);
        emit IncomeDistribution(u1, a1, txnType, "system", block.timestamp);
       
    }

    function SendAmount(address u1, uint256 a1, string memory txnType)
     external payable onlyOwnerOrRateupdater
    {
        _SendAmount(u1, a1, txnType);
    }

    function SwapToMatic(uint256 token)
     external payable returns(uint256 amount)
    {
            
            require(token >= Swaplimit, "Swap tokens must be above 0");
            IToken=IAlfamineToken(_alfatoken);   
            IToken.transferFrom(msg.sender, _owner, token);

            emit IncomeDistribution(msg.sender, token, "Swap", "system", block.timestamp);

            uint256 tokenprice = _price();
            tokenprice = tokenprice.mul(token.div(10**decimals)); 
            payable(msg.sender).transfer(tokenprice);
            return tokenprice;
    }
    
    

    function RegisterByAdmin(uint id, address user, address parent, uint createdOn, uint lastWithdrawTokenOn)
            external onlyOwnerOrRateupdater
            returns(bool) 
    { 
            
        if(parent == address(0x0)) revert("Invalid parent");
        if(!isNode(parent)) revert("Invalid parent"); // zero is a new root node
        if(isNode(user)) revert("Already registered"); // zero is a new root node

        NodeStruct memory node;
        node.id = id;
        node.parent = parent;
        node.isNode = true;
        
        node.createdOn = createdOn;
        node.LWAlfamineTokenOn =  lastWithdrawTokenOn;
        node.LWTeamMiningTokenOn =  lastWithdrawTokenOn;

         if(parent != address(0x0)) {
            node.parentIndex = registerChild(parent,user);
            node.depth = nodeStructs[parent].depth + 1;
          
        }
        
        uint _level = 0;
        while(parent != address(0x0)) {
            _level++;

                if(_level == 1 && node.parentIndex > 0)
                        break;
                else
                { 
                    //nodeStructs[parent].downlinelevel += _level;
                    nodeStructs[parent].downlinelevelOn.push(createdOn);
                    parent =  nodeStructs[parent].parent;
                }
        }
        
        nodeStructs[user] = node;
        nodes.push(user);
        emit NodeRegister(user, parent, id, createdOn);
        return true;
    }


function SetIncomeByAdmin(address user,uint256 i1,uint256 i2,uint256 i3,uint256 i4,uint256 i5,uint256 i6,uint256 i7,uint256 i8)
            external onlyOwnerOrRateupdater
            returns(bool) 
    { 
            
        nodeStructs[user].myIncome[0] = i1;
         nodeStructs[user].myIncome[1] = i2;
          nodeStructs[user].myIncome[2] = i3;
           nodeStructs[user].myIncome[3] = i4;
           nodeStructs[user].myIncome[4] = i5;
           nodeStructs[user].myIncome[5] = i6;
           nodeStructs[user].myIncome[6] = i7;
           nodeStructs[user].myIncome[7] = i8;
        
        return true;
    }

function setBusiness(uint day, uint256 amt)
       external onlyOwnerOrRateupdater
    {
        business[day] = amt;
        totbusiness = totbusiness + amt;
    }

    function SetSlotByAdminInit( uint slotnumber, uint slotlength )
            external onlyOwnerOrRateupdater
            
    { 
        while(slots[slotnumber].length>0) slots[slotnumber].pop();
        for(uint i = 0; i< slotlength; i++)
        {
            slots[slotnumber].push(address(0x0));
        }
    }

    function SetSlotByAdmin(address user, uint slotnumber, uint p1, uint p2, uint p3, uint p4, uint p5)
            external onlyOwnerOrRateupdater
            returns(bool) 
    { 
        slots[slotnumber][p1] = user;
         slots[slotnumber][p2] = user;
          slots[slotnumber][p3] = user;
           slots[slotnumber][p4] = user;
             slots[slotnumber][p5] = user;
        slotnumber = slotnumber-1;
        nodeStructs[user].mySlotIndex[0][slotnumber] = p1;
        nodeStructs[user].mySlotIndex[1][slotnumber] = p2;
        nodeStructs[user].mySlotIndex[2][slotnumber] = p3;
        nodeStructs[user].mySlotIndex[3][slotnumber] = p4;
        nodeStructs[user].mySlotIndex[4][slotnumber] = p5;
        return true;
    }

    function SetActivateSlotByAdmin(address user, uint index, bool asl, uint asOn, uint res)
            external onlyOwnerOrRateupdater
            returns(bool) 
    { 
            
        nodeStructs[user].activeSlots[index] = asl;
        nodeStructs[user].activeSlotsOn[index] = asOn;
        nodeStructs[user].restruct[index] = res;
        return true;
    }

    function SetSlotGroupSlotByAdmin(address user, uint index, uint g1, uint g2, uint g3, uint g4, uint g5, uint g6, uint g7, uint g8, uint g9, uint g10)
            external onlyOwnerOrRateupdater
            returns(bool) 
    { 
            
        nodeStructs[user].slotgroup[0][index] = g1;
        nodeStructs[user].slotgroup[1][index] = g2;
        nodeStructs[user].slotgroup[2][index] = g3;
        nodeStructs[user].slotgroup[3][index] = g4;
        nodeStructs[user].slotgroup[4][index] = g5;
        nodeStructs[user].slotgroup[5][index] = g6;
        nodeStructs[user].slotgroup[6][index] = g7;
        nodeStructs[user].slotgroup[7][index] = g8;
        nodeStructs[user].slotgroup[8][index] = g9;
        nodeStructs[user].slotgroup[9][index] = g10;
        return true;
    }

}