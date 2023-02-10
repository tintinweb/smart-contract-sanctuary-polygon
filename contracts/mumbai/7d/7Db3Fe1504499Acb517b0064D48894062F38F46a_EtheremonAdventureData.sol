/**
 *Submitted for verification at polygonscan.com on 2023-02-10
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

    struct LandTokenClaim {
        uint256 emonAmount;
        uint256 etherAmount;
    }

    // total revenue
    struct LandRevenue {
        uint256 emonAmount;
        uint256 etherAmount;
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
    mapping(uint256 => LandRevenue) public siteData; // class id => amount

    function addLandRevenue(
        uint256 _siteId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external onlyModerators {
        LandRevenue storage revenue = siteData[_siteId];
        revenue.emonAmount = revenue.emonAmount.add(_emonAmount);
        revenue.etherAmount = revenue.etherAmount.add(_etherAmount);
    }

    function addTokenClaim(
        uint256 _tokenId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external onlyModerators {
        LandTokenClaim storage claim = claimData[_tokenId];
        claim.emonAmount = claim.emonAmount.add(_emonAmount);
        claim.etherAmount = claim.etherAmount.add(_etherAmount);
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
        if (explorePending[_sender] > 0) revert();
        exploreCount += 1;
        ExploreData storage data = exploreData[exploreCount];
        data.sender = _sender;
        data.typeId = _typeId;
        data.monsterId = _monsterId;
        data.siteId = _siteId;
        data.itemSeed = 0;
        data.startAt = _startAt;
        explorePending[_sender] = exploreCount;

        LandRevenue storage revenue = siteData[_siteId];
        revenue.emonAmount = revenue.emonAmount.add(_emonAmount);
        revenue.etherAmount = revenue.etherAmount.add(_etherAmount);
        return exploreCount;
    }

    function removePendingExplore(uint256 _exploreId, uint256 _itemSeed)
        external
        onlyModerators
    {
        ExploreData storage data = exploreData[_exploreId];
        if (explorePending[data.sender] != _exploreId) revert();
        explorePending[data.sender] = 0;
        data.itemSeed = _itemSeed;
    }

    // public function
    function getLandRevenue(uint256 _classId)
        public
        view
        returns (uint256 _emonAmount, uint256 _etherAmount)
    {
        LandRevenue storage revenue = siteData[_classId];
        return (revenue.emonAmount, revenue.etherAmount);
    }

    function getTokenClaim(uint256 _tokenId)
        public
        view
        returns (uint256 _emonAmount, uint256 _etherAmount)
    {
        LandTokenClaim storage claim = claimData[_tokenId];
        return (claim.emonAmount, claim.etherAmount);
    }

    function getExploreData(uint256 _exploreId)
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

    function getPendingExploreData(address _player)
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
}