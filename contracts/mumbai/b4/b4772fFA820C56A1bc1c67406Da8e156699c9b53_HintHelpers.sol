// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IVaultManager.sol";
import "./ISortedVaults.sol";
import "./OrumBase.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./SafeMath.sol";

contract HintHelpers is OrumBase, Ownable, CheckContract {
    string constant public NAME = "HintHelpers";
    // using SafeMath for uint256;

    ISortedVaults public sortedVaults;
    IVaultManager public vaultManager;

    // --- Events ---

    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event TEST_here(uint _here);

    // --- Dependency setters ---

    function setAddresses(
        address _sortedVaultsAddress,
        address _vaultManagerAddress
    )
        external
        onlyOwner
    {
        checkContract(_sortedVaultsAddress);
        checkContract(_vaultManagerAddress);

        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);

        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);

    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_OSDamount` to figure out where the redemption sequence will start and what state the final Vault
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Vault with ICR >= MCR (i.e. the first Vault that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Vault of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedOSDamount` is the maximum amount that can be redeemed out of the the provided `_OSDamount`. This can be lower than
     *    `_OSDamount` when redeeming the full amount would leave the last Vault of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Vaults to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint _OSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedOSDamount
        )
    {
        ISortedVaults sortedVaultsCached = sortedVaults;
        uint remainingOSD = _OSDamount;
        address currentVaultuser = sortedVaultsCached.getLast();
        while (currentVaultuser != address(0) && vaultManager.getCurrentICR(currentVaultuser, _price) < MCR) {
            currentVaultuser = sortedVaultsCached.getPrev(currentVaultuser);
        }

        firstRedemptionHint = currentVaultuser;

        if (_maxIterations == 0) {
            _maxIterations = 2**256 - 1;
        }
        while (currentVaultuser != address(0) && remainingOSD > 0 && _maxIterations-- > 0) {
            uint netOSDDebt = _getNetDebt(vaultManager.getVaultDebt(currentVaultuser))
                 + vaultManager.getPendingOSDDebtReward(currentVaultuser);

            if (netOSDDebt > remainingOSD) {
                if (netOSDDebt > MIN_NET_DEBT) {
                    uint maxRedeemableOSD = OrumMath._min(remainingOSD, netOSDDebt - MIN_NET_DEBT);

                    uint ROSE = vaultManager.getVaultColl(currentVaultuser)
                        + (vaultManager.getPendingROSEReward(currentVaultuser));

                    uint newColl = ROSE - ((maxRedeemableOSD * DECIMAL_PRECISION)/ _price);
                    uint newDebt = netOSDDebt - maxRedeemableOSD;

                    uint compositeDebt = _getCompositeDebt(newDebt);
                    partialRedemptionHintNICR = OrumMath._computeNominalCR(newColl, compositeDebt);

                    remainingOSD = remainingOSD - maxRedeemableOSD;
                }
                break;
            } else {

                remainingOSD = remainingOSD - netOSDDebt;
            }

            currentVaultuser = sortedVaultsCached.getPrev(currentVaultuser);
        }
        truncatedOSDamount = _OSDamount - remainingOSD;
    }

    /* getApproxHint() - return address of a Vault that is, on average, (length / numTrials) positions away in the 
    sortedVaults list from the correct insert position of the Vault to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:
    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed)
    {
        uint arrayLength = vaultManager.getVaultOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedVaults.getLast();
        diff = OrumMath._getAbsoluteDifference(_CR, vaultManager.getNominalICR(hintAddress));
        latestRandomSeed = _inputRandomSeed;

        uint i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint(keccak256(abi.encodePacked(latestRandomSeed)));

            uint arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = vaultManager.getVaultFromVaultOwnersArray(arrayIndex);
            uint currentNICR = vaultManager.getNominalICR(currentAddress);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint currentDiff = OrumMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }
    }

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint) {
        return OrumMath._computeNominalCR(_coll, _debt);
    }

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint) {
        return OrumMath._computeCR(_coll, _debt, _price);
    }
}