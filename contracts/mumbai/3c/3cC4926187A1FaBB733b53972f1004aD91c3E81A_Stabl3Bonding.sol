// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";
import "./IROI.sol";

contract Stabl3Bonding is Ownable, ReentrancyGuard {
    using SafeMathUpgradeable for uint256;

    uint8 private constant BOND_POOL = 1;

    ITreasury public treasury;
    IROI public ROI;
    address public HQ;

    IERC20 public immutable STABL3;

    uint256 public treasuryPercentage;
    uint256 public ROIPercentage;
    uint256 public HQPercentage;

    uint256 public bondingClaimTime;

    uint256 public totalBondIndexes;

    bool public bondState;

    // structs

    struct BondInfo {
        uint256 bondIndex;
        uint256 bondAmount;
        uint256 bondAmountConsumed;
        uint256 discount;
        uint256 startTime;
        uint256 expiryTime;
    }

    struct Bonding {
        uint256 index;
        address user;
        uint256 bondIndex;
        bool status;
        uint256 amountStabl3;
        IERC20 token;
        uint256 amountToken;
        uint256 startTime;
        uint256 endTime;
    }

    struct Record {
        uint256 totalAmountToken;
        uint256 totalAmountStabl3;
    }

    // mappings

    // current bond set by the admin/owner
    BondInfo public getBondInfo;

    // user bondings
    mapping (address => Bonding[]) public getBondings;

    // user lifetime bonding records
    mapping (address => Record) public getRecords;

    // admins are accounts that have permission to access certain bonding functions
    // mapping (address => bool) public admin;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedBondingClaimTime(uint256 newBondingClaimTime, uint256 oldBondingClaimTime);

    // event UpdatedAdmin(address account, bool state);

    event CreatedBond(
        uint256 bondIndex,
        uint256 bondAmount,
        uint256 discount,
        uint256 startTime,
        uint256 expiryTime
    );

    event Bond(
        address indexed user,
        uint256 index,
        uint256 bondIndex,
        uint256 amountStabl3,
        IERC20 token,
        uint256 amountToken,
        uint256 totalAmountToken,
        uint256 timestamp
    );

    event ClaimedBond(
        address indexed user,
        uint256 index,
        uint256 bondIndex,
        uint256 amountStabl3,
        IERC20 token,
        uint256 amountToken,
        uint256 totalAmountStabl3,
        uint256 timestamp
    );

    // constructor

    constructor(address _treasury, address _ROI) {
        treasury = ITreasury(_treasury);
        ROI = IROI(_ROI);
        // TODO change
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        // TODO change
        STABL3 = IERC20(0xc3Bf0c0172E3638d383361801e9BF63B4FfE0d6e);

        treasuryPercentage = 800;
        ROIPercentage = 161;
        HQPercentage = 39;

        // TODO remove
        bondingClaimTime = 300; // 0:15 hours time in seconds
        // bondingClaimTime = 2592000; // 1 month time in seconds
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "Stabl3Bonding: Treasury is already this address");
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Bonding: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3Bonding: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateDistributionPercentages(
        uint256 _treasuryPercentage,
        uint256 _ROIPercentage,
        uint256 _HQPercentage
    ) external onlyOwner {
        require(_treasuryPercentage + _ROIPercentage + _HQPercentage == 1000,
            "Stabl3Bonding: Sum of magnified percentages should equal 1000");

        treasuryPercentage = _treasuryPercentage;
        ROIPercentage = _ROIPercentage;
        HQPercentage = _HQPercentage;
    }

    function updateBondingClaimTime(uint256 _bondingClaimTime) external onlyOwner {
        require(bondingClaimTime != _bondingClaimTime, "Stabl3Bonding: Bonding Claim Time is already this value");
        emit UpdatedBondingClaimTime(_bondingClaimTime, bondingClaimTime);
        bondingClaimTime = _bondingClaimTime;
    }

    function updateBondState(bool _state) external onlyOwner {
        require(bondState != _state, "Stabl3Bonding: Bond State is already this state");
        bondState = _state;
    }

    // function updateAdmin(address _account, bool _state) external onlyOwner {
    //     require(admin[_account] != _state, "Stabl3Bonding: Account is already this state");
    //     admin[_account] = _state;
    //     emit UpdatedAdmin(_account, _state);
    // }

    /**
     * @dev Once made the bond cannot be changed
     * @dev A new bond can only be started once the current one's time expires or the bond amount is fully consumed
     * @param _bondAmount in 18 decimals
     * @param _discount all percentages are magnified by 10
     * @param _duration in seconds
     */
    function createBond(
        uint256 _bondAmount,
        uint256 _discount,
        uint256 _duration
    ) external bondActive onlyOwner {
        require(_bondAmount > 0, "Stabl3Bonding: Insufficient amount");

        uint256 timestampToConsider = block.timestamp;

        require(timestampToConsider >= getBondInfo.expiryTime, "Stabl3Bonding: Previous bond is still active");

        BondInfo memory bondInfo;
        bondInfo.bondIndex = totalBondIndexes;
        bondInfo.bondAmount = _bondAmount;
        // bondInfo.bondAmountConsumed = 0;
        bondInfo.discount = _discount;
        bondInfo.startTime = timestampToConsider;
        bondInfo.expiryTime = timestampToConsider + _duration;

        getBondInfo = bondInfo;

        totalBondIndexes++;

        emit CreatedBond(bondInfo.bondIndex, bondInfo.bondAmount, bondInfo.discount, bondInfo.startTime, bondInfo.expiryTime);
    }

    function bond(IERC20 _token, uint256 _amountToken) external bondActive reserved(_token) nonReentrant {
        require(_amountToken > 0, "Stabl3Bonding: Insufficient amount");

        BondInfo storage bondInfo = getBondInfo;

        uint256 timestampToConsider = block.timestamp;

        uint256 amountTokenConverted = _token.decimals() < 18 ? _amountToken * (10 ** (18 - _token.decimals())) : _amountToken;

        require(timestampToConsider < bondInfo.expiryTime, "Stabl3Bonding: Bond has expired");
        require(bondInfo.bondAmountConsumed + amountTokenConverted <= bondInfo.bondAmount, "Stabl3Bonding: Bond limit reached");

        {
            uint256 amountTreasury = _amountToken.mul(treasuryPercentage).div(1000);

            uint256 amountROI = _amountToken.mul(ROIPercentage).div(1000);

            uint256 amountHQ = _amountToken.mul(HQPercentage).div(1000);

            uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ;
            if (_amountToken > totalAmountDistributed) {
                amountTreasury += _amountToken - totalAmountDistributed;
            }

            SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
            SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

            treasury.updatePool(BOND_POOL, _token, amountTreasury, amountROI, amountHQ, true);
        }

        uint256 amountStabl3 = treasury.getAmountOut(_token, _amountToken);

        amountStabl3 = amountStabl3.mul(1000).div(1000 - bondInfo.discount);

        Bonding memory bonding;
        bonding.index = getBondings[msg.sender].length;
        bonding.user = msg.sender;
        bonding.bondIndex = bondInfo.bondIndex;
        bonding.status = true;
        bonding.token = _token;
        bonding.amountToken = _amountToken;
        bonding.amountStabl3 = amountStabl3;
        bonding.startTime = timestampToConsider;
        bonding.endTime = timestampToConsider + bondingClaimTime;

        getBondings[msg.sender].push(bonding);

        bondInfo.bondAmountConsumed += amountTokenConverted;

        Record storage record = getRecords[msg.sender];

        record.totalAmountToken += amountTokenConverted;

        treasury.updateRate(_token, _amountToken);

        ROI.updateAPR();

        emit Bond(
            bonding.user,
            bonding.index,
            bonding.bondIndex,
            bonding.amountStabl3,
            bonding.token,
            bonding.amountToken,
            record.totalAmountToken,
            timestampToConsider
        );
    }

    function getClaimableBondSingle(address _user, uint256 _index, uint256 _timestamp) public view returns (uint256) {
        uint256 claimableBond;

        Bonding memory bonding = getBondings[_user][_index];

        if (
            bonding.status &&
            _timestamp >= bonding.endTime
        ) {
            claimableBond = bonding.amountStabl3;
        }
        
        return claimableBond;
    }

    function getClaimableBondAll(address _user) external view returns (uint256) {
        uint256 totalClaimableBond;

        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getBondings[_user].length ; i++) {
            uint256 claimableBond = getClaimableBondSingle(_user, i, timestampToConsider);

            if (claimableBond > 0) {
                totalClaimableBond += claimableBond;
            }
        }

        return totalClaimableBond;
    }

    function claimBondSingle(uint256 _index) public bondActive nonReentrant {
        Bonding storage bonding = getBondings[msg.sender][_index];

        uint256 timestampToConsider = block.timestamp;

        require(bonding.status, "Stabl3Bonding: Invalid Bonding");
        require(timestampToConsider >= bonding.endTime, "Stabl3Bonding: Bonding not yet claimable");

        STABL3.transferFrom(address(treasury), msg.sender, bonding.amountStabl3);

        bonding.status = false;

        Record storage record = getRecords[msg.sender];

        record.totalAmountStabl3 += bonding.amountStabl3;

        treasury.updateStabl3CirculatingSupply(bonding.amountStabl3, true);

        emit ClaimedBond(
            bonding.user,
            bonding.index,
            bonding.bondIndex,
            bonding.amountStabl3,
            bonding.token,
            bonding.amountToken,
            record.totalAmountStabl3,
            timestampToConsider
        );
    }

    function claimBondMultiple(uint256[] calldata _indexes) external bondActive {
        for (uint256 i = 0 ; i < _indexes.length ; i++) {
            claimBondSingle(_indexes[i]);
        }
    }

    // modifiers

    modifier bondActive() {
        require(bondState, "Stabl3Bonding: Bond not yet started");
        _;
    }

    // modifier onlyAdmin() {
    //     require(admin[msg.sender] || msg.sender == owner(), "Stabl3Bonding: Caller is not an admin");
    //     _;
    // }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "Stabl3Bonding: Not a reserved token");
        _;
    }
}