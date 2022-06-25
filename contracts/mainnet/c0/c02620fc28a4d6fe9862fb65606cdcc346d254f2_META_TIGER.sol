/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

pragma solidity >=0.4.23 <0.6.0;

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

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract META_TIGER is Ownable {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;   
        mapping(uint8 => bool) activeX12Levels;      
        mapping(uint8 => X12) x12Matrix;
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
    IERC20 public TokenStable;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8  matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
	event SentIncomeDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level, uint256 levelPricee);
    
    
    constructor(address ownerAddress, address _token) public {
        levelPrice[1] = 1 * ( 10  ** 18 );
        levelPrice[2] = 2 * ( 10  ** 18 );
        levelPrice[3] = 5 * ( 10  ** 18 );
        levelPrice[4] = 10 * ( 10  ** 18 );
        levelPrice[5] = 20 * ( 10  ** 18 );
        levelPrice[6] = 30 * ( 10  ** 18 );
        levelPrice[7] = 50 * ( 10  ** 18 );
        levelPrice[8] = 100 * ( 10  ** 18 );
        levelPrice[9] = 200 * ( 10  ** 18 );
        levelPrice[10] = 300 * ( 10  ** 18 );
        levelPrice[11] = 500 * ( 10  ** 18 );
        levelPrice[12] = 1000 * ( 10  ** 18 );
        
        
        owner = ownerAddress;
        TokenStable = IERC20(_token);
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {           
            users[ownerAddress].activeX12Levels[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix==3, "invalid matrix");
        //require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
       
        require(!users[msg.sender].activeX12Levels[level], "level already activated"); 

        if (users[msg.sender].x12Matrix[level-1].blocked) {
            users[msg.sender].x12Matrix[level-1].blocked = false;
        }

        address freeX12Referrer = findFreeX12Referrer(msg.sender, level);
        
        users[msg.sender].activeX12Levels[level] = true;
        updateX12Referrer(msg.sender, freeX12Referrer, level);
        
        emit Upgrade(msg.sender, freeX12Referrer, 3, level);
       
    }    
    
    function registration(address userAddress, address referrerAddress) private {
       // require(msg.value == 0.03 * ( 10  ** 18 ), "registration cost 0.05");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;        
       
        users[userAddress].activeX12Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
      
        updateX12Referrer(userAddress, findFreeX12Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
        
    
    function usersActiveX12Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX12Levels[level];
    }

    
    
    function usersX12Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory,address[] memory, bool, address) {
        return (users[userAddress].x12Matrix[level].currentReferrer,
                users[userAddress].x12Matrix[level].firstLevelReferrals,
                users[userAddress].x12Matrix[level].secondLevelReferrals,
                users[userAddress].x12Matrix[level].thirdlevelreferrals,
                users[userAddress].x12Matrix[level].blocked,
                users[userAddress].x12Matrix[level].closedPart);
    }
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        
            while (true) {
                if (users[receiver].x12Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, matrix, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x12Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
      
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

       // if (!address(uint160(receiver)).send(levelPrice[level])) {
       //     return address(uint160(receiver)).transfer(address(this).balance);
       // }
        
        if (!TokenStable.transferFrom(msg.sender, receiver, levelPrice[level])) {
            TokenStable.transferFrom(msg.sender, owner, levelPrice[level]);
        }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
		emit SentIncomeDividends(_from, receiver, matrix, level, levelPrice[level]);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        TokenStable = IERC20(_token);
        return true;
    }
    
    
    /*  12X */
    function updateX12Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX12Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x12Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 3, level, uint8(users[referrerAddress].x12Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 3, level);
            }
            
            address ref = users[referrerAddress].x12Matrix[level].currentReferrer;            
            users[ref].x12Matrix[level].secondLevelReferrals.push(userAddress); 
            
            address ref1 = users[ref].x12Matrix[level].currentReferrer;            
            users[ref1].x12Matrix[level].thirdlevelreferrals.push(userAddress);
            
            uint len = users[ref].x12Matrix[level].firstLevelReferrals.length;
            uint8 toppos=2;
            if(ref1!=address(0x0)){
            if(ref==users[ref1].x12Matrix[level].firstLevelReferrals[0]){
                toppos=1;
            }else
            {
                toppos=2;
            }
            }
            if ((len == 2) && 
                (users[ref].x12Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x12Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x12Matrix[level].place.push(5);
                    emit NewUserPlace(userAddress, ref, 3, level, 5); 
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    users[ref].x12Matrix[level].place.push(6);
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                }
            }  else
            if ((len == 1 || len == 2) &&
                    users[ref].x12Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x12Matrix[level].place.push(3);
                    emit NewUserPlace(userAddress, ref, 3, level, 3);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+3);
                } else {
                    users[ref].x12Matrix[level].place.push(4);
                    emit NewUserPlace(userAddress, ref, 3, level, 4);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+4);
                }
            } else if (len == 2 && users[ref].x12Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x12Matrix[level].firstLevelReferrals.length == 1) {
                    users[ref].x12Matrix[level].place.push(5);
                     emit NewUserPlace(userAddress, ref, 3, level, 5);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+5);
                } else {
                    users[ref].x12Matrix[level].place.push(6);
                    emit NewUserPlace(userAddress, ref, 3, level, 6);
                    emit NewUserPlace(userAddress, ref1, 3, level, (4*toppos)+6);
                }
            }
            
            return updateX12ReferrerSecondLevel(userAddress, ref1, level);
        }
         if (users[referrerAddress].x12Matrix[level].secondLevelReferrals.length < 4) {
        users[referrerAddress].x12Matrix[level].secondLevelReferrals.push(userAddress);
        address secondref = users[referrerAddress].x12Matrix[level].currentReferrer; 
        if(secondref==address(0x0))
        secondref=owner;
        if (users[referrerAddress].x12Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX12(userAddress, referrerAddress, level, false);
            return updateX12ReferrerSecondLevel(userAddress, secondref, level);
        } else if (users[referrerAddress].x12Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX12(userAddress, referrerAddress, level, true);
            return updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        if (users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length < 
            2) {
            updateX12(userAddress, referrerAddress, level, false);
        } else {
            updateX12(userAddress, referrerAddress, level, true);
        }
        
        updateX12ReferrerSecondLevel(userAddress, secondref, level);
        }
        
        
        else  if (users[referrerAddress].x12Matrix[level].thirdlevelreferrals.length < 8) {
        users[referrerAddress].x12Matrix[level].thirdlevelreferrals.push(userAddress);

      if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 0);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 1);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[2]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 2);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }else if (users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[3]].x12Matrix[level].firstLevelReferrals.length<2) {
            updateX12Fromsecond(userAddress, referrerAddress, level, 3);
            return updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        //updateX12Fromsecond(userAddress, referrerAddress, level, users[referrerAddress].x12Matrix[level].secondLevelReferrals.length);
          
        
        updateX12ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
    }

    function updateX12(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdlevelreferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].firstLevelReferrals[0], 3, level, uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 2 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length));
           
            users[referrerAddress].x12Matrix[level].place.push(2 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length));
           
           if(referrerAddress!=address(0x0) && referrerAddress!=owner){
            if(users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals[0]==referrerAddress)
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level,6 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length));
            else
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, (10 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[0]].x12Matrix[level].firstLevelReferrals.length)));
            //set current level
           }
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[0];
           
        } else {
            users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].thirdlevelreferrals.push(userAddress);
            
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].firstLevelReferrals[1], 3, level, uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 3, level, 4 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));
            
            users[referrerAddress].x12Matrix[level].place.push(4 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));
            
            if(referrerAddress!=address(0x0) && referrerAddress!=owner){
            if(users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals[0]==referrerAddress)
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, 8 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));
            else
            emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].currentReferrer, 3, level, 12 + uint8(users[users[referrerAddress].x12Matrix[level].firstLevelReferrals[1]].x12Matrix[level].firstLevelReferrals.length));
            }
            //set current level
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX12Fromsecond(address userAddress, address referrerAddress, uint8 level,uint pos) private {
            users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.push(userAddress);
             users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].secondLevelReferrals.push(userAddress);
            
            
            uint8 len=uint8(users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].firstLevelReferrals.length);
            
            uint temppos=users[referrerAddress].x12Matrix[level].place[pos];
            emit NewUserPlace(userAddress, referrerAddress, 3, level,uint8(((temppos)*2)+len)); //third position
            if(temppos<5){
            emit NewUserPlace(userAddress, users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer, 3, level,uint8((((temppos-3)+1)*2)+len));
                       users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].place.push((((temppos-3)+1)*2)+len);
            }else{
            emit NewUserPlace(userAddress, users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer, 3, level,uint8((((temppos-3)-1)*2)+len));
                       users[users[users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos]].x12Matrix[level].currentReferrer].x12Matrix[level].place.push((((temppos-3)-1)*2)+len);
            }
             emit NewUserPlace(userAddress, users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos], 3, level, len); //first position
           //set current level
            
            users[userAddress].x12Matrix[level].currentReferrer = users[referrerAddress].x12Matrix[level].secondLevelReferrals[pos];
           
       
    }
    
    function updateX12ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if(referrerAddress==address(0x0)){
            return sendETHDividends(owner, userAddress, 3, level);
        }
        if (users[referrerAddress].x12Matrix[level].thirdlevelreferrals.length < 8) {
            return sendETHDividends(referrerAddress, userAddress, 3, level);
        }
        
        address[] memory x12 = users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].firstLevelReferrals;
        
        if (x12.length == 2) {
            if (x12[0] == referrerAddress ||
                x12[1] == referrerAddress) {
                users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].closedPart = referrerAddress;
            } else if (x12.length == 1) {
                if (x12[0] == referrerAddress) {
                    users[users[users[referrerAddress].x12Matrix[level].currentReferrer].x12Matrix[level].currentReferrer].x12Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x12Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].thirdlevelreferrals = new address[](0);
        users[referrerAddress].x12Matrix[level].closedPart = address(0);
        users[referrerAddress].x12Matrix[level].place=new uint[](0);

        if (!users[referrerAddress].activeX12Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x12Matrix[level].blocked = true;
        }

        users[referrerAddress].x12Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX12Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 3, level);
            updateX12Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 3, level);
            sendETHDividends(owner, userAddress, 3, level);
        }
    }
    
     function findFreeX12Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX12Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
}