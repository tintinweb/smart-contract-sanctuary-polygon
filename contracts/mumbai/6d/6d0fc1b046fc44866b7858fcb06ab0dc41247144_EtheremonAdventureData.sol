/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// File: contracts/EthermonAdventureData.sol

/**
 *Submitted for verification at Etherscan.io on 2018-09-03
 */

pragma solidity ^0.6.6;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicAccessControl {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() external onlyOwner {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) external onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) external onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) external onlyOwner {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonAdventureData is BasicAccessControl {
    using SafeMath for uint256;

    // total revenue
    struct LandRevenue {
        uint256 emonAmount;
    }
    struct LandTokenClaim {
        uint256 emonAmount;
    }

    struct ExploreData {
        address sender;
        uint256 typeId;
        uint256 monsterId;
        uint256 siteId;
        uint256 itemSeed;
        uint256 startAt; // blocknumber
    }

    uint256 public exploreCount = 0;
    mapping(uint256 => ExploreData) public exploreData; // explore count => data
    mapping(address => uint256) public explorePending; // address => explore id

    mapping(uint256 => LandTokenClaim) public claimData; // tokenid => claim info
    mapping(uint256 => uint256) public landToken;
    mapping(uint256 => LandRevenue) public siteData; // class id => amount
    mapping(uint256 => uint256[]) public siteClassToken; // class id => token ids

    function addLandRevenue(
        uint256 _siteId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external onlyModerators {
        LandRevenue storage revenue = siteData[_siteId];
        revenue.emonAmount = revenue.emonAmount.add(_emonAmount);
    }

    function addTokenClaim(
        uint256 _tokenId,
        uint256 _emonAmount
    ) external onlyModerators {
        LandTokenClaim storage claim = claimData[_tokenId];
        claim.emonAmount = claim.emonAmount.add(_emonAmount);
    }

    function addTokenToClass(
        uint256 _classId,
        uint256 _tokenId
    ) external onlyModerators {
        siteClassToken[_classId].push(_tokenId);
    }

    function HasCapped(uint32 _siteId) external view returns (bool) {
        uint256[] memory tokenIds = siteClassToken[_siteId];
        return tokenIds.length < 20;
    }

    function addExploreData(
        address _sender,
        uint256 _typeId,
        uint256 _monsterId,
        uint256 _siteId,
        uint256 _startAt,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external onlyModerators returns (uint256) {
        require(explorePending[_sender] < 0, "Item is already on pending");
        exploreCount += 1;
        ExploreData storage data = exploreData[exploreCount];
        data.sender = _sender;
        data.typeId = _typeId;
        data.monsterId = _monsterId;
        data.siteId = _siteId;
        data.itemSeed = 0;
        data.startAt = _startAt;
        explorePending[_sender] = exploreCount;

        uint256[] memory tokenIds = siteClassToken[_siteId];
        require(tokenIds.length > 0, "This sites not minted");

        LandRevenue storage revenue = siteData[_siteId];
        revenue.emonAmount = revenue.emonAmount.add(_emonAmount);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // 5 / 2 - (5 * 10) / 100
            // TODO: Ask to replace below math with above (revenueamount / tokenIds) - (revenueamount * 19 / 100)

            //Get 1% of emonAmount
            //Subtract 1% from emonAmount
            //divide the sutracted result with tokenIds.length
            //(emonAmount - (emonAmount * percent(here would be 10 to get 1) / 100)) / tokenIds.length
            //Getting 10% to ourselves
            uint256 perecentAmount = (_emonAmount * 10).div(100);
            uint256 subAmount = _emonAmount.sub(perecentAmount);
            uint256 currentRevenue = subAmount.div(tokenIds.length);
            // uint256 currentRevenue = (
            //     revenue.emonAmount.mul(tokenIds.length - 1)
            // ).div(100);
            landToken[tokenIds[i]] += currentRevenue;
        }
        return exploreCount;
    }

    function removePendingExplore(
        uint256 _exploreId,
        uint256 _itemSeed
    ) external onlyModerators {
        ExploreData storage data = exploreData[_exploreId];
        if (explorePending[data.sender] != _exploreId) revert();
        explorePending[data.sender] = 0;
        data.itemSeed = _itemSeed;
    }

    // public function
    function getLandRevenue(
        uint256 _classId
    ) public view returns (uint256 _emonAmount) {
        LandRevenue storage revenue = siteData[_classId];
        return (revenue.emonAmount);
    }

    function getTokenClaim(
        uint256 _tokenId
    ) public view returns (uint256 _emonAmount) {
        LandTokenClaim storage claim = claimData[_tokenId];
        return (claim.emonAmount);
    }

    function getExploreData(
        uint256 _exploreId
    )
        public
        view
        returns (
            address _sender,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        )
    {
        ExploreData storage data = exploreData[_exploreId];
        return (
            data.sender,
            data.typeId,
            data.monsterId,
            data.siteId,
            data.itemSeed,
            data.startAt
        );
    }

    function getPendingExplore(address _player) public view returns (uint256) {
        return explorePending[_player];
    }

    function getPendingExploreData(
        address _player
    )
        public
        view
        returns (
            uint256 _exploreId,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        )
    {
        _exploreId = explorePending[_player];
        if (_exploreId > 0) {
            ExploreData storage data = exploreData[_exploreId];
            return (
                _exploreId,
                data.typeId,
                data.monsterId,
                data.siteId,
                data.itemSeed,
                data.startAt
            );
        }
    }

    function getRevenueInfo(
        uint256 _tokenId
    )
        external
        view
        returns (
            uint256 _currentRevenue,
            uint256 _claimedRevenue,
            uint256 _pendingRevenue
        )
    {
        _currentRevenue = landToken[_tokenId];
        _claimedRevenue = getTokenClaim(_tokenId);
        _pendingRevenue = _currentRevenue.sub(_claimedRevenue);
    }
}