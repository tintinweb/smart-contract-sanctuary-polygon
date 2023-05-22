/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19.0;

contract ContractOwnership {
    address payable public ownerAddress;
    address payable internal newOwnerAddress;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == ownerAddress);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwnerAddress = payable(_newOwner);
    }

    function acceptOwnership() public {
        require(msg.sender == newOwnerAddress);
        emit OwnershipTransferred(ownerAddress, newOwnerAddress);
        ownerAddress = payable(newOwnerAddress);
        newOwnerAddress = payable(address(0));
    }
}

contract EliteForceS30 is ContractOwnership {
    address payable internal constant FIRST_PARTNER_ADDRESS = payable(0x305674E5Abe6AcE957802d33660b2715285ecB9C);
    address payable internal constant SECOND_PARTNER_ADDRESS = payable(0x852b82010917099fc229A67e0012ec241d9cc2A8);
    uint internal constant FIRST_PARTNER_PERCENT = 9; // 15% * 60%
    uint internal constant SECOND_PARTNER_PERCENT = 6; // 15% * 40%
    uint internal constant HOLDER_PERCENT = 85; // holder: 85%
    uint public maxDownLimit = 2;
    uint public lastIDCount;
    uint public defaultRefID = 1;

    uint256[11] public levelPrice;
    uint256 public multiply;

    address public levelAddress;

    address payable internal eliteContractAddress = payable(address(this));

    struct UserInfo {
        bool joined;
        uint id;
        uint origRef;
        uint levelBought;
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

    event DirectPaidEvent(uint userID, uint referrerID, uint256 amount, uint level);
    event PayForLevelEvent(uint userID, uint parentID, uint256 amount, uint fromDown);
    event RegisterLevelEvent(uint userID, uint referrerID, address userAddress, uint amount);
    event LevelBuyEvent(uint userID, uint256 amount, uint level);
    event TreeEvent(uint userID, uint userPosition, uint256 amount, uint placing, uint parentID, uint level);

    receive() external payable {}
    fallback() external payable {}

    constructor() {
        ownerAddress = payable(msg.sender);

        // Fixed level price - in test, the price is 0.02 MATIC
        multiply = 10 ** 15;
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
    }

    function setLevelAddress(address newLevelAddress) public onlyOwner returns (bool)
    {
        levelAddress = newLevelAddress;
        return true;
    }

    function registerUser(address referrerAddress) public payable returns (bool)
    {
        require(referrerAddress != address(0), "Referrer address is 0");
        // If referrerAddress is not joined -> take ownerAddress as referrerAddress
        if (!userInfos[referrerAddress].joined) referrerAddress = ownerAddress;

        // Pay to register as level 1
        require(msg.value == levelPrice[1], "Need to transfer 20 MATIC to register");
        eliteContractAddress.transfer(msg.value);

        _registerUser(msg.sender, referrerAddress, true);
        return true;
    }

    function registerOwner(address userAddress, address referrerAddress) public onlyOwner payable returns (bool)
    {
        require(referrerAddress != address(0), "Referrer address address is 0");
        if (!userInfos[referrerAddress].joined) referrerAddress = ownerAddress;

        // Pay to register as level 1
        require(msg.value == levelPrice[1], "Need to transfer 20 MATIC to register");
        eliteContractAddress.transfer(msg.value);

        _registerUser(userAddress, referrerAddress, true);
        return true;
    }

    function _registerUser(address userAddress, address refererAddress, bool pay) internal returns (bool)
    {
        require(!userInfos[userAddress].joined, "Already joined");

        (uint user4thParent,) = getPosition(userAddress, 1);
        // user4thParent = p here for stack too deep
        require(user4thParent < 30, "No place under this referrer");

        address origRef = refererAddress;
        uint referrerID = userInfos[refererAddress].id;
        (uint parentID,bool treeComplete) = findFreeParentInDown(referrerID, 1);
        require(!treeComplete, "No free place");

        lastIDCount++;
        UserInfo memory userInfo;
        userInfo = UserInfo({
            joined: true,
            id: lastIDCount,
            origRef: userInfos[refererAddress].id,
            levelBought: 1,
            referral: new address[](0)
        });
        userInfos[userAddress] = userInfo;
        userAddressByID[lastIDCount] = userAddress;

        userInfos[origRef].referral.push(userAddress);
        userInfos[userAddress].referral.push(refererAddress);

        GoldInfo memory temp;
        temp.currentParent = parentID;
        temp.position = activeGoldInfos[userAddressByID[parentID]][1].children.length + 1;
        activeGoldInfos[userAddress][1] = temp;
        activeGoldInfos[userAddressByID[parentID]][1].children.push(userAddress);


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
        _splitPart(lastIDCount, referrerID, userAddress, userPosition, levelPrice[1], temp.position, temp.currentParent);

        // Pay 50% for referrer
        _payoutReferrer(payable(refererAddress), levelPrice[1] / 2, true);
        // Dispatch direct paid event - to calculate the direct profit
        emit DirectPaidEvent(lastIDCount, referrerID, levelPrice[1] / 2, 1);

        return true;
    }

    function _splitPart(uint lastIDCount_, uint _referrerID, address msgSender, uint userPosition, uint prc, uint tempPosition, uint tempCurrentParent) internal returns (bool)
    {
        emit RegisterLevelEvent(lastIDCount_, _referrerID, msgSender, prc);
        emit TreeEvent(lastIDCount_, userPosition, prc, tempPosition, tempCurrentParent, 1);
        return true;
    }

    function getPosition(address userAddress, uint level) public view returns (uint recyclePosition_, uint recycleID)
    {
        uint a;
        uint b;
        uint c;
        uint d;
        bool id1Found;
        a = activeGoldInfos[userAddress][level].position;

        uint parentID = activeGoldInfos[userAddress][level].currentParent;
        b = activeGoldInfos[userAddressByID[parentID]][level].position;
        // Parent is holder
        if (parentID == 1) id1Found = true;

        // Layer 2
        if (!id1Found)
        {
            parentID = activeGoldInfos[userAddressByID[parentID]][level].currentParent;
            c = activeGoldInfos[userAddressByID[parentID]][level].position;
            if (parentID == 1) id1Found = true;
        }

        // Layer 3
        if (!id1Found)
        {
            parentID = activeGoldInfos[userAddressByID[parentID]][level].currentParent;
            d = activeGoldInfos[userAddressByID[parentID]][level].position;
            if (parentID == 1) id1Found = true;
        }

        if (!id1Found) parentID = activeGoldInfos[userAddressByID[parentID]][level].currentParent;

        if (a == 2 && b == 2 && c == 2 && d == 2) return (30, parentID);
        if (a == 1 && b == 2 && c == 2 && d == 2) return (29, parentID);
        if (a == 2 && b == 1 && c == 2 && d == 2) return (28, parentID);
        if (a == 1 && b == 1 && c == 2 && d == 2) return (27, parentID);
        if (a == 2 && b == 1 && c == 1 && d == 1) return (16, parentID);
        if (a == 1 && b == 2 && c == 1 && d == 1) return (17, parentID);
        if (a == 2 && b == 2 && c == 1 && d == 1) return (18, parentID);
        if (a == 1 && b == 1 && c == 2 && d == 1) return (19, parentID);
        else return (1, parentID);

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

    function buyLevel(uint nextLevel) public payable returns (bool)
    {
        require(nextLevel < 11 && nextLevel > 1, "invalid level");
        // Buy level
        require(msg.value == levelPrice[nextLevel], "Invalid level price");
        eliteContractAddress.transfer(msg.value);
        _buyLevel(msg.sender, nextLevel, true, levelPrice[nextLevel]);

        address _refAddress = address(uint160(userAddressByID[userInfos[msg.sender].origRef]));
        _payoutReferrer(payable(_refAddress), levelPrice[nextLevel] / 2, true);
        // Dispatch direct paid event - to calculate the direct profit
        emit DirectPaidEvent(userInfos[msg.sender].id, userInfos[msg.sender].origRef, levelPrice[nextLevel] / 2, nextLevel);

        return true;
    }

    // Owner buy level for user
    function buyLevelOwner(address userAddress, uint nextLevel) public payable onlyOwner returns (bool)
    {
        require(nextLevel < 11 && nextLevel > 1, "invalid level");
        // Buy level
        require(msg.value == levelPrice[nextLevel], "Invalid level price");
        eliteContractAddress.transfer(msg.value);
        _buyLevel(userAddress, nextLevel, true, levelPrice[nextLevel]);

        address referrerAddress = address(uint160(userAddressByID[userInfos[userAddress].origRef]));
        _payoutReferrer(payable(referrerAddress), levelPrice[nextLevel] / 2, true);
        // Dispatch direct paid event - to calculate the direct profit
        emit DirectPaidEvent(userInfos[userAddress].id, userInfos[userAddress].origRef, levelPrice[nextLevel] / 2, nextLevel);

        return true;
    }

    function _buyLevel(address userAddress, uint nextLevel, bool pay, uint prc) internal returns (bool)
    {
        require(userInfos[userAddress].joined, "Need joined to buy new level");
        (uint user4thParent,) = getPosition(userAddress, 1);
        // user4thParent = p
        require(userInfos[userAddress].levelBought + 1 == nextLevel, "please buy previous level first");

        address _refAddress = userAddressByID[userInfos[userAddress].origRef];

        // If referrerAddress not found, take owner as referrer
        if (_refAddress == address(0)) _refAddress = ownerAddress;

        uint _referrerID = userInfos[_refAddress].id;
        while (userInfos[userAddressByID[_referrerID]].levelBought < nextLevel) {
            _referrerID = userInfos[userAddressByID[_referrerID]].origRef;
        }
        bool treeComplete;
        (_referrerID, treeComplete) = findFreeParentInDown(_referrerID, nextLevel);
        // from here _referrerID is _parentID
        require(!treeComplete, "no free place");

        userInfos[userAddress].levelBought = nextLevel;

        GoldInfo memory temp;
        temp.currentParent = _referrerID;
        temp.position = activeGoldInfos[userAddressByID[_referrerID]][nextLevel].children.length + 1;
        activeGoldInfos[userAddress][nextLevel] = temp;
        activeGoldInfos[userAddressByID[_referrerID]][nextLevel].children.push(userAddress);

        uint userPosition;
        (userPosition, user4thParent) = getPosition(userAddress, nextLevel);
        (, treeComplete) = findFreeParentInDown(user4thParent, nextLevel);

        if (userPosition > 28 && userPosition < 31) {
            _payoutForLevel(userAddress, nextLevel, true, pay, true);
            // true means recycling pay to all except 25%
        } else {
            _payoutForLevel(userAddress, nextLevel, false, pay, true);
            // false means no recycling pay to all
        }

        if (treeComplete) {
            _recyclePosition(user4thParent, nextLevel, pay);
        }
        emit LevelBuyEvent(userInfos[userAddress].id, prc, nextLevel);
        _splitStack(userAddress, userPosition, prc, temp.position, _referrerID, nextLevel);

        return true;
    }


    function _splitStack(address senderAddress, uint userPosition, uint prc, uint tempPosition, uint _referrerID, uint _level) internal returns (bool)
    {
        emit TreeEvent(userInfos[senderAddress].id, userPosition, prc, tempPosition, _referrerID, _level);
        return true;
    }

    function findEligibleRef(address _origRef, uint _level) public view returns (address)
    {
        while (userInfos[_origRef].levelBought < _level) {
            _origRef = userAddressByID[userInfos[_origRef].origRef];
        }
        return _origRef;
    }

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
            emit TreeEvent(_userID, 0, levelPrice[_level], 0, 1, _level);
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
                if (pay) _payoutHolder += _payoutReferrer(payable(_parent), _payout, false);
                emit PayForLevelEvent(userInfos[_user].id, userInfos[_parent].id, _payout, i);
            }
            else if (recycle == false)
            {
                if (pay) _payoutHolder += _payoutReferrer(payable(_parent), _payout, false);
                emit PayForLevelEvent(userInfos[_user].id, userInfos[_parent].id, _payout, i);
            }
            else
            {
                // Payout for holder -> store to pay later
                if (pay) _payoutHolder += _payout;
                emit PayForLevelEvent(userInfos[_user].id, 0, _payout, i);
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

    function setContract(address payable _contract) public onlyOwner returns (bool)
    {
        eliteContractAddress = _contract;
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

    // Payout from system to referrer
    function _payoutReferrer(address payable referrerAddress, uint payout, bool forcePayHolder) internal returns (uint)
    {
        // Pay to owner -> store to pay later
        if (referrerAddress == ownerAddress) {
            if (forcePayHolder) {
                _splitPayout(payout);
                return 0;
            } else {
                return payout;
            }
        } else { // Pay to user referrer -> pay immediately
            referrerAddress.transfer(payout);
            return 0;
        }
    }

    function _splitPayout(uint256 price) internal
    {
        // Send to owner
        ownerAddress.transfer(HOLDER_PERCENT * price / 100);

        // Send to first partner
        FIRST_PARTNER_ADDRESS.transfer(FIRST_PARTNER_PERCENT * price / 100);

        // Send to second partner
        SECOND_PARTNER_ADDRESS.transfer(SECOND_PARTNER_PERCENT * price / 100);
    }
}