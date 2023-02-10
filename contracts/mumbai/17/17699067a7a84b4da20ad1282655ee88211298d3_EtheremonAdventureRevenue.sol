/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// File: contracts/EthermonAdventureRevenue.sol

/**
 *Submitted for verification at Etherscan.io on 2018-09-04
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

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        virtual
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        public
        virtual
        returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);
}

interface EtheremonAdventureItem {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getItemInfo(uint256 _tokenId)
        external
        view
        returns (uint256 classId, uint256 value);

    function spawnItem(
        uint256 _classId,
        uint256 _value,
        address _owner
    ) external returns (uint256);
}

abstract contract EtheremonAdventureData {
    function addLandRevenue(
        uint256 _siteId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    function addTokenClaim(
        uint256 _tokenId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    // public function
    function getLandRevenue(uint256 _classId)
        public
        view
        virtual
        returns (uint256 _emonAmount, uint256 _etherAmount);

    function getTokenClaim(uint256 _tokenId)
        public
        view
        virtual
        returns (uint256 _emonAmount, uint256 _etherAmount);
}

contract EtheremonAdventureRevenue is BasicAccessControl {
    using SafeMath for uint256;

    uint256 revenuDivider;
    struct PairData {
        uint256 d1;
        uint256 d2;
    }

    // TODO: Have to make variable of pecentage to be updateable from mod

    address public tokenContract;
    address public adventureDataContract;
    address public adventureItemContract;

    modifier requireTokenContract() {
        require(tokenContract != address(0));
        _;
    }

    modifier requireAdventureDataContract() {
        require(adventureDataContract != address(0));
        _;
    }

    modifier requireAdventureItemContract() {
        require(adventureItemContract != address(0));
        _;
    }

    function setConfig(
        address _tokenContract,
        address _adventureDataContract,
        address _adventureItemContract
    ) public onlyModerators {
        tokenContract = _tokenContract;
        adventureDataContract = _adventureDataContract;
        adventureItemContract = _adventureItemContract;
    }

    function withdrawEther(address _sendTo, uint256 _amount) public onlyOwner {
        // it is used in case we need to upgrade the smartcontract
        if (_amount > address(this).balance) {
            revert();
        }
        payable(_sendTo).transfer(_amount);
    }

    function withdrawToken(address _sendTo, uint256 _amount)
        external
        onlyOwner
        requireTokenContract
    {
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }

    function setRevenuDivider(uint256 _revenuDivider) external onlyModerators {
        require(_revenuDivider > 0, "Invalid divider value");
        revenuDivider = _revenuDivider;
    }

    // public

    // function () payable public {
    // }

    function getEarning(uint256 _tokenId)
        public
        view
        returns (uint256 _emonAmount, uint256 _ethAmount)
    {
        PairData memory tokenInfo;

        PairData memory currentRevenue;
        PairData memory claimedRevenue;

        (tokenInfo.d1, tokenInfo.d2) = EtheremonAdventureItem(
            adventureItemContract
        ).getItemInfo(_tokenId);
        EtheremonAdventureData data = EtheremonAdventureData(
            adventureDataContract
        );
        (currentRevenue.d1, currentRevenue.d2) = data.getLandRevenue(
            tokenInfo.d1
        );
        (claimedRevenue.d1, claimedRevenue.d2) = data.getTokenClaim(_tokenId);

        _emonAmount = ((currentRevenue.d1.mul(9)).div(100)).sub(
            claimedRevenue.d1
        );
        _ethAmount = ((currentRevenue.d2.mul(9)).div(100)).sub(
            claimedRevenue.d2
        );
    }

    function claimEarning(uint256 _tokenId)
        public
        isActive
        requireTokenContract
        requireAdventureDataContract
        requireAdventureItemContract
    {
        EtheremonAdventureItem item = EtheremonAdventureItem(
            adventureItemContract
        );
        EtheremonAdventureData data = EtheremonAdventureData(
            adventureDataContract
        );
        if (item.ownerOf(_tokenId) != msg.sender) revert();
        PairData memory tokenInfo;
        PairData memory currentRevenue;
        PairData memory claimedRevenue;
        PairData memory pendingRevenue;
        (tokenInfo.d1, tokenInfo.d2) = item.getItemInfo(_tokenId);
        (currentRevenue.d1, currentRevenue.d2) = data.getLandRevenue(
            tokenInfo.d1
        );
        (claimedRevenue.d1, claimedRevenue.d2) = data.getTokenClaim(_tokenId);

        pendingRevenue.d1 = ((currentRevenue.d1.mul(9)).div(100)).sub(
            claimedRevenue.d1
        );
        pendingRevenue.d2 = ((currentRevenue.d2.mul(9)).div(100)).sub(
            claimedRevenue.d2
        );

        if (pendingRevenue.d1 == 0 && pendingRevenue.d2 == 0) revert();
        data.addTokenClaim(_tokenId, pendingRevenue.d1, pendingRevenue.d2);

        if (pendingRevenue.d1 > 0) {
            ERC20Interface(tokenContract).transfer(
                msg.sender,
                pendingRevenue.d1
            );
        }

        if (pendingRevenue.d2 > 0) {
            msg.sender.transfer(pendingRevenue.d2);
        }
    }
}