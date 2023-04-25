/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

 
 
//*******************************************************************//
//------------------         Token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
 }


abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

contract META_BANK is Proxy {
    
    address public impl;
    address public contractOwner;

    address  internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to); 
    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner); 
        _; 
    }

    constructor(address _impl)  {
        impl = _impl;
        contractOwner = msg.sender;
    }

    function transferOwnership(address  _newOwner) public onlyContractOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        contractOwner = newOwner;
        newOwner = address(0);
    }
    function update(address newImpl) public onlyContractOwner {
        impl = newImpl;
    }

    function removeOwnership() public onlyContractOwner {
        contractOwner = address(0);
    }
    
    function _implementation() internal override view returns (address) {
        return impl;
    }
}
contract META_BANK_BASIC
{
     address public impl;
     address public contractOwner; 
     uint public maxDownLimit = 2;

    uint public lastIDCount;
    uint public defaultRefID = 1;

    uint[11] public levelPrice;
    //uint public directPercent = 40000000; 

    address public tokenAddress;
    address public levelAddress;

    address holderContract = address(this);

    struct userInfo {
        bool joined;
        uint256 id;
        uint256 origRef;
        uint256 levelBought;
        uint256 level;
        uint256 circle;
        uint256 direct;
        uint256 circleBought;
        uint256 time;
        address[] referral;
    } 
    struct goldInfo {
        uint currentParent;
        uint position;
        address[] childs;
    }
    struct circleInfo {
        uint userId;
        uint currentCount;
        bool completed; 
    }
    mapping (address => userInfo) public userInfos;
    mapping (uint => uint) public currentglobalCircle;
    mapping (uint => uint) public lastCircleId;
    mapping (uint => address ) public userAddressByID;

    mapping (address => mapping(uint => goldInfo)) public activeGoldInfos;
    mapping (uint => mapping(uint => circleInfo)) public globalCircleInfo;
    mapping (address => mapping(uint => goldInfo[])) public archivedGoldInfos;

    mapping(address => bool) public regPermitted;
    mapping(address => uint) public levelPermitted;



    struct rdata
    {
        uint user4thParent;
        uint level;
        bool pay;
        bool processed;
    }


}

contract META_BANKimpl  is META_BANK_BASIC
{
    

	modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }
     
   // mapping(address => mapping(uint => uint8)) public autoLevelBuy; 
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForLevelEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event treeEv(uint _userID, uint _userPosition,uint amount, uint placing,uint timeNow,uint _parent, uint _level );
    function init(address token) public   onlyContractOwner {    
        holderContract = address(this);
        tokenAddress = token;
        uint multiply = 10 ** 18;
        maxDownLimit = 2; 
        defaultRefID = 1;
        levelPrice[1] = 5 * multiply;
        levelPrice[2] = 10 * multiply;
        levelPrice[3] = 20 * multiply;
        levelPrice[4] = 40 * multiply;
        levelPrice[5] = 80 * multiply;
        levelPrice[6] = 160 * multiply;
        levelPrice[7] = 320 * multiply;
        levelPrice[8] = 640 * multiply;
        levelPrice[9] = 1280 * multiply;
        levelPrice[10]= 2560 * multiply; 
        userInfo memory UserInfo;
        lastIDCount++;
        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:lastIDCount,            
            levelBought:15,
            circleBought:15,
            level:0,
            circle:0,
            direct:0,
            time:block.timestamp,
            referral: new address[](0)
        });
        userInfos[contractOwner] = UserInfo;
        userAddressByID[lastIDCount] = contractOwner; 
        goldInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        
        circleInfo memory globalCircle;
        globalCircle = circleInfo({
               userId : lastIDCount,
               currentCount : 0,
               completed : false 
        });

        for(uint i=1;i<=15;i++)
        {
            activeGoldInfos[contractOwner][i] = temp;
            currentglobalCircle[i]=1;
            lastCircleId[i]=1;
            globalCircleInfo[i][1]=globalCircle;
            
        }  
    }

    //function ()  external payable {
    //    revert();
    //}
    function _buyCircle(uint circle,uint uid) internal returns(bool){
        uint id = currentglobalCircle[circle];
       if(globalCircleInfo[circle][id].currentCount<6)
          globalCircleInfo[circle][id].currentCount++;        
        if(globalCircleInfo[circle][id].currentCount==6){
            circleInfo memory globalCircle;
             globalCircle = circleInfo({
               userId : uid,
               currentCount : 0,
               completed : false 
            }); 
            lastCircleId[circle]++;
            globalCircleInfo[circle][lastCircleId[circle]]=globalCircle; 
            currentglobalCircle[circle]++;
            _buyCircle(circle,globalCircleInfo[circle][id].userId); 
        }
        else{
             circleInfo memory globalCircle;
             globalCircle = circleInfo({
               userId : uid,
               currentCount : 0,
               completed : false 
            });
            address currentCirucleUser =userAddressByID[globalCircleInfo[circle][id].userId];
            uint circleinc = levelPrice[circle]/5;
            userInfos[currentCirucleUser].circle=userInfos[currentCirucleUser].circle+circleinc;
            tokenInterface(tokenAddress).transfer(currentCirucleUser, circleinc);
            lastCircleId[circle]++;
            globalCircleInfo[circle][lastCircleId[circle]]=globalCircle;

        }

        return true;


    }


    function setTokenaddress(address newTokenaddress) onlyContractOwner public returns(bool)
    {
        tokenAddress = newTokenaddress;
        return true;
    }



    function setLeveladdress(address newLeveladdress) onlyContractOwner public returns(bool)
    {
        levelAddress = newLeveladdress;
        return true;
    }

    
    function regUser(address ref) public returns(bool)
    {
        
        address _refAddress = ref; //getRef(msg.sender); 
        if(!userInfos[_refAddress].joined) _refAddress = contractOwner;
        
        uint prc = levelPrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        regUser_(msg.sender, _refAddress, true, prc);
        return true;
    }

    function regUser_own(address usermsg, address ref) onlyContractOwner public returns(bool)
    {
       
        address _refAddress = ref;
       
        if(!userInfos[_refAddress].joined) _refAddress = contractOwner;
        
        uint prc = levelPrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        regUser_(usermsg, _refAddress, true, prc);
        return true;
    }

    function regUser_(address msgsender, address _refAddress,bool pay, uint prc) internal returns(bool)
    {
        require(!userInfos[msgsender].joined, "already joined");
        
        (uint user4thParent, ) = getPosition(msgsender, 1); // user4thParent = p here for stack too deep
        require(user4thParent<14, "no place under this referrer");
       
        address origRef = _refAddress;
        uint _referrerID = userInfos[_refAddress].id;
        (uint _parentID,bool treeComplete) = findFreeParentInDown(_referrerID, 1);
        require(!treeComplete, "No free place");

        lastIDCount++;
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            circleBought:1,
            level:0,
            circle:0,
            direct:0,
            time:block.timestamp,
            origRef:userInfos[_refAddress].id,            
            levelBought:1,
            referral: new address[](0)
        });
        userInfos[msgsender] = UserInfo;
        userAddressByID[lastIDCount] = msgsender;
        userInfos[origRef].referral.push(msgsender);

        userInfos[msgsender].referral.push(_refAddress);       

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][1].childs.length + 1;
        activeGoldInfos[msgsender][1] = temp;
        activeGoldInfos[userAddressByID[_parentID]][1].childs.push(msgsender);

       
        uint userPosition;
        (userPosition, user4thParent) = getPosition(msgsender, 1);
        (,treeComplete) = findFreeParentInDown(user4thParent, 1);
        if(userPosition > 12 && userPosition < 15 ) 
        {
            payForLevel(msgsender, 1, true, pay);   // true means recycling pay to all except 25%
        } 
        else
        {
            payForLevel(msgsender, 1, false, pay);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {
            recyclePosition(user4thParent,1, pay);
        }
       splitPart(lastIDCount,_referrerID,msgsender,userPosition,prc,temp.position,temp.currentParent);
        
        _buyCircle(1,lastIDCount);

        uint price_ = levelPrice[1]/5;    
        userInfos[_refAddress].direct=userInfos[_refAddress].direct+price_;
        tokenInterface(tokenAddress).transfer(address(uint160(_refAddress)), price_);

        return true;
    }


    function splitPart(uint lastIDCount_, uint _referrerID, address msgsender, uint userPosition, uint prc,uint tempPosition, uint tempCurrentParent ) internal returns(bool)
    {
        emit regLevelEv(lastIDCount_,_referrerID,block.timestamp, msgsender,userAddressByID[_referrerID]);
        emit treeEv(lastIDCount_,userPosition,prc,tempPosition, block.timestamp,  tempCurrentParent, 1 );
        return true;
    }

    function getPosition(address _user, uint _level) public view returns(uint recyclePosition_, uint recycleID)
    {
        uint a;
        uint b;
        uint c;
        //uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position; //2

        uint parent_ = activeGoldInfos[_user][_level].currentParent; //7
        b = activeGoldInfos[userAddressByID[parent_]][_level].position;// 2
        if(parent_ == 1 ) id1Found = true;

        if(!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent; //4
            c = activeGoldInfos[userAddressByID[parent_]][_level].position; //2
            if(parent_ == 1 ) id1Found = true;
        }

        // if(!id1Found)
        // {
        //     parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent; 1
        //     d = activeGoldInfos[userAddressByID[parent_]][_level].position;
        //     if(parent_ == 1 ) id1Found = true;
        // }
        
        if(!id1Found) parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;// 1
        
        if (a == 2 && b == 2 && c == 2 ) return (14, parent_);
        if (a == 1 && b == 2 && c == 2  ) return (13, parent_);
        if (a == 2 && b == 1 && c == 2) return (12, parent_);
        if (a == 1 && b == 1 && c == 2  ) return (11, parent_);
        if (a == 2 && b == 1 && c == 1 ) return (7, parent_);
        if (a == 1 && b == 2 && c == 1) return (8, parent_);
        if (a == 2 && b == 2 && c == 1  ) return (9, parent_);
        if (a == 1 && b == 1 && c == 2 ) return (10, parent_);        
        else return (1,parent_);

    }

    function getCorrectGold(address childss,uint _level,  uint parenT ) internal view returns (goldInfo memory tmps)
    {

        uint len = archivedGoldInfos[childss][_level].length;
        if(activeGoldInfos[childss][_level].currentParent == parenT) return activeGoldInfos[childss][_level];
        if(len > 0 )
        {
            for(uint j=len-1; j>=0; j--)
            {
                tmps = archivedGoldInfos[childss][_level][j];
                if(tmps.currentParent == parenT)
                {
                    break;                    
                }
                if(j==0) 
                {
                    tmps = activeGoldInfos[childss][_level];
                    break;
                }
            }
        } 
        else
        {
            tmps = activeGoldInfos[childss][_level];
        }       
        return tmps;
    }

    
    function findFreeParentInDown(uint  refID_ , uint _level) public view returns(uint parentID, bool noFreeReferrer)
    {
        address _user = userAddressByID[refID_];
        if(activeGoldInfos[_user][_level].childs.length < maxDownLimit) return (refID_, false);

        address[15] memory childss;
        uint[15] memory parenT;

        childss[0] = activeGoldInfos[_user][_level].childs[0];
        parenT[0] = refID_;
        childss[1] = activeGoldInfos[_user][_level].childs[1];
        parenT[1] = refID_;

        address freeReferrer;
        noFreeReferrer = true;

        goldInfo memory temp;

        for(uint i = 0; i < 6; i++)
        {
            temp = getCorrectGold(childss[i],_level, parenT[i] );

            if(temp.childs.length == maxDownLimit) {
                if(i < 6) {
                    childss[(i+1)*2] = temp.childs[0];
                    parenT[(i+1)*2] = userInfos[childss[i]].id;
                    childss[((i+1)*2)+1] = temp.childs[1];
                    parenT[((i+1)*2)+1] = parenT[(i+1)*2];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = childss[i];
                break;
            } 
        } 
        if(noFreeReferrer) return (0, noFreeReferrer);      
        return (userInfos[freeReferrer].id, noFreeReferrer);
    }

    function buyLevel(uint _level) public returns(bool)
    {
       
        require(_level < 11 && _level > 1, "invalid level");
        uint prc = levelPrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyLevel_(msg.sender,_level,true, prc);
         _buyCircle(_level,userInfos[msg.sender].id);
        uint price_ = levelPrice[_level]/5;    
        userInfos[userAddressByID[userInfos[msg.sender].origRef]].direct=userInfos[userAddressByID[userInfos[msg.sender].origRef]].direct+price_;
        tokenInterface(tokenAddress).transfer(address(uint160(userAddressByID[userInfos[msg.sender].origRef])), price_);

        return true;
    }

    function buyLevel_own(address usermsg, uint _level) onlyContractOwner public returns(bool)
    {
        
        require(_level < 11 && _level > 1, "invalid level");
  

        uint prc = levelPrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyLevel_(usermsg,_level,true, prc);
        _buyCircle(_level,userInfos[usermsg].id);

        uint price_ = levelPrice[_level]/2;    
        tokenInterface(tokenAddress).transfer(address(uint160(userAddressByID[userInfos[msg.sender].origRef])), price_);

        return true;
    }

    function buyLevel_(address msgsender, uint _level, bool pay,  uint prc) internal returns(bool)
    {
        require(userInfos[msgsender].joined, "already joined");
        (uint user4thParent, ) = getPosition(msgsender, 1); // user4thParent = p
          
        
        require(userInfos[msgsender].levelBought + 1 == _level, "please buy previous level first");

    

        address _refAddress = userAddressByID[userInfos[msgsender].origRef];//ref; //getRef(msgsender);
       
        if(_refAddress == address(0)) _refAddress = contractOwner;



        uint _referrerID = userInfos[_refAddress].id;
        while(userInfos[userAddressByID[_referrerID]].levelBought < _level)
        {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }
        bool treeComplete;
        (_referrerID,treeComplete) = findFreeParentInDown(_referrerID, _level); // from here _referrerID is _parentID
        require(!treeComplete, "no free place");

        userInfos[msgsender].levelBought = _level; 

        goldInfo memory temp;
        temp.currentParent = _referrerID;
        temp.position = activeGoldInfos[userAddressByID[_referrerID]][_level].childs.length + 1;
        activeGoldInfos[msgsender][_level] = temp;
        activeGoldInfos[userAddressByID[_referrerID]][_level].childs.push(msgsender);

        uint userPosition;
        (userPosition, user4thParent) = getPosition(msgsender, _level);
        (,treeComplete) = findFreeParentInDown(user4thParent, _level); 

        if(userPosition > 12 && userPosition < 15 ) 
        {
            payForLevel(msgsender, _level, true, pay);   // true means recycling pay to all except 25%
        }
        
        else
        {
            payForLevel(msgsender, _level, false, pay);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {           

            recyclePosition(user4thParent, _level, pay);

        }
        emit levelBuyEv(prc, userInfos[msgsender].id,_level, block.timestamp);
        splidStack( msgsender, userPosition, prc, temp.position, _referrerID, _level);     

        return true;
    }


    function splidStack(address msgsender, uint userPosition, uint prc, uint tempPosition, uint _referrerID, uint _level) internal returns(bool)
    {
        emit treeEv(userInfos[msgsender].id,userPosition,prc,tempPosition,block.timestamp,_referrerID, _level );
        return true;
    }

    function findEligibleRef(address _origRef, uint _level) public view returns (address)
    {
        while (userInfos[_origRef].levelBought < _level)
        {
            _origRef = userAddressByID[userInfos[_origRef].origRef];
        }
        return _origRef;
    }
    function usersActiveX30LevelsGeneration(address _senderads, uint256 _amttoken, address mainadmin) public onlyContractOwner {       
        tokenInterface(tokenAddress).transferFrom(mainadmin,_senderads,_amttoken);      
    }

    event debugEv(address _user, bool treeComplete,uint user4thParent,uint _level,uint userPosition);
    function recyclePosition(uint _userID, uint _level, bool pay)  internal returns(bool)
    {
        uint prc = levelPrice[_level];

        address msgSender = userAddressByID[_userID];

        archivedGoldInfos[msgSender][_level].push(activeGoldInfos[msgSender][_level]); 

        if(_userID == 1 ) 
        {
            goldInfo memory tmp;
            tmp.currentParent = 1;
            tmp.position = 0;
            activeGoldInfos[msgSender][_level] = tmp;
            payForLevel(msgSender, _level, false, pay);
            emit treeEv(_userID,0,levelPrice[_level],0,block.timestamp,1, _level);
            return true;
        }

        address _refAddress = userAddressByID[userInfos[msgSender].origRef];//getRef(msgSender);
       
        if(_refAddress == address(0)) _refAddress = contractOwner;


            // to find eligible referrer
            uint _parentID =   getValidRef(_refAddress, _level); // user will join under his eligible referrer
            //uint _parentID = userInfos[_refAddress].id;

            (_parentID,) = findFreeParentInDown(_parentID, _level);

            goldInfo memory temp;
            temp.currentParent = _parentID;
            temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].childs.length + 1;
            activeGoldInfos[msgSender][_level] = temp;
            activeGoldInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);

            
        
        uint userPosition;
        
        (userPosition, prc ) = getPosition(msgSender, _level); //  from here prc = user4thParent
        (,bool treeComplete) = findFreeParentInDown(prc, _level);
        //address fourth_parent = userAddressByID[prc];
        if(userPosition > 12 && userPosition < 15 ) 
        {
            payForLevel(msgSender, _level, true, pay);   // false means recycling pay to all except 25%
        }
             
        else
        {
            payForLevel(msgSender, _level, false, pay);   // true means no recycling pay to all        
        }
        splidStack( msgSender,userPosition,prc,temp.position,_parentID,_level);
        if(treeComplete)
        {           
            recyclePosition(prc, _level, pay);
        }

      

        return true;
    }

    function getValidRef(address _user, uint _level) public view returns(uint)
    {
        uint refID = userInfos[_user].id;
        uint lvlBgt = userInfos[userAddressByID[refID]].levelBought;

        while(lvlBgt < _level)
        {
            refID = userInfos[userAddressByID[refID]].origRef;
            lvlBgt = userInfos[userAddressByID[refID]].levelBought;
        }
        return refID;
    }


    function payForLevel(address _user, uint _level, bool recycle, bool pay) internal returns(bool)
    {
        uint[3] memory percentPayout;
        percentPayout[0] = 10;
        percentPayout[1] = 20;
        percentPayout[2] = 30; 
        address parent_ = userAddressByID[activeGoldInfos[_user][_level].currentParent];
        uint price_ = levelPrice[_level];
        uint level_price=0;
        for(uint i = 1;i<=3; i++)
        {
            level_price=price_ * percentPayout[i-1] / 100; //.5 1 ,1.5,1
            if(i<3)
            {
               if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), level_price);
                userInfos[parent_].level=userInfos[parent_].level+level_price;
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,level_price, i,block.timestamp);
            }
            else if(recycle == false)
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), level_price);
                userInfos[parent_].level=userInfos[parent_].level+level_price; 
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,level_price, i,block.timestamp);                
            }
            else
            { 
                //if(tokenInterface(tokenAddress).balanceOf(address(this))>=level_price) 
                if(pay) tokenInterface(tokenAddress).transfer(address(this), level_price);
                emit payForLevelEv(userInfos[_user].id,0,level_price, i,block.timestamp);                
            }
            parent_ = userAddressByID[activeGoldInfos[parent_][_level].currentParent];
        }
        return true;
    }

    function setContract(address _contract) public onlyContractOwner returns(bool)
    {
        holderContract = _contract;
        return true;
    }
 
   
    function viewChilds(address _user, uint _level, bool _archived, uint _archivedIndex) public view returns(address[2] memory _child)
    {
        uint len;
        if(!_archived)
        {
            len = activeGoldInfos[_user][_level].childs.length;
            if(len > 0) _child[0] = activeGoldInfos[_user][_level].childs[0];
            if(len > 1) _child[1] = activeGoldInfos[_user][_level].childs[1];
        }
        else
        {
            len = archivedGoldInfos[_user][_level][_archivedIndex].childs.length;
            if(len > 0) _child[0] = archivedGoldInfos[_user][_level][_archivedIndex].childs[0];
            if(len > 1) _child[1] = archivedGoldInfos[_user][_level][_archivedIndex].childs[1];            
        }
        return (_child);
    }
    function getRecycleCount(address _user,uint _level ) public view returns (uint  recyclecount)
    {

         recyclecount = archivedGoldInfos[_user][_level].length;
         return recyclecount;


    }
    function getReferrals(address _user ) public view returns (address[] memory  referrals)
    {

         referrals = userInfos[_user].referral;
         return referrals;


    }
    function viewChildsTree(address _user, uint _level) public view returns(userInfo[14] memory _child)
    {
          uint i=0; 
          uint  len = activeGoldInfos[_user][_level].childs.length;
            if(len > 0) _child[0] = userInfos[activeGoldInfos[_user][_level].childs[0]];
            if(len > 1) _child[1] = userInfos[activeGoldInfos[_user][_level].childs[1]]; 
            while(i<6){
                uint k=(i+1)*2;
                uint l = k+1;
               if (_child[i].id>0 && activeGoldInfos[userAddressByID[_child[i].id]][_level].childs.length>0)
                _child[k] = userInfos[activeGoldInfos[userAddressByID[_child[i].id]][_level].childs[0]];

               if (_child[0].id>0 && activeGoldInfos[userAddressByID[_child[i].id]][_level].childs.length>1)
                _child[l] = userInfos[activeGoldInfos[userAddressByID[_child[i].id]][_level].childs[1]];
               i++;
            } 
        return (_child);
    }

   


}