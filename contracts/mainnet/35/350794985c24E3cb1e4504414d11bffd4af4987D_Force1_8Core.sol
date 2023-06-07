/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

pragma solidity 0.8.0;

 
contract owned {
    address  public owner;
    address  internal newOwner;
modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
   
}
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        

        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X6) x6Matrix;
    }
    
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }


contract Force1_8Core is owned
{

    uint public maxDownLimit = 2;

    uint public lastCoreCount;
    uint public defaultRefID = 1;


    uint[13] public corePrice;
    

    address public tokenAddress;
    address public coreAddress;

    address holderContract = address(this);

    struct userInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
        address[] referral;
    }

    struct goldInfo {
        uint currentParent;
        uint position;
        address[] childs;
    }
    mapping (address => userInfo) public coreInfos;
    mapping (uint => address ) public coreAddressByID;

    mapping (address => mapping(uint => goldInfo)) public activeGoldInfos;
    mapping (address => mapping(uint => goldInfo[])) public archivedGoldInfos;

    mapping(address => bool) public regPermitted;
    mapping(address => uint) public corePermitted;



    struct rdata
    {
        uint user4thParent;
        uint level;
        bool pay;
        bool processed;
    }

   

    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForCoreEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event treeEv(uint _userID, uint _userPosition,uint amount, uint placing,uint timeNow,uint _parent, uint _level );

    constructor(address token)  {
        owner = msg.sender;
        tokenAddress = token;
        uint multiply = 10 ** 18;

        corePrice[1] = 5 * multiply;
        corePrice[2] = 10 * multiply;
        corePrice[3] = 20 * multiply;
        corePrice[4] = 30 * multiply;
        corePrice[5] = 50 * multiply;
        corePrice[6] = 100 * multiply;
        corePrice[7] = 200 * multiply;
        corePrice[8] = 300 * multiply;
        corePrice[9] = 500 * multiply;
        corePrice[10]= 1000 * multiply;
        corePrice[11]= 1500 * multiply;
        corePrice[12]= 2500 * multiply;


        userInfo memory UserInfo;
        lastCoreCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastCoreCount,
            origRef:lastCoreCount,            
            levelBought:15,
            referral: new address[](0)
        });
        coreInfos[owner] = UserInfo;
        coreAddressByID[lastCoreCount] = owner;

        goldInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        for(uint i=1;i<=255;i++)
        {
            activeGoldInfos[owner][i] = temp;
        }
    }

   


    function assignAd(address newTokenaddress) onlyOwner public returns(bool)
    {
        tokenAddress = newTokenaddress;
        return true;
    }



    function assignCoreAddress(address newcoreAddress) onlyOwner public returns(bool)
    {
        coreAddress = newcoreAddress;
        return true;
    }

    
    function subCore(address ref) public returns(bool)
    {
        
        address _refAddress = ref; 
       
        if(!coreInfos[_refAddress].joined) _refAddress = owner;
        
        uint prc = corePrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        subCore_(msg.sender, _refAddress, true, prc);
        return true;
    }

    function subCore_own(address usermsg, address ref) onlyOwner public returns(bool)
    {
       
        address _refAddress = ref;
       
        if(!coreInfos[_refAddress].joined) _refAddress = owner;
        
        uint prc = corePrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        subCore_(usermsg, _refAddress, true, prc);
        return true;
    }

    function subCore_(address msgsender, address _refAddress,bool pay, uint prc) internal returns(bool)
    {
        require(!coreInfos[msgsender].joined, "already joined");
        
        (uint user4thParent, ) = getPosition(msgsender, 1);
        require(user4thParent<254, "no place under this referrer");
       
        address origRef = _refAddress;
        uint _referrerID = coreInfos[_refAddress].id;
        (uint _parentID,bool treeComplete  ) = findFreeParentInDown(_referrerID, 1);
        require(!treeComplete, "No free place");

        lastCoreCount++;
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: lastCoreCount,
            origRef:coreInfos[_refAddress].id,            
            levelBought:1,
            referral: new address[](0)
        });
        coreInfos[msgsender] = UserInfo;
        coreAddressByID[lastCoreCount] = msgsender;
        coreInfos[origRef].referral.push(msgsender);

        coreInfos[msgsender].referral.push(_refAddress);       

        goldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[coreAddressByID[_parentID]][1].childs.length + 1;
        activeGoldInfos[msgsender][1] = temp;
        activeGoldInfos[coreAddressByID[_parentID]][1].childs.push(msgsender);

       
        uint userPosition;
        (userPosition, user4thParent) = getPosition(msgsender, 1);
        (,treeComplete) = findFreeParentInDown(user4thParent, 1);
        if(userPosition > 506 && userPosition < 511 ) 
        {
            payForCore(msgsender, 1, true, pay,true);   
        }
       
        else
        {
            payForCore(msgsender, 1, false, pay, true);   
        }
        
        if(treeComplete)
        {
            recyclePosition(user4thParent,1, pay );
        }
        splitPart(lastCoreCount,_referrerID,msgsender,userPosition,prc,temp.position,temp.currentParent );
        
       

        uint price_ = corePrice[1]/2;    
        tokenInterface(tokenAddress).transfer(address(uint160(_refAddress)), price_);

        return true;
    }


    function splitPart(uint lastCoreCount_, uint _referrerID, address msgsender, uint userPosition, uint prc,uint tempPosition, uint tempCurrentParent ) internal returns(bool)
    {
        emit regLevelEv(lastCoreCount_,_referrerID,block.timestamp, msgsender,coreAddressByID[_referrerID]);
        emit treeEv(lastCoreCount_,userPosition,prc,tempPosition, block.timestamp,  tempCurrentParent, 1 );
        return true;
    }

    function getPosition(address _user, uint _level) public view returns(uint recyclePosition_, uint recycleID)
    {
        uint a;
        uint b;
        uint c;
        uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position;

        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        b = activeGoldInfos[coreAddressByID[parent_]][_level].position;
        if(parent_ == 1 ) id1Found = true;

        if(!id1Found)
        {
            parent_ = activeGoldInfos[coreAddressByID[parent_]][_level].currentParent;
            c = activeGoldInfos[coreAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }

        if(!id1Found)
        {
            parent_ = activeGoldInfos[coreAddressByID[parent_]][_level].currentParent;
            d = activeGoldInfos[coreAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }
        
        if(!id1Found) parent_ = activeGoldInfos[coreAddressByID[parent_]][_level].currentParent;
        
        if (a == 2 && b == 2 && c == 2 && d == 2 ) return (510, parent_);
        if (a == 1 && b == 2 && c == 2 && d == 2 ) return (509, parent_);
        if (a == 2 && b == 1 && c == 2 && d == 2 ) return (508, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 2 ) return (507, parent_);
        if (a == 2 && b == 1 && c == 1 && d == 1 ) return (256, parent_);
        if (a == 1 && b == 2 && c == 1 && d == 1 ) return (257, parent_);
        if (a == 2 && b == 2 && c == 1 && d == 1 ) return (258, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 1 ) return (259, parent_);        
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
        address _user = coreAddressByID[refID_];
        if(activeGoldInfos[_user][_level].childs.length < maxDownLimit) return (refID_, false);

        address[511] memory childss;
        uint[511] memory parenT;

        childss[0] = activeGoldInfos[_user][_level].childs[0];
        parenT[0] = refID_;
        childss[1] = activeGoldInfos[_user][_level].childs[1];
        parenT[1] = refID_;

        address freeReferrer;
        noFreeReferrer = true;

        goldInfo memory temp;

        for(uint i = 0; i < 254; i++)
        {
            temp = getCorrectGold(childss[i],_level, parenT[i] );

            if(temp.childs.length == maxDownLimit) {
                if(i < 2) {
                    childss[(i+1)*2] = temp.childs[0];
                    parenT[(i+1)*2] = coreInfos[childss[i]].id;
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
        return (coreInfos[freeReferrer].id, noFreeReferrer);
    }

    function buyCore(uint _level) public returns(bool)
    {
       
        require(_level < 13 && _level > 1, "invalid level");
        uint prc = corePrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyCore_(msg.sender,_level,true, prc);
        
        uint price_ = corePrice[_level]/2;    
        tokenInterface(tokenAddress).transfer(address(uint160(coreAddressByID[coreInfos[msg.sender].origRef])), price_);

        return true;
    }

    function buyCore_own(address usermsg, uint _level) onlyOwner public returns(bool)
    {
        
       require(_level < 13 && _level > 1, "invalid level");
  

        uint prc = corePrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyCore_(usermsg,_level,true, prc);

        uint price_ = corePrice[_level]/2;    
        tokenInterface(tokenAddress).transfer(address(uint160(coreAddressByID[coreInfos[msg.sender].origRef])), price_);

        return true;
    }

    function buyCore_(address msgsender, uint _level, bool pay,  uint prc) internal returns(bool)
    {
        require(coreInfos[msgsender].joined, "already joined");
        (uint user4thParent, ) = getPosition(msgsender, 1); 
          
        
        require(coreInfos[msgsender].levelBought + 1 == _level, "please buy previous level first");

    

        address _refAddress = coreAddressByID[coreInfos[msgsender].origRef];
       
        if(_refAddress == address(0)) _refAddress = owner;



        uint _referrerID = coreInfos[_refAddress].id;
        while(coreInfos[coreAddressByID[_referrerID]].levelBought < _level)
        {
            _referrerID = coreInfos[coreAddressByID[_referrerID]].origRef;
        }
        bool treeComplete;
        (_referrerID,treeComplete) = findFreeParentInDown(_referrerID, _level); 
        require(!treeComplete, "no free place");

        coreInfos[msgsender].levelBought = _level; 

        goldInfo memory temp;
        temp.currentParent = _referrerID;
        temp.position = activeGoldInfos[coreAddressByID[_referrerID]][_level].childs.length + 1;
        activeGoldInfos[msgsender][_level] = temp;
        activeGoldInfos[coreAddressByID[_referrerID]][_level].childs.push(msgsender);

        uint userPosition;

        (userPosition, user4thParent) = getPosition(msgsender, _level);
        (,treeComplete) = findFreeParentInDown(user4thParent, _level); 

        if(userPosition > 506 && userPosition < 511 ) 
        {
            payForCore(msgsender, _level, true, pay, true);   
        }
        
        else
        {
            payForCore(msgsender, _level, false, pay, true);   
        }
        
        if(treeComplete)
        {           

            recyclePosition(user4thParent, _level, pay);

        }
        emit levelBuyEv(prc, coreInfos[msgsender].id,_level, block.timestamp);
        splidStack( msgsender, userPosition, prc, temp.position, _referrerID, _level);     

        return true;
    }


    function splidStack(address msgsender, uint userPosition, uint prc, uint tempPosition, uint _referrerID, uint _level) internal returns(bool)
    {
        emit treeEv(coreInfos[msgsender].id,userPosition,prc,tempPosition,block.timestamp,_referrerID, _level );
        return true;
    }

    function findEligibleRef(address _origRef, uint _level) public view returns (address)
    {
        while (coreInfos[_origRef].levelBought < _level)
        {
            _origRef = coreAddressByID[coreInfos[_origRef].origRef];
        }
        return _origRef;
    }
    

    event debugEv(address _user, bool treeComplete,uint user4thParent,uint _level,uint userPosition);
    function recyclePosition(uint _userID, uint _level, bool pay)  internal returns(bool)
    {
        uint prc = corePrice[_level];

        address msgSender = coreAddressByID[_userID];

        archivedGoldInfos[msgSender][_level].push(activeGoldInfos[msgSender][_level]); 

        if(_userID == 1 ) 
        {
            goldInfo memory tmp;
            tmp.currentParent = 1;
            tmp.position = 0;
            activeGoldInfos[msgSender][_level] = tmp;
            payForCore(msgSender, _level, false, pay, true);
            emit treeEv(_userID,0,corePrice[_level],0,block.timestamp,1, _level );
            return true;
        }

        address _refAddress = coreAddressByID[coreInfos[msgSender].origRef];
       
        if(_refAddress == address(0)) _refAddress = owner;


           
            uint _parentID =   getValidRef(_refAddress, _level);
            

            (_parentID,) = findFreeParentInDown(_parentID, _level);

            goldInfo memory temp;
            temp.currentParent = _parentID;
            temp.position = activeGoldInfos[coreAddressByID[_parentID]][_level].childs.length + 1;
            activeGoldInfos[msgSender][_level] = temp;
            activeGoldInfos[coreAddressByID[_parentID]][_level].childs.push(msgSender);

            
        
        uint userPosition;
        
        (userPosition, prc ) = getPosition(msgSender, _level); 
        (,bool treeComplete) = findFreeParentInDown(prc, _level);
        
        if(userPosition > 506 && userPosition < 511 ) 
        {
            payForCore(msgSender, _level, true, pay, true);   
        }
             
        else
        {
            payForCore(msgSender, _level, false, pay, true);         
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
        uint refID = coreInfos[_user].id;
        uint lvlBgt = coreInfos[coreAddressByID[refID]].levelBought;

        while(lvlBgt < _level)
        {
            refID = coreInfos[coreAddressByID[refID]].origRef;
            lvlBgt = coreInfos[coreAddressByID[refID]].levelBought;
        }
        return refID;
    }


    function payForCore(address _user, uint _level, bool recycle, bool pay, bool payAll) internal returns(bool)
    {
        uint[8] memory percentPayout;
        percentPayout[0] = 10;
        percentPayout[1] = 10;
        percentPayout[2] = 10;
        percentPayout[3] = 10;
        percentPayout[4] = 10;   
        percentPayout[5] = 10;
        percentPayout[6] = 15;       
        if(payAll) percentPayout[7] = 25;

        address parent_ = coreAddressByID[activeGoldInfos[_user][_level].currentParent];
        uint price_ = corePrice[_level]/2;
        for(uint i = 1;i<=8; i++)
        {
            if(i<8)
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), price_ * percentPayout[i-1] / 100);
                emit payForCoreEv(coreInfos[_user].id,coreInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,block.timestamp);
            }
            else if(recycle == false)
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), price_ * percentPayout[i-1] / 100);
                emit payForCoreEv(coreInfos[_user].id,coreInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,block.timestamp);                
            }
            else
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(holderContract)), price_ * percentPayout[i-1] / 100);
                emit payForCoreEv(coreInfos[_user].id,0,price_ * percentPayout[i-1] / 100, i,block.timestamp);                
            }
            parent_ = coreAddressByID[activeGoldInfos[parent_][_level].currentParent];
        }
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

   


}