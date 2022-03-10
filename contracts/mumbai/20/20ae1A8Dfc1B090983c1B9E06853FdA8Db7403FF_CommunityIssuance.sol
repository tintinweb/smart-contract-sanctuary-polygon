// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./IOrumToken.sol";
import "./ICommunityIssuance.sol";
import "./OrumMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./SafeMath.sol";


contract CommunityIssuance is ICommunityIssuance, Ownable, CheckContract {
    using SafeMath for uint;

    // --- Data ---

    string constant public NAME = "CommunityIssuance";

    uint constant public SECONDS_IN_ONE_MINUTE = 60;
    uint constant public DECIMAL_PRECISION = 1e18;

   /* The issuance factor F determines the curvature of the issuance curve.
    *
    * Minutes in one year: 60*24*365 = 525600
    *
    * For 50% of remaining tokens issued each year, with minutes as time units, we have:
    * 
    * F ** 525600 = 0.5
    * 
    * Re-arranging:
    * 
    * 525600 * ln(F) = ln(0.5)
    * F = 0.5 ** (1/525600)
    * F = 0.999998681227695000 
    */
    uint constant public ISSUANCE_FACTOR = 999998681227695000;

    /* 
    * The community Orum supply cap is the starting balance of the Community Issuance contract.
    * It should be minted to this contract by OrumToken, when the token is deployed.
    * 
    * Set to 32M (slightly less than 1/3) of total Orum supply.
    */
    uint constant public OrumSupplyCap = 40e24; // 32 million

    IOrumToken public orumToken;

    address public stabilityPoolAddress;

    uint public totalOrumIssued;
    uint public immutable deploymentTime;
    // --- Functions ---

    constructor() {
        deploymentTime = block.timestamp;
    }

    function setAddresses
    (
        address _orumTokenAddress, 
        address _stabilityPoolAddress
    ) 
        external 
        onlyOwner 
        override 
    {
        checkContract(_orumTokenAddress);
        checkContract(_stabilityPoolAddress);

        orumToken = IOrumToken(_orumTokenAddress);
        stabilityPoolAddress = _stabilityPoolAddress;

        // When OrumToken deployed, it should have transferred CommunityIssuance's Orum entitlement
        uint OrumBalance = orumToken.balanceOf(address(this));
        assert(OrumBalance >= OrumSupplyCap);

        emit OrumTokenAddressSet(_orumTokenAddress);
        emit StabilityPoolAddressSet(_stabilityPoolAddress);

    }

    function issueOrum() external override returns (uint) {
        _requireCallerIsStabilityPool();

        uint latestTotalOrumIssued = OrumSupplyCap.mul(_getCumulativeIssuanceFraction()).div(DECIMAL_PRECISION);
        uint issuance = latestTotalOrumIssued.sub(totalOrumIssued);

        totalOrumIssued = latestTotalOrumIssued;
        emit TotalOrumIssuedUpdated(latestTotalOrumIssued);
        
        return issuance;
    }

    /* Gets 1-f^t    where: f < 1

    f: issuance factor that determines the shape of the curve
    t:  time passed since last Orum issuance event  */
    function _getCumulativeIssuanceFraction() internal view returns (uint) {
        // Get the time passed since deployment
        uint timePassedInMinutes = block.timestamp.sub(deploymentTime).div(SECONDS_IN_ONE_MINUTE);

        // f^t
        uint power = OrumMath._decPow(ISSUANCE_FACTOR, timePassedInMinutes);

        //  (1 - f^t)
        uint cumulativeIssuanceFraction = (uint(DECIMAL_PRECISION).sub(power));
        assert(cumulativeIssuanceFraction <= DECIMAL_PRECISION); // must be in range [0,1]

        return cumulativeIssuanceFraction;
    }

    function sendOrum(address _account, uint _orumAmount) external override {
        _requireCallerIsStabilityPool();

        orumToken.transfer(_account, _orumAmount);
    }

    // --- 'require' functions ---

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "CommunityIssuance: caller is not SP");
    }
}