// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid,
        None
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    ///TODO: by default are not internal need to create a custom internal function for this refer :- https://ethereum.stackexchange.com/questions/21155/how-to-expose-enum-in-solidity-contract
    enum EndowmentType {
        Charity,
        Normal,
        None
    }

    enum EndowmentStatus {
        Inactive,
        Approved,
        Frozen,
        Closed
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage curAvailible,
        uint256[] storage cerAvailibleAmount, 
        string memory curToken
    ) public {
        bool check = true;
        for (uint8 j = 0; j < curAvailible.length; j++) {
            if (
                keccak256(abi.encodePacked(curAvailible[j])) ==
                keccak256(abi.encodePacked(curToken))
            ) {
                check = false;
            }
        }
        if (check) {
            curAvailible.push(curToken);
            cerAvailibleAmount.push(0);
        }
    }

    struct RebalanceDetails {
        bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
        bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
        bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    }

    function rebalanceDetailsDefaut()
        public
        pure
        returns (RebalanceDetails memory)
    {
        RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
            rebalanceLiquidInvestedProfits: false,
            lockedInterestsToLiquid: false,
            interest_distribution: 20,
            lockedPrincipleToLiquid: false,
            principle_distribution: 0
        });

        return _tempRebalanceDetails;
    }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct Cw20CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        // Coin[] native;
        uint256[] Cw20CoinVerified_amount;
        address[] Cw20CoinVerified_addr;
        // Cw20CoinVerified[] cw20;
    }

    function addToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            curTemp.Cw20CoinVerified_addr.push(curTokenaddress);
            curTemp.Cw20CoinVerified_amount.push(curAmount);
        }
    }

    function addTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            GenericBalance memory new_temp = GenericBalance({
                coinNativeAmount: curTemp.coinNativeAmount,
                Cw20CoinVerified_amount: new uint256[](
                    curTemp.Cw20CoinVerified_amount.length + 1
                ),
                Cw20CoinVerified_addr: new address[](
                    curTemp.Cw20CoinVerified_addr.length + 1
                )
            });
            for (uint256 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
                new_temp.Cw20CoinVerified_addr[i] = curTemp
                    .Cw20CoinVerified_addr[i];
                new_temp.Cw20CoinVerified_amount[i] = curTemp
                    .Cw20CoinVerified_amount[i];
            }
            new_temp.Cw20CoinVerified_addr[
                curTemp.Cw20CoinVerified_addr.length
            ] = curTokenaddress;
            new_temp.Cw20CoinVerified_amount[
                curTemp.Cw20CoinVerified_amount.length
            ] = curAmount;
            return new_temp;
        } else return curTemp;
    }

    function subToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
    }

    function subTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
        return curTemp;
    }

    function splitBalance(
        uint256[] storage cw20Coin,
        uint256 splitFactor
    ) public view returns (uint256[] memory) {
        uint256[] memory curTemp = new uint256[](cw20Coin.length);
        for (uint8 i = 0; i < cw20Coin.length; i++) {
            uint256 result = SafeMath.div(cw20Coin[i], splitFactor);
            curTemp[i] = result;
        }

        return curTemp;
    }

    function receiveGenericBalance(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] storage curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] memory curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function deductTokens(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curDeducttokenfor,
        uint256 curDeductamount
    ) public pure returns (uint256[] memory) {
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curDeducttokenfor) {
                require(curAmount[i] > curDeductamount, "Insufficient Funds");
                curAmount[i] -= curDeductamount;
            }
        }

        return curAmount;
    }

    function getTokenAmount(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curTokenaddress
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curTokenaddress) {
                amount = curAmount[i];
            }
        }

        return amount;
    }

    struct AllianceMember {
        string name;
        string logo;
        string website;
    }

    function genericBalanceDefault()
        public
        pure
        returns (GenericBalance memory)
    {
        GenericBalance memory empty;
        return empty;
    }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint256 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint256[] members;
        bool rotatingFund; // set a fund as a rotating fund
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint256 id;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory curTemp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({id: 0, addr: address(0)})
        });

        return curTemp;
    }

    struct SocialMedialUrls {
        string facebook;
        string twitter;
        string linkedin;
    }

    struct Profile {
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        SocialMedialUrls socialMediaUrls;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///CHanges made for registrar contract

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a split parameter is not provided
    }

    function checkSplits(
        SplitDetails memory registrarSplits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a non-TCA address meets the default
        // requirements for splits that is set in the Registrar contract
        if (
            userLiquid > registrarSplits.max ||
            userLiquid < registrarSplits.min ||
            userOverride == true
        ) {
            return (
                100 - registrarSplits.defaultSplit,
                registrarSplits.defaultSplit
            );
        } else {
            return (userLocked, userLiquid);
        }
    }

    struct AcceptedTokens {
        address[] cw20;
    }

    function cw20Valid(
        address[] memory cw20,
        address token
    ) public pure returns (bool) {
        bool check = false;
        for (uint8 i = 0; i < cw20.length; i++) {
            if (cw20[i] == token) {
                check = true;
            }
        }

        return check;
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router;
        address axelerGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    struct YieldVault {
        string addr; // vault's contract address on chain where the Registrar lives/??
        uint256 network; // Points to key in NetworkConnections storage map
        address inputDenom; //?
        address yieldToken; //?
        bool approved;
        EndowmentType[] restrictedFrom;
        AccountType acctType;
        VaultType vaultType;
    }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct ThresholdData {
        uint256 weight;
        uint256 percentage;
        uint256 threshold;
        uint256 quorum;
    }
    enum ThresholdEnum {
        AbsoluteCount,
        AbsolutePercentage,
        ThresholdQuorum
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    //TODO: remove if not needed
    // function durationAfter(Duration memory data)
    //     public
    //     view
    //     returns (Expiration memory)
    // {
    //     if (data.enumData == DurationEnum.Height) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atHeight,
    //                 data: ExpirationData({
    //                     height: block.number + data.data.height,
    //                     time: 0
    //                 })
    //             });
    //     } else if (data.enumData == DurationEnum.Time) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atTime,
    //                 data: ExpirationData({
    //                     height: 0,
    //                     time: block.timestamp + data.data.time
    //                 })
    //             });
    //     } else {
    //         revert("Duration not configured");
    //     }
    // }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    struct Threshold {
        ThresholdEnum enumData;
        ThresholdData data;
    }

    enum CurveTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    //TODO: remove if unused
    // function getReserveRatio(CurveTypeEnum curCurveType)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     if (curCurveType == CurveTypeEnum.Linear) {
    //         return 500000;
    //     } else if (curCurveType == CurveTypeEnum.SquarRoot) {
    //         return 660000;
    //     } else {
    //         return 1000000;
    //     }
    // }

    struct CurveTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct CurveType {
        CurveTypeEnum curve_type;
        CurveTypeData data;
    }

    enum TokenType {
        ExistingCw20,
        NewCw20,
        BondingCurve
    }

    struct DaoTokenData {
        address existingCw20Data;
        uint256 newCw20InitialSupply;
        string newCw20Name;
        string newCw20Symbol;
        CurveType bondingCurveCurveType;
        string bondingCurveName;
        string bondingCurveSymbol;
        uint256 bondingCurveDecimals;
        address bondingCurveReserveDenom;
        uint256 bondingCurveReserveDecimals;
        uint256 bondingCurveUnbondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address Addr;
        uint256 expires; // datetime int of delegation expiry
    }

    function canTakeAction(
        Delegate storage self,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        if (
            sender == self.Addr &&
            (self.expires == 0 || envTime <= self.expires)
        ) {
            return true;
        } else {
            return false;
        }
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 feePercentage;
        bool active;
    }

    struct SettingsPermission {
        bool ownerControlled;
        bool govControlled;
        bool modifiableAfterInit;
        Delegate delegate;
    }

    function setDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        address delegateAddr,
        uint256 delegateExpiry
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov)
        ) {
            self.delegate = Delegate({
                Addr: delegateAddr,
                expires: delegateExpiry
            });
        }
    }

    function revokeDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            self.delegate = Delegate({Addr: address(0), expires: 0});
        }
    }

    function canChange(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public view returns (bool) {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            return self.modifiableAfterInit;
        }
        return false;
    }

    struct SettingsController {
        SettingsPermission endowmentController;
        SettingsPermission strategies;
        SettingsPermission whitelistedBeneficiaries;
        SettingsPermission whitelistedContributors;
        SettingsPermission maturityWhitelist;
        SettingsPermission maturityTime;
        SettingsPermission profile;
        SettingsPermission earningsFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission aumFee;
        SettingsPermission kycDonorsOnly;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    function getPermissions(
        SettingsController storage _tempObject,
        string memory name
    ) public view returns (SettingsPermission storage) {
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("endowmentController"))
        ) {
            return _tempObject.endowmentController;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityWhitelist"))
        ) {
            return _tempObject.maturityWhitelist;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("splitToLiquid"))
        ) {
            return _tempObject.splitToLiquid;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("ignoreUserSplits"))
        ) {
            return _tempObject.ignoreUserSplits;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("strategies"))
        ) {
            return _tempObject.strategies;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedBeneficiaries"))
        ) {
            return _tempObject.whitelistedBeneficiaries;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedContributors"))
        ) {
            return _tempObject.whitelistedContributors;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityTime"))
        ) {
            return _tempObject.maturityTime;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("profile"))
        ) {
            return _tempObject.profile;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("earningsFee"))
        ) {
            return _tempObject.earningsFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("withdrawFee"))
        ) {
            return _tempObject.withdrawFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("depositFee"))
        ) {
            return _tempObject.depositFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("aumFee"))
        ) {
            return _tempObject.aumFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("kycDonorsOnly"))
        ) {
            return _tempObject.kycDonorsOnly;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("name"))
        ) {
            return _tempObject.name;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("image"))
        ) {
            return _tempObject.image;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("logo"))
        ) {
            return _tempObject.logo;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("categories"))
        ) {
            return _tempObject.categories;
        } else {
            revert("InvalidInputs");
        }
    }

    // None at the start as pending starts at 1 in ap rust contracts (in cw3 core)
    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../../core/struct.sol";

import {subDaoStorage} from "./storage.sol";

library subDaoMessage {
    struct InstantiateMsg {
        uint256 id;
        address owner;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
        AngelCoreStruct.DaoToken token;
        AngelCoreStruct.EndowmentType endow_type;
        address endowOwner;
        address registrarContract;
    }

    struct QueryConfigResponse {
        address owner;
        address daoToken;
        address veToken;
        address swapFactory;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library subDaoStorage {
    struct Config {
        address registrarContract;
        address owner;
        address daoToken;
        address veToken;
        address swapFactory;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
    }

    struct State {
        uint256 pollCount;
        uint256 totalShare;
        uint256 totalDeposit;
    }

    enum VoteOption {
        Yes,
        No
    }

    struct VoterInfo {
        VoteOption vote;
        uint256 balance;
        bool voted;
    }

    // struct TokenManager {
    //     uint256 share;                        // total staked balance
    //     VoterInfo lockedBalance; // maps pollId to weight voted
    // }

    struct ExecuteData {
        uint256[] order;
        address[] contractAddress;
        bytes[] execution_message;
    }

    enum PollStatus {
        InProgress,
        Passed,
        Rejected,
        Executed,
        Expired
    }

    struct Poll {
        uint256 id;
        address creator;
        PollStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 startBlock;
        uint256 startTime;
        uint256 endHeight;
        string title;
        string description;
        string link;
        ExecuteData executeData;
        uint256 depositAmount;
        /// Total balance at the end poll
        uint256 totalBalanceAtEndPoll;
        uint256 stakedAmount;
    }
}

contract Storage {
    subDaoStorage.Config config;
    subDaoStorage.State state;

    mapping(uint256 => subDaoStorage.Poll) poll;
    mapping(uint256 => subDaoStorage.PollStatus) poll_status;

    mapping(uint256 => mapping(address => subDaoStorage.VoterInfo)) voting_status;

    uint256 constant MIN_TITLE_LENGTH = 4;
    uint256 constant MAX_TITLE_LENGTH = 64;
    uint256 constant MIN_DESC_LENGTH = 4;
    uint256 constant MAX_DESC_LENGTH = 1024;
    uint256 constant MIN_LINK_LENGTH = 12;
    uint256 constant MAX_LINK_LENGTH = 128;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {subDaoMessage} from "./message.sol";
import {subDaoStorage} from "./storage.sol";

contract SubdaoEmitter {
    bool initialized = false;
    address accountsContract;

    function initEmitter(address curAccountscontract) public {
        require(
            curAccountscontract != address(0),
            "Invalid accounts contract address"
        );
        require(!initialized, "Already Initialized");
        initialized = true;
        accountsContract = curAccountscontract;
    }

    mapping(address => bool) isSubdao;
    modifier isOwner() {
        require(msg.sender == accountsContract, "Unauthorized");
        _;
    }
    modifier isEmitter() {
        require(isSubdao[msg.sender], "Unauthorized");
        _;
    }
    event SubdaoInitialized(
        address subdao,
        subDaoMessage.InstantiateMsg instantiateMsg
    );
    event SubdaoUpdateConfig(address subdao, subDaoStorage.Config config);
    event SubdaoTransferFrom(
        address subdao,
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    );
    event SubdaoUpdateState(address subdao, subDaoStorage.State state);
    event SubdaoUpdatePoll(address subdao, uint256 id, subDaoStorage.Poll poll);
    event SubdaoUpdatePollStatus(
        address subdao,
        uint256 id,
        subDaoStorage.PollStatus pollStatus
    );
    event SubdaoTransfer(
        address subdao,
        address tokenAddress,
        address recipient,
        uint amount
    );
    event SubdapUpdateVotingStatus(
        address subdao,
        uint256 pollId,
        address voter,
        subDaoStorage.VoterInfo voterInfo
    );

    function initializeSubdao(
        address subdao,
        subDaoMessage.InstantiateMsg memory instantiateMsg
    ) public isOwner {
        isSubdao[subdao] = true;
        emit SubdaoInitialized(msg.sender, instantiateMsg);
    }

    function updateSubdaoConfig(
        subDaoStorage.Config memory config
    ) public isEmitter {
        emit SubdaoUpdateConfig(msg.sender, config);
    }

    function transferFromSubdao(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) public isEmitter {
        emit SubdaoTransferFrom(msg.sender, tokenAddress, from, to, amount);
    }

    function updateSubdaoState(
        subDaoStorage.State memory state
    ) public isEmitter {
        emit SubdaoUpdateState(msg.sender, state);
    }

    function updateSubdaoPoll(
        uint256 id,
        subDaoStorage.Poll memory poll
    ) public isEmitter {
        emit SubdaoUpdatePoll(msg.sender, id, poll);
    }

    function transferSubdao(
        address tokenAddress,
        address recipient,
        uint amount
    ) public isEmitter {
        emit SubdaoTransfer(msg.sender, tokenAddress, recipient, amount);
    }

    function updateVotingStatus(
        uint256 pollId,
        address voter,
        subDaoStorage.VoterInfo memory voterInfo
    ) public isEmitter {
        emit SubdapUpdateVotingStatus(msg.sender, pollId, voter, voterInfo);
    }

    function updateSubdaoPollAndStatus(
        uint256 id,
        subDaoStorage.Poll memory poll,
        subDaoStorage.PollStatus pollStatus
    ) public isEmitter {
        emit SubdaoUpdatePoll(msg.sender, id, poll);
        emit SubdaoUpdatePollStatus(msg.sender, id, pollStatus);
    }
}