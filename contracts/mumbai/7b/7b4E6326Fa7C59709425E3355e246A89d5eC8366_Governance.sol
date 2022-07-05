// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./Reporter.sol";
import "../../interfaces/IGovernance.sol";

/**
 * @title Governance Contract
 *
 * @dev The governance contract permits any NPM tokenholder to submit a report
 * by staking a minimum number of NPM tokens as set in the cover pool.
 *
 * <br /> <br />
 *
 * The reporting procedure begins when an incident report is received and often takes seven days or longer,
 * depending on the configuration of a cover. It also allows subsequent reporters to submit their stakes
 * in support of the initial report or to add stakes to dispute it.
 *
 * <br /> <br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
contract Governance is IGovernance, Reporter {
  using GovernanceUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using ValidationLibV1 for bytes32;

  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_GOVERNANCE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IReporter.sol";
import "./Witness.sol";

/**
 * @title Reporter Contract
 *
 * @dev This contract allows any NPM tokenholder to report a new incident
 * or dispute a previously recorded incident.
 *
 * <br /> <br />
 *
 * When a cover pool is reporting, additional tokenholders may join in to reach a resolution.
 * The `First Reporter` is the user who initially submits an incident,
 * while `Candidate Reporter` is the user who challenges the submitted report.
 *
 * <br /> <br />
 *
 * Valid reporter is one of the aforementioned who receives a favourable decision
 * when resolution is achieved.
 *
 * <br /> <br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
abstract contract Reporter is IReporter, Witness {
  using GovernanceUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Stake NPM tokens to file an incident report.
   * Check the `[getFirstReportingStake(coverKey) method](#getfirstreportingstake)` to get
   * the minimum amount required to report this cover.
   *
   * <br /> <br />
   *
   * For more info, check out the [documentation](https://docs.neptunemutual.com/covers/cover-reporting)
   *
   * <br /> <br />
   *
   * **Rewards:**
   *
   * <br />
   *
   * If you obtain a favourable resolution, you will enjoy the following benefits:
   *
   * - A proportional commission in NPM tokens on all rewards earned by qualified camp voters (see [Unstakable.unstakeWithClaim](Unstakable.md#unstakewithclaim)).
   * - A proportional commission on the protocol earnings of all stablecoin claim payouts.
   * - Your share of the 60 percent pool of invalid camp participants.
   *
   *
   * @custom:note Please note the differences between the following:
   *
   * **Observed Date**
   *
   * The date an time when incident occurred in the real world.
   *
   * **Incident Date**
   *
   * Instead of observed date or the real date and time of the trigger incident,
   * the timestamp when this report is submitted is "the incident date".
   *
   * Payouts to policyholders is given only if the reported incident date
   * falls within the coverage period.
   *
   *
   * @custom:warning **Warning:**
   *
   * Please carefully check the cover rules, cover exclusions, and standard exclusion
   * in detail before you submit this report. You entire stake will be forfeited
   * if resolution does not go in your favor. You will be able to unstake
   * and receive back your NPM only if:
   *
   * - incident resolution is in your favor
   * - after reporting period ends
   *
   * **By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.**
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param coverKey Enter the cover key you are reporting
   * @param productKey Enter the product key you are reporting
   * @param info Enter IPFS hash of the incident in the following format:
   * <br />
   * <pre>{
   * <br />  incidentTitle: 'Animated Brands Exploit, August 2024',
   * <br />  observed: 1723484937,
   * <br />  proofOfIncident: 'https://twitter.com/AnimatedBrand/status/5739383124571205635',
   * <br />  description: 'In a recent exploit, attackers were able to drain 50M USDC from Animated Brands lending vaults',
   * <br />}
   * </pre>
   * @param stake Enter the amount you would like to stake to submit this report
   *
   */
  function report(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    s.mustHaveNormalProductStatus(coverKey, productKey);

    uint256 incidentDate = block.timestamp; // solhint-disable-line
    require(stake > 0, "Stake insufficient");
    require(stake >= s.getMinReportingStakeInternal(coverKey), "Stake insufficient");

    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey, incidentDate);

    // Set the Resolution Timestamp
    uint256 resolutionDate = block.timestamp + s.getReportingPeriodInternal(coverKey); // solhint-disable-line
    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, coverKey, productKey, resolutionDate);

    // Update the values
    s.addAttestationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    // Transfer the stake to the resolution contract
    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Reported(coverKey, productKey, msg.sender, incidentDate, info, stake, resolutionDate);
    emit Attested(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev If you believe that a reported incident is wrong, you can stake NPM tokens to dispute an incident report.
   * Check the `[getFirstReportingStake(coverKey) method](#getfirstreportingstake)` to get
   * the minimum amount required to report this cover.
   *
   * <br /> <br />
   *
   * **Rewards:**
   *
   * If you get resolution in your favor, you will receive these rewards:
   *
   * - A 10% commission on all reward received by valid camp voters (check `Unstakeable.unstakeWithClaim`) in NPM tokens.
   * - Your proportional share of the 60% pool of the invalid camp.
   *
   * @custom:warning **Warning:**
   *
   * Please carefully check the coverage rules and exclusions in detail
   * before you submit this report. You entire stake will be forfeited
   * if resolution does not go in your favor. You will be able to unstake
   * and receive back your NPM only if:
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   * - incident resolution is in your favor
   * - after reporting period ends
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param coverKey Enter the cover key you are reporting
   * @param productKey Enter the product key you are reporting
   * @param info Enter IPFS hash of the incident in the following format:
   * `{
   *    incidentTitle: 'Wrong Incident Reporting',
   *    observed: 1723484937,
   *    proofOfIncident: 'https://twitter.com/AnimatedBrand/status/5739383124571205635',
   *    description: 'Animated Brands emphasised in its most recent tweet that the report regarding their purported hack was false.',
   *  }`
   * @param stake Enter the amount you would like to stake to submit this dispute
   *
   */
  function dispute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustNotHaveDispute(coverKey, productKey);
    s.mustBeReporting(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Stake insufficient");
    require(stake >= s.getMinReportingStakeInternal(coverKey), "Stake insufficient");

    s.addRefutationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    // Transfer the stake to the resolution contract
    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Disputed(coverKey, productKey, msg.sender, incidentDate, info, stake);
    emit Refuted(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Allows a cover manager set first reporting (minimum) stake of a given cover.
   *
   * @param coverKey Provide a coverKey or leave it empty. If empty, the stake is set as
   * fallback value. Covers that do not have customized first reporting stake will infer to the fallback value.
   * @param value Enter the first reporting stake in NPM units
   *
   */
  function setFirstReportingStake(bytes32 coverKey, uint256 value) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    require(value > 0, "Please specify value");

    uint256 previous = getFirstReportingStake(coverKey);

    if (coverKey > 0) {
      s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, coverKey, value);
    } else {
      s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, value);
    }

    emit FirstReportingStakeSet(coverKey, previous, value);
  }

  /**
   * @dev Returns the minimum amount of NPM tokens required to `report` or `dispute`
   * a cover.
   *
   * @param coverKey Specify the cover you want to get the minimum stake required value of.
   *
   */
  function getFirstReportingStake(bytes32 coverKey) public view override returns (uint256) {
    return s.getMinReportingStakeInternal(coverKey);
  }

  /**
   * @dev Allows a cover manager set burn rate of the NPM tokens of the invalid camp.
   * The protocol forfeits all stakes of invalid camp voters. During `unstakeWithClaim`,
   * NPM tokens get proportionately burned as configured here.
   *
   * <br /> <br />
   *
   * The unclaimed and thus unburned NPM stakes will be manually pulled
   * and burned on a periodic but not-so-frequent basis.
   *
   * @param value Enter the burn rate in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function setReportingBurnRate(uint256 value) external override nonReentrant {
    require(value > 0, "Please specify value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    uint256 previous = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE, value);

    emit ReportingBurnRateSet(previous, value);
  }

  /**
   * @dev Allows a cover manager set reporter comission of the NPM tokens from the invalid camp.
   * The protocol forfeits all stakes of invalid camp voters. During `unstakeWithClaim`,
   * NPM tokens get proportionately transferred to the **valid reporter** as configured here.
   *
   * <br /> <br />
   *
   * The unclaimed and thus unrewarded NPM stakes will be manually pulled and burned on a periodic but not-so-frequent basis.
   *
   * @param value Enter the valid reporter comission in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function setReporterCommission(uint256 value) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    require(value > 0, "Please specify value");

    uint256 previous = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION, value);

    emit ReporterCommissionSet(previous, value);
  }

  /**
   * @dev Gets the latest incident date of a given cover and product
   * @param coverKey Enter the cover key you want to get the incident of
   * @param productKey Enter the product key you want to get the incident of
   *
   */
  function getActiveIncidentDate(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getActiveIncidentDateInternal(coverKey, productKey);
  }

  /**
   * @dev Gets the reporter of a cover by its incident date
   *
   * @custom:note Please note that until resolution deadline is over, the returned
   * reporter might keep changing.
   *
   * @param coverKey Enter the cover key you would like to get the reporter of
   * @param productKey Enter the product key you would like to get the reporter of
   * @param productKey Enter the cover's incident date you would like to get the reporter of
   */
  function getReporter(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view override returns (address) {
    return s.getReporterInternal(coverKey, productKey, incidentDate);
  }

  /**
   * @dev Retuns the resolution date of a given cover
   * @param coverKey Enter the cover key to get the resolution date of
   * @param productKey Enter the product key to get the resolution date of
   *
   */
  function getResolutionTimestamp(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getResolutionTimestampInternal(coverKey, productKey);
  }

  /**
   * @dev Gets an account's attestation details. Please also check `getRefutation` since an account
   * can submit both `attestations` and `refutations` if they wish to.
   *
   * @param coverKey Enter the cover key you want to get attestation of
   * @param productKey Enter the product key you want to get attestation of
   * @param who Enter the account you want to get attestation of
   * @param who Enter the specified cover's indicent date for which attestation will be returned
   *
   */
  function getAttestation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view override returns (uint256 myStake, uint256 totalStake) {
    return s.getAttestationInternal(coverKey, productKey, who, incidentDate);
  }

  /**
   * @dev Gets an account's refutation details. Please also check `getAttestation` since an account
   * can submit both `attestations` and `refutations` if they wish to.
   *
   * @param coverKey Enter the cover key you want to get refutation of
   * @param productKey Enter the product key you want to get refutation of
   * @param who Enter the account you want to get refutation of
   * @param who Enter the specified cover's indicent date for which refutation will be returned
   *
   */
  function getRefutation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view override returns (uint256 myStake, uint256 totalStake) {
    return s.getRefutationInternal(coverKey, productKey, who, incidentDate);
  }
}

/* solhint-disable function-max-lines */
// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IReporter.sol";
import "./IWitness.sol";
import "./IMember.sol";

// solhint-disable-next-line
interface IGovernance is IMember, IReporter, IWitness {

}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IReporter {
  event Reported(bytes32 indexed coverKey, bytes32 indexed productKey, address reporter, uint256 indexed incidentDate, bytes32 info, uint256 initialStake, uint256 resolutionTimestamp);
  event Disputed(bytes32 indexed coverKey, bytes32 indexed productKey, address reporter, uint256 indexed incidentDate, bytes32 info, uint256 initialStake);

  event ReportingBurnRateSet(uint256 previous, uint256 current);
  event FirstReportingStakeSet(bytes32 coverKey, uint256 previous, uint256 current);
  event ReporterCommissionSet(uint256 previous, uint256 current);

  function report(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256 stake
  ) external;

  function dispute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external;

  function getActiveIncidentDate(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function getAttestation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake);

  function getRefutation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake);

  function getReporter(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (address);

  function getResolutionTimestamp(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function setFirstReportingStake(bytes32 coverKey, uint256 value) external;

  function getFirstReportingStake(bytes32 coverKey) external view returns (uint256);

  function setReportingBurnRate(uint256 value) external;

  function setReporterCommission(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../Recoverable.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../interfaces/IWitness.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../../libraries/GovernanceUtilV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/RegistryLibV1.sol";
import "../../interfaces/IVault.sol";

/**
 * @title Witness Contract
 *
 * @dev The witeness contract enables NPM tokenholders to
 * participate in an active cover incident.
 *
 * <br /><br />
 *
 * The participants can choose to support an incident by `attesting`
 * or they can also disagree by `refuting` the incident. In both cases,
 * the tokenholders can choose to submit any amount of
 * NEP stake during the (7 day, configurable) reporting period.
 *
 * <br /><br />
 *
 * After the reporting period, whichever side loses, loses all their tokens.
 * While each `witness` and `reporter` on the winning side will proportionately
 * receive a portion of these tokens as a reward, some forfeited tokens are
 * burned too.
 *
 * <br /><br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
abstract contract Witness is Recoverable, IWitness {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Support the reported incident by staking your NPM token.
   * Your tokens will be frozen until the incident is fully resolved.
   *
   * <br /> <br />
   *
   * Ensure that you not only thoroughly comprehend the terms, exclusion, standard exclusion, etc of the policy,
   * but that you also have all the necessary proof to verify that the requirement has been met.
   *
   * @custom:warning **Warning:**
   *
   * Although you may believe that the incident did actually occur, you may still be wrong.
   * Even when you are right, the governance participants could outcast you.
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   *
   * @param coverKey Enter the key of the active cover
   * @param incidentDate Enter the active cover's date of incident
   * @param stake Enter the amount of NPM tokens you wish to stake.
   * Note that you cannot unstake this amount if the decision was not in your favor.
   */
  function attest(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeReportingOrDisputed(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Enter a stake");

    s.addAttestationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Attested(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Reject the reported incident by staking your NPM token.
   * Your tokens will be frozen until the incident is fully resolved.
   *
   * <br /> <br />
   *
   * Ensure that you not only thoroughly comprehend the terms, exclusion, standard exclusion, etc of the policy,
   * but that you also have all the necessary proof to verify that the requirement has NOT been met.
   *
   * @custom:warning **Warning:**
   *
   * Although you may believe that the incident did not occur, you may still be wrong.
   * Even when you are right, the governance participants could outcast you.
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   *
   * @param coverKey Enter the key of the active cover
   * @param incidentDate Enter the active cover's date of incident
   * @param stake Enter the amount of NPM tokens you wish to stake.
   * Note that you cannot unstake this amount if the decision was not in your favor.
   */
  function refute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustHaveDispute(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Enter a stake");

    s.addRefutationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Refuted(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Gets the status of a given cover
   *
   * @param coverKey Enter the key of the cover you'd like to check the status of
   * @return Returns the cover status as an integer.
   * For more, check the enum `ProductStatus` on `CoverUtilV1` library.
   *
   */
  function getStatus(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getStatusInternal(coverKey, productKey);
  }

  /**
   * @dev Gets the stakes of each side of a given cover governance pool
   *
   * @param coverKey Enter the key of the cover you'd like to check the stakes of
   * @param incidentDate Enter the active cover's date of incident
   * @return Returns an array of integers --> [yes, no]
   *
   */
  function getStakes(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view override returns (uint256, uint256) {
    return s.getStakesInternal(coverKey, productKey, incidentDate);
  }

  /**
   * @dev Gets the stakes of each side of a given cover governance pool for the specified account.
   *
   * @param coverKey Enter the key of the cover you'd like to check the stakes of
   * @param incidentDate Enter the active cover's date of incident
   * @param account Enter the account you'd like to get the stakes of
   * @return Returns an array of integers --> [yes, no]
   *
   */
  function getStakesOf(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) external view override returns (uint256, uint256) {
    return s.getStakesOfInternal(account, coverKey, productKey, incidentDate);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IRecoverable.sol";
import "../libraries/BaseLibV1.sol";
import "../libraries/ValidationLibV1.sol";

/**
 *
 * @title Recoverable Contract
 * @dev The recoverable contract enables "Recovery Agents" to recover
 * Ether and ERC-20 tokens sent to this address.
 *
 * To learn more about our recovery policy, please refer to the following doc:
 * https://docs.neptunemutual.com/usage/recovering-cryptocurrencies
 *
 */
abstract contract Recoverable is ReentrancyGuard, IRecoverable {
  using ValidationLibV1 for IStore;
  IStore public override s;

  constructor(IStore store) {
    require(address(store) != address(0), "Invalid Store");
    s = store;
  }

  /**
   * @dev Recover all Ether held by the contract.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   */
  function recoverEther(address sendTo) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeRecoveryAgent(s);
    BaseLibV1.recoverEtherInternal(sendTo);
  }

  /**
   * @dev Recover all ERC-20 compatible tokens sent to this address.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   *
   * @custom:suppress-malicious-erc The malicious ERC-20 `token` should only be invoked via `NTransferUtil`.
   * @custom:suppress-address-trust-issue Although the token can't be trusted, the recovery agent has to check the token code manually.
   *
   * @param token ERC-20 The address of the token contract
   */
  function recoverToken(address token, address sendTo) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeRecoveryAgent(s);
    BaseLibV1.recoverTokenInternal(token, sendTo);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IERC20Detailed.sol";

library ProtoUtilV1 {
  using StoreKeyUtil for IStore;

  uint256 public constant MULTIPLIER = 10_000;
  uint256 public constant MAX_LIQUIDITY = 45_000_000_000;
  uint256 public constant MAX_PROPOSAL_AMOUNT = 45_000_000_000;
  uint256 public constant MAX_NPM_STAKE = 10_000_000_000;
  uint256 public constant NPM_PRECISION = 1 ether;
  uint256 public constant CXTOKEN_PRECISION = 1 ether;
  uint256 public constant POD_PRECISION = 1 ether;

  /// @dev Protocol contract namespace
  bytes32 public constant CNS_CORE = "cns:core";

  /// @dev The address of NPM token available in this blockchain
  bytes32 public constant CNS_NPM = "cns:core:npm:instance";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant CNS_COVER = "cns:cover";

  bytes32 public constant CNS_UNISWAP_V2_ROUTER = "cns:core:uni:v2:router";
  bytes32 public constant CNS_UNISWAP_V2_FACTORY = "cns:core:uni:v2:factory";
  bytes32 public constant CNS_PRICE_DISCOVERY = "cns:core:price:discovery";
  bytes32 public constant CNS_TREASURY = "cns:core:treasury";
  bytes32 public constant CNS_NPM_PRICE_ORACLE = "cns:core:npm:price:oracle";
  bytes32 public constant CNS_COVER_REASSURANCE = "cns:cover:reassurance";
  bytes32 public constant CNS_POOL_BOND = "cns:pool:bond";
  bytes32 public constant CNS_COVER_POLICY = "cns:cover:policy";
  bytes32 public constant CNS_COVER_POLICY_MANAGER = "cns:cover:policy:manager";
  bytes32 public constant CNS_COVER_POLICY_ADMIN = "cns:cover:policy:admin";
  bytes32 public constant CNS_COVER_STAKE = "cns:cover:stake";
  bytes32 public constant CNS_COVER_VAULT = "cns:cover:vault";
  bytes32 public constant CNS_COVER_VAULT_DELEGATE = "cns:cover:vault:delegate";
  bytes32 public constant CNS_COVER_STABLECOIN = "cns:cover:sc";
  bytes32 public constant CNS_COVER_CXTOKEN_FACTORY = "cns:cover:cxtoken:factory";
  bytes32 public constant CNS_COVER_VAULT_FACTORY = "cns:cover:vault:factory";
  bytes32 public constant CNS_BOND_POOL = "cns:pools:bond";
  bytes32 public constant CNS_STAKING_POOL = "cns:pools:staking";
  bytes32 public constant CNS_LIQUIDITY_ENGINE = "cns:liquidity:engine";
  bytes32 public constant CNS_STRATEGY_AAVE = "cns:strategy:aave";
  bytes32 public constant CNS_STRATEGY_COMPOUND = "cns:strategy:compound";

  /// @dev Governance contract address
  bytes32 public constant CNS_GOVERNANCE = "cns:gov";

  /// @dev Governance:Resolution contract address
  bytes32 public constant CNS_GOVERNANCE_RESOLUTION = "cns:gov:resolution";

  /// @dev Claims processor contract address
  bytes32 public constant CNS_CLAIM_PROCESSOR = "cns:claim:processor";

  /// @dev The address where `burn tokens` are sent or collected.
  /// The collection behavior (collection) is required if the protocol
  /// is deployed on a sidechain or a layer-2 blockchain.
  /// &nbsp;\n
  /// The collected NPM tokens are will be periodically bridged back to Ethereum
  /// and then burned.
  bytes32 public constant CNS_BURNER = "cns:core:burner";

  /// @dev Namespace for all protocol members.
  bytes32 public constant NS_MEMBERS = "ns:members";

  /// @dev Namespace for protocol contract members.
  bytes32 public constant NS_CONTRACTS = "ns:contracts";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant NS_COVER = "ns:cover";
  bytes32 public constant NS_COVER_PRODUCT = "ns:cover:product";
  bytes32 public constant NS_COVER_PRODUCT_EFFICIENCY = "ns:cover:product:efficiency";

  bytes32 public constant NS_COVER_CREATION_DATE = "ns:cover:creation:date";
  bytes32 public constant NS_COVER_CREATION_FEE = "ns:cover:creation:fee";
  bytes32 public constant NS_COVER_CREATION_MIN_STAKE = "ns:cover:creation:min:stake";
  bytes32 public constant NS_COVER_REASSURANCE = "ns:cover:reassurance";
  bytes32 public constant NS_COVER_REASSURANCE_PAYOUT = "ns:cover:reassurance:payout";
  bytes32 public constant NS_COVER_REASSURANCE_WEIGHT = "ns:cover:reassurance:weight";
  bytes32 public constant NS_COVER_REASSURANCE_RATE = "ns:cover:reassurance:rate";
  bytes32 public constant NS_COVER_LEVERAGE_FACTOR = "ns:cover:leverage:factor";
  bytes32 public constant NS_COVER_CREATION_FEE_EARNING = "ns:cover:creation:fee:earning";
  bytes32 public constant NS_COVER_INFO = "ns:cover:info";
  bytes32 public constant NS_COVER_OWNER = "ns:cover:owner";
  bytes32 public constant NS_COVER_SUPPORTS_PRODUCTS = "ns:cover:supports:products";

  bytes32 public constant NS_VAULT_STRATEGY_OUT = "ns:vault:strategy:out";
  bytes32 public constant NS_VAULT_LENDING_INCOMES = "ns:vault:lending:incomes";
  bytes32 public constant NS_VAULT_LENDING_LOSSES = "ns:vault:lending:losses";
  bytes32 public constant NS_VAULT_DEPOSIT_HEIGHTS = "ns:vault:deposit:heights";
  bytes32 public constant NS_COVER_LIQUIDITY_LENDING_PERIOD = "ns:cover:liquidity:len:p";
  bytes32 public constant NS_COVER_LIQUIDITY_MAX_LENDING_RATIO = "ns:cover:liquidity:max:lr";
  bytes32 public constant NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW = "ns:cover:liquidity:ww";
  bytes32 public constant NS_COVER_LIQUIDITY_MIN_STAKE = "ns:cover:liquidity:min:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_STAKE = "ns:cover:liquidity:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITTED = "ns:cover:liquidity:committed";
  bytes32 public constant NS_COVER_STABLECOIN_NAME = "ns:cover:stablecoin:name";
  bytes32 public constant NS_COVER_REQUIRES_WHITELIST = "ns:cover:requires:whitelist";

  bytes32 public constant NS_COVER_HAS_FLASH_LOAN = "ns:cover:has:fl";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE = "ns:cover:liquidity:fl:fee";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE_PROTOCOL = "ns:proto:cover:liquidity:fl:fee";

  bytes32 public constant NS_COVERAGE_LAG = "ns:coverage:lag";
  bytes32 public constant NS_COVER_POLICY_RATE_FLOOR = "ns:cover:policy:rate:floor";
  bytes32 public constant NS_COVER_POLICY_RATE_CEILING = "ns:cover:policy:rate:ceiling";
  bytes32 public constant NS_POLICY_DISABLED = "ns:policy:disabled";

  bytes32 public constant NS_COVER_STAKE = "ns:cover:stake";
  bytes32 public constant NS_COVER_STAKE_OWNED = "ns:cover:stake:owned";
  bytes32 public constant NS_COVER_STATUS = "ns:cover:status";
  bytes32 public constant NS_COVER_CXTOKEN = "ns:cover:cxtoken";
  bytes32 public constant NS_VAULT_TOKEN_NAME = "ns:vault:token:name";
  bytes32 public constant NS_VAULT_TOKEN_SYMBOL = "ns:vault:token:symbol";
  bytes32 public constant NS_COVER_CREATOR_WHITELIST = "ns:cover:creator:whitelist";
  bytes32 public constant NS_COVER_USER_WHITELIST = "ns:cover:user:whitelist";
  bytes32 public constant NS_COVER_CLAIM_BLACKLIST = "ns:cover:claim:blacklist";

  /// @dev Resolution timestamp = timestamp of first reporting + reporting period
  bytes32 public constant NS_GOVERNANCE_RESOLUTION_TS = "ns:gov:resolution:ts";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKEN = "ns:gov:unstaken";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_TS = "ns:gov:unstake:ts";

  /// @dev The reward received by the winning camp
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REWARD = "ns:gov:unstake:reward";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_BURNED = "ns:gov:unstake:burned";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REPORTER_FEE = "ns:gov:unstake:rep:fee";

  bytes32 public constant NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE = "ns:gov:rep:min:first:stake";

  /// @dev An approximate date and time when trigger event or cover incident occurred
  bytes32 public constant NS_GOVERNANCE_REPORTING_INCIDENT_DATE = "ns:gov:rep:incident:date";

  /// @dev A period (in solidity timestamp) configurable by cover creators during
  /// when NPM tokenholders can vote on incident reporting proposals
  bytes32 public constant NS_GOVERNANCE_REPORTING_PERIOD = "ns:gov:rep:period";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who saw incident to have happened
  /// 2. For address --> The address of the first reporter
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_YES = "ns:gov:rep:witness:yes";

  /// @dev Used as key to flag if a cover was disputed. Cleared when a cover is finalized.
  bytes32 public constant NS_GOVERNANCE_REPORTING_HAS_A_DISPUTE = "ns:gov:rep:has:dispute";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who disagreed with and disputed an incident reporting
  /// 2. For address --> The address of the first disputing reporter (disputer / candidate reporter)
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_NO = "ns:gov:rep:witness:no";

  /// @dev Stakes guaranteed by an individual witness supporting the "incident happened" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES = "ns:gov:rep:stake:owned:yes";

  /// @dev Stakes guaranteed by an individual witness supporting the "false reporting" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO = "ns:gov:rep:stake:owned:no";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake reward to burn.
  /// @custom:note that the reward comes from the losing camp after resolution is achieved.
  bytes32 public constant NS_GOVERNANCE_REPORTING_BURN_RATE = "ns:gov:rep:burn:rate";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake
  /// reward to provide to the final reporter.
  bytes32 public constant NS_GOVERNANCE_REPORTER_COMMISSION = "ns:gov:reporter:commission";

  bytes32 public constant NS_CLAIM_PERIOD = "ns:claim:period";

  bytes32 public constant NS_CLAIM_PAYOUTS = "ns:claim:payouts";

  /// @dev A 24-hour delay after a governance agent "resolves" an actively reported cover.
  bytes32 public constant NS_CLAIM_BEGIN_TS = "ns:claim:begin:ts";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_CLAIM_EXPIRY_TS = "ns:claim:expiry:ts";

  bytes32 public constant NS_RESOLUTION_DEADLINE = "ns:resolution:deadline";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_RESOLUTION_COOL_DOWN_PERIOD = "ns:resolution:cdp";

  /// @dev The percentage rate (x MULTIPLIER) of amount deducted by the platform
  /// for each successful claims payout
  bytes32 public constant NS_COVER_PLATFORM_FEE = "ns:cover:platform:fee";

  /// @dev The percentage rate (x MULTIPLIER) of amount provided to the first reporter
  /// upon favorable incident resolution. This amount is a commission of the
  /// 'ns:claim:platform:fee'
  bytes32 public constant NS_CLAIM_REPORTER_COMMISSION = "ns:claim:reporter:commission";

  bytes32 public constant NS_LAST_LIQUIDITY_STATE_UPDATE = "ns:last:snl:update";
  bytes32 public constant NS_LIQUIDITY_STATE_UPDATE_INTERVAL = "ns:snl:update:interval";
  bytes32 public constant NS_LENDING_STRATEGY_ACTIVE = "ns:lending:strategy:active";
  bytes32 public constant NS_LENDING_STRATEGY_DISABLED = "ns:lending:strategy:disabled";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_START = "ns:lending:strategy:w:start";
  bytes32 public constant NS_ACCRUAL_INVOCATION = "ns:accrual:invocation";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_END = "ns:lending:strategy:w:end";

  bytes32 public constant CNAME_PROTOCOL = "Neptune Mutual Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "Policy Admin";
  bytes32 public constant CNAME_POLICY_MANAGER = "Policy Manager";
  bytes32 public constant CNAME_BOND_POOL = "BondPool";
  bytes32 public constant CNAME_STAKING_POOL = "Staking Pool";
  bytes32 public constant CNAME_POD_STAKING_POOL = "PODStaking Pool";
  bytes32 public constant CNAME_CLAIMS_PROCESSOR = "Claims Processor";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_GOVERNANCE = "Governance";
  bytes32 public constant CNAME_RESOLUTION = "Resolution";
  bytes32 public constant CNAME_VAULT_FACTORY = "Vault Factory";
  bytes32 public constant CNAME_CXTOKEN_FACTORY = "cxToken Factory";
  bytes32 public constant CNAME_COVER_STAKE = "Cover Stake";
  bytes32 public constant CNAME_COVER_REASSURANCE = "Cover Reassurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";
  bytes32 public constant CNAME_VAULT_DELEGATE = "Vault Delegate";
  bytes32 public constant CNAME_LIQUIDITY_ENGINE = "Liquidity Engine";
  bytes32 public constant CNAME_STRATEGY_AAVE = "Aave Strategy";
  bytes32 public constant CNAME_STRATEGY_COMPOUND = "Compound Strategy";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return IProtocol(getProtocolAddress(s));
  }

  function getProtocolAddress(IStore s) public view returns (address) {
    return s.getAddressByKey(CNS_CORE);
  }

  function getContract(IStore s, bytes32 name) external view returns (address) {
    return _getContract(s, name);
  }

  function isProtocolMember(IStore s, address contractAddress) external view returns (bool) {
    return _isProtocolMember(s, contractAddress);
  }

  /**
   * @dev Reverts if the caller is one of the protocol members.
   */
  function mustBeProtocolMember(IStore s, address contractAddress) external view {
    bool isMember = _isProtocolMember(s, contractAddress);
    require(isMember, "Not a protocol member");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   * @param sender Enter the `msg.sender` value
   */
  function mustBeExactContract(
    IStore s,
    bytes32 name,
    address sender
  ) public view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function senderMustBeExactContract(IStore s, bytes32 name) external view {
    return callerMustBeExactContract(s, name, msg.sender);
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function callerMustBeExactContract(
    IStore s,
    bytes32 name,
    address caller
  ) public view {
    return mustBeExactContract(s, name, caller);
  }

  function npmToken(IStore s) external view returns (IERC20) {
    return IERC20(getNpmTokenAddress(s));
  }

  function getNpmTokenAddress(IStore s) public view returns (address) {
    address npm = s.getAddressByKey(CNS_NPM);
    return npm;
  }

  function getUniswapV2Router(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_ROUTER);
  }

  function getUniswapV2Factory(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_FACTORY);
  }

  function getNpmPriceOracle(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_NPM_PRICE_ORACLE);
  }

  function getTreasury(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_TREASURY);
  }

  function getStablecoin(IStore s) public view returns (address) {
    return s.getAddressByKey(CNS_COVER_STABLECOIN);
  }

  function getStablecoinPrecision(IStore s) external view returns (uint256) {
    return 10**IERC20Detailed(getStablecoin(s)).decimals();
  }

  function getBurnAddress(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_BURNER);
  }

  function _isProtocolMember(IStore s, address contractAddress) private view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, contractAddress);
  }

  function _getContract(IStore s, bytes32 name) private view returns (address) {
    return s.getAddressByKeys(NS_CONTRACTS, name);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
// solhint-disable func-order
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";

library StoreKeyUtil {
  function setUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setUint(key, value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2, key3), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2, account), value);
  }

  function addUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.addUint(key, value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2, account), value);
  }

  function subtractUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.subtractUint(key, value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2, account), value);
  }

  function setStringByKey(
    IStore s,
    bytes32 key,
    string calldata value
  ) external {
    require(key > 0, "Invalid key");
    s.setString(key, value);
  }

  function setStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    string calldata value
  ) external {
    return s.setString(_getKey(key1, key2), value);
  }

  function setBytes32ByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    s.setBytes32(key, value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.setBytes32(_getKey(key1, key2), value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.setBytes32(_getKey(key1, key2, key3), value);
  }

  function setBoolByKey(
    IStore s,
    bytes32 key,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBool(key, value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    return s.setBool(_getKey(key1, key2), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bool value
  ) external {
    return s.setBool(_getKey(key1, key2, key3), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    return s.setBool(_getKey(key, account), value);
  }

  function setAddressByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddress(key, value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2, key3), value);
  }

  function setAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressArrayItem(key, value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2), value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function setAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressBoolean(key, account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2), account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2, key3), account, value);
  }

  function deleteUintByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteUint(key);
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteUint(_getKey(key1, key2));
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external {
    return s.deleteUint(_getKey(key1, key2, key3));
  }

  function deleteBytes32ByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    s.deleteBytes32(key);
  }

  function deleteBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBytes32(_getKey(key1, key2));
  }

  function deleteBoolByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteBool(key);
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBool(_getKey(key1, key2));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external {
    return s.deleteBool(_getKey(key, account));
  }

  function deleteAddressByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteAddress(key);
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteAddress(_getKey(key1, key2));
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external {
    return s.deleteAddress(_getKey(key1, key2, key3));
  }

  function deleteAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItem(key, value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2), value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteAddressArrayByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItemByIndex(key, index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function getUintByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getUint(key);
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2, key3));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2, account));
  }

  function getStringByKey(IStore s, bytes32 key) external view returns (string memory) {
    require(key > 0, "Invalid key");
    return s.getString(key);
  }

  function getStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (string memory) {
    return s.getString(_getKey(key1, key2));
  }

  function getBytes32ByKey(IStore s, bytes32 key) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32(key);
  }

  function getBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32) {
    return s.getBytes32(_getKey(key1, key2));
  }

  function getBoolByKey(IStore s, bytes32 key) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getBool(key);
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (bool) {
    return s.getBool(_getKey(key1, key2, key3));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bool) {
    return s.getBool(_getKey(key1, key2));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    return s.getBool(_getKey(key, account));
  }

  function getAddressByKey(IStore s, bytes32 key) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddress(key);
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2, key3));
  }

  function getAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getAddressBoolean(key, account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2), account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2, key3), account);
  }

  function countAddressArrayByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.countAddressArrayItems(key);
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2));
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2, key3));
  }

  function getAddressArrayByKey(IStore s, bytes32 key) external view returns (address[] memory) {
    require(key > 0, "Invalid key");
    return s.getAddressArray(key);
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2));
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2, key3));
  }

  function getAddressArrayItemPositionByKey(
    IStore s,
    bytes32 key,
    address addressToFind
  ) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemPosition(key, addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2), addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2, key3), addressToFind);
  }

  function getAddressArrayItemByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemByIndex(key, index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function _getKey(bytes32 key1, bytes32 key2) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2, key3));
  }

  function _getKey(bytes32 key, address account) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key, account));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2, account));
  }

  function setBytes32ArrayByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBytes32ArrayItem(key, value);
  }

  function setBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.setBytes32ArrayItem(_getKey(key1, key2), value);
  }

  function setBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.setBytes32ArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteBytes32ArrayByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteBytes32ArrayItem(key, value);
  }

  function deleteBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.deleteBytes32ArrayItem(_getKey(key1, key2), value);
  }

  function deleteBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.deleteBytes32ArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteBytes32ArrayByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteBytes32ArrayItemByIndex(key, index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    return s.deleteBytes32ArrayItemByIndex(_getKey(key1, key2), index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    return s.deleteBytes32ArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function countBytes32ArrayByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.countBytes32ArrayItems(key);
  }

  function countBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.countBytes32ArrayItems(_getKey(key1, key2));
  }

  function countBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countBytes32ArrayItems(_getKey(key1, key2, key3));
  }

  function getBytes32ArrayByKey(IStore s, bytes32 key) external view returns (bytes32[] memory) {
    require(key > 0, "Invalid key");
    return s.getBytes32Array(key);
  }

  function getBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32[] memory) {
    return s.getBytes32Array(_getKey(key1, key2));
  }

  function getBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (bytes32[] memory) {
    return s.getBytes32Array(_getKey(key1, key2, key3));
  }

  function getBytes32ArrayItemPositionByKey(
    IStore s,
    bytes32 key,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getBytes32ArrayItemPosition(key, bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPosition(_getKey(key1, key2), bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPosition(_getKey(key1, key2, key3), bytes32ToFind);
  }

  function getBytes32ArrayItemByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32ArrayItemByIndex(key, index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndex(_getKey(key1, key2), index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndex(_getKey(key1, key2, key3), index);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../dependencies/BokkyPooBahsDateTimeLibrary.sol";
import "../interfaces/IStore.sol";
import "./ProtoUtilV1.sol";
import "./AccessControlLibV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./StrategyLibV1.sol";
import "../interfaces/ICxToken.sol";
import "../interfaces/IERC20Detailed.sol";

library CoverUtilV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using AccessControlLibV1 for IStore;
  using StrategyLibV1 for IStore;

  uint256 public constant REASSURANCE_WEIGHT_FALLBACK_VALUE = 8000;

  enum ProductStatus {
    Normal,
    Stopped,
    IncidentHappened,
    FalseReporting,
    Claimable
  }

  function getCoverOwner(IStore s, bytes32 coverKey) external view returns (address) {
    return _getCoverOwner(s, coverKey);
  }

  function _getCoverOwner(IStore s, bytes32 coverKey) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, coverKey);
  }

  function getCoverCreationFeeInfo(IStore s)
    external
    view
    returns (
      uint256 fee,
      uint256 minCoverCreationStake,
      uint256 minStakeToAddLiquidity
    )
  {
    fee = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE);
    minCoverCreationStake = getMinCoverCreationStake(s);
    minStakeToAddLiquidity = getMinStakeToAddLiquidity(s);
  }

  function getMinCoverCreationStake(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  function getCoverCreationDate(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_CREATION_DATE, coverKey);
  }

  function getMinStakeToAddLiquidity(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  function getClaimPeriod(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, coverKey);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] Reassurance amount
   * @param _values[3] Reassurance pool weight
   * @param _values[4] Count of products under this cover
   * @param _values[5] Leverage
   * @param _values[6] Cover product efficiency weight
   */
  function getCoverPoolSummaryInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256[] memory _values) {
    _values = new uint256[](8);

    uint256 precision = s.getStablecoinPrecision();

    _values[0] = s.getStablecoinOwnedByVaultInternal(coverKey); // precision: stablecoin
    _values[1] = getActiveLiquidityUnderProtection(s, coverKey, productKey, precision); // <-- adjusted precision
    _values[2] = getReassuranceAmountInternal(s, coverKey); // precision: stablecoin
    _values[3] = getReassuranceWeightInternal(s, coverKey);
    _values[4] = s.countBytes32ArrayByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey);
    _values[5] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LEVERAGE_FACTOR, coverKey);
    _values[6] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT_EFFICIENCY, coverKey, productKey);
  }

  /**
   * @dev Gets the reassurance weight of a given cover key.
   *
   * @param s Provide store instance
   * @param coverKey Enter the cover for which you want to obtain the reassurance weight for.
   *
   * @return If reassurance weight value wasn't set for the specified cover pool,
   * the global value will be returned.
   *
   * If global value, too, isn't available, a fallback value of `REASSURANCE_WEIGHT_FALLBACK_VALUE`
   * is returned.
   */
  function getReassuranceWeightInternal(IStore s, bytes32 coverKey) public view returns (uint256) {
    uint256 setForTheCoverPool = s.getUintByKey(getReassuranceWeightKey(coverKey));

    if (setForTheCoverPool > 0) {
      return setForTheCoverPool;
    }

    // Globally set value: not set for any specifical cover
    uint256 setGlobally = s.getUintByKey(getReassuranceWeightKey(0));

    if (setGlobally > 0) {
      return setGlobally;
    }

    return REASSURANCE_WEIGHT_FALLBACK_VALUE;
  }

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param coverKey Enter the cover key
   */
  function getReassuranceAmountInternal(IStore s, bytes32 coverKey) public view returns (uint256) {
    return s.getUintByKey(getReassuranceKey(coverKey));
  }

  function getReassuranceRateInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 rate = s.getUintByKey(getReassuranceRateKey(coverKey));

    if (rate > 0) {
      return rate;
    }

    // Default: 25%
    return 2500;
  }

  function getReassuranceKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE, coverKey));
  }

  function getReassuranceRateKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_RATE, coverKey));
  }

  function getReassuranceWeightKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_WEIGHT, coverKey));
  }

  function isCoverNormalInternal(IStore s, bytes32 coverKey) external view returns (bool) {
    bool supportsProducts = supportsProductsInternal(s, coverKey);

    if (supportsProducts == false) {
      return getProductStatusInternal(s, coverKey, 0) == ProductStatus.Normal;
    }

    bytes32[] memory products = _getProducts(s, coverKey);

    for (uint256 i = 0; i < products.length; i++) {
      bool isNormal = getProductStatusInternal(s, coverKey, products[i]) == ProductStatus.Normal;

      if (!isNormal) {
        return false;
      }
    }

    return true;
  }

  function getProductStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (ProductStatus) {
    return ProductStatus(s.getUintByKey(getProductStatusKey(coverKey, productKey)));
  }

  /**
   * @dev Gets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function getStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKey(getProductStatusKey(coverKey, productKey));
  }

  function getProductStatusOf(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (ProductStatus) {
    return ProductStatus(getStatusOf(s, coverKey, productKey, incidentDate));
  }

  function getStatusOf(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(getProductStatusOfKey(coverKey, productKey, incidentDate));
  }

  /**
   * @dev Hash key of the product status of the given cover and product
   * to find out the current status. This gets reset during finalization.
   */
  function getProductStatusKey(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STATUS, coverKey, productKey));
  }

  /**
   * @dev Hash key of the product status of (the given cover, product, and incident date)
   * for historical significance. This must not be reset during finalization.
   */
  function getProductStatusOfKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STATUS, coverKey, productKey, incidentDate));
  }

  function getCoverLiquidityStakeKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey));
  }

  function getLastDepositHeightKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_DEPOSIT_HEIGHTS, coverKey));
  }

  function getCoverLiquidityStakeIndividualKey(bytes32 coverKey, address account) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey, account));
  }

  function getBlacklistKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CLAIM_BLACKLIST, coverKey, productKey, incidentDate));
  }

  function getTotalLiquidityUnderProtection(
    IStore s,
    bytes32 coverKey,
    uint256 precision
  ) external view returns (uint256 total) {
    bool supportsProducts = supportsProductsInternal(s, coverKey);

    if (supportsProducts == false) {
      return getActiveLiquidityUnderProtection(s, coverKey, 0, precision);
    }

    bytes32[] memory products = _getProducts(s, coverKey);

    for (uint256 i = 0; i < products.length; i++) {
      total += getActiveLiquidityUnderProtection(s, coverKey, products[i], precision);
    }
  }

  function _getProducts(IStore s, bytes32 coverKey) private view returns (bytes32[] memory products) {
    return s.getBytes32ArrayByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey);
  }

  function getActiveLiquidityUnderProtection(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 adjustPrecision
  ) public view returns (uint256 total) {
    (uint256 current, uint256 future) = _getLiquidityUnderProtectionInfo(s, coverKey, productKey);
    total = current + future;

    // @caution:
    // Adjusting precision results in truncation and data loss.
    //
    // Can also open a can of worms if the protocol stablecoin
    // address needs to be updated in the future.
    total = (total * adjustPrecision) / ProtoUtilV1.CXTOKEN_PRECISION;
  }

  function _getLiquidityUnderProtectionInfo(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) private view returns (uint256 current, uint256 future) {
    uint256 expiryDate = 0;

    (current, expiryDate) = _getCurrentCommitment(s, coverKey, productKey);
    future = _getFutureCommitments(s, coverKey, productKey, expiryDate);
  }

  function _getCurrentCommitment(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) private view returns (uint256 amount, uint256 expiryDate) {
    uint256 incidentDateIfAny = getActiveIncidentDateInternal(s, coverKey, productKey);

    // There isn't any incident for this cover
    // and therefore no need to pay
    if (incidentDateIfAny == 0) {
      return (0, 0);
    }

    expiryDate = _getMonthEndDate(incidentDateIfAny);
    ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, coverKey, productKey, expiryDate));

    if (address(cxToken) != address(0)) {
      amount = cxToken.totalSupply();
    }
  }

  function _getFutureCommitments(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 ignoredExpiryDate
  ) private view returns (uint256 sum) {
    uint256 maxMonthsToProtect = 3;

    for (uint256 i = 0; i < maxMonthsToProtect; i++) {
      uint256 expiryDate = _getNextMonthEndDate(block.timestamp, i); // solhint-disable-line

      if (expiryDate == ignoredExpiryDate || expiryDate <= block.timestamp) {
        // solhint-disable-previous-line
        continue;
      }

      ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, coverKey, productKey, expiryDate));

      if (address(cxToken) != address(0)) {
        sum += cxToken.totalSupply();
      }
    }
  }

  function getStake(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, coverKey);
  }

  /**
   * @dev Sets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function setStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    ProductStatus status
  ) external {
    s.setUintByKey(getProductStatusKey(coverKey, productKey), uint256(status));

    if (incidentDate > 0) {
      s.setUintByKey(getProductStatusOfKey(coverKey, productKey, incidentDate), uint256(status));
    }
  }

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDateInternal(uint256 today, uint256 coverDuration) external pure returns (uint256) {
    // Get the day of the month
    (, , uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(today);

    // Cover duration of 1 month means current month
    // unless today is the 25th calendar day or later
    uint256 monthToAdd = coverDuration - 1;

    if (day >= 25) {
      // Add one month
      monthToAdd += 1;
    }

    return _getNextMonthEndDate(today, monthToAdd);
  }

  // function _getPreviousMonthEndDate(uint256 date, uint256 monthsToSubtract) private pure returns (uint256) {
  //   uint256 pastDate = BokkyPooBahsDateTimeLibrary.subMonths(date, monthsToSubtract);
  //   return _getMonthEndDate(pastDate);
  // }

  function _getNextMonthEndDate(uint256 date, uint256 monthsToAdd) private pure returns (uint256) {
    uint256 futureDate = BokkyPooBahsDateTimeLibrary.addMonths(date, monthsToAdd);
    return _getMonthEndDate(futureDate);
  }

  function _getMonthEndDate(uint256 date) private pure returns (uint256) {
    // Get the year and month from the date
    (uint256 year, uint256 month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(date);

    // Count the total number of days of that month and year
    uint256 daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(year, month);

    // Get the month end date
    return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, daysInMonth, 23, 59, 59);
  }

  function getActiveIncidentDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey);
  }

  function getCxTokenByExpiryDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiryDate
  ) public view returns (address cxToken) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CXTOKEN, coverKey, productKey, expiryDate));
    cxToken = s.getAddress(k);
  }

  function checkIfProductRequiresWhitelist(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey, productKey);
  }

  function checkIfRequiresWhitelist(IStore s, bytes32 coverKey) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey);
  }

  function supportsProductsInternal(IStore s, bytes32 coverKey) public view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_SUPPORTS_PRODUCTS, coverKey);
  }

  function isValidProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey);
  }

  function isActiveProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey) == 1;
  }

  function disablePolicyInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    bool status
  ) external {
    bytes32 key = getPolicyDisabledKey(coverKey, productKey);
    s.setBoolByKey(key, status);
  }

  function isPolicyDisabledInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    bytes32 key = getPolicyDisabledKey(coverKey, productKey);
    return s.getBoolByKey(key);
  }

  function getPolicyDisabledKey(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_POLICY_DISABLED, coverKey, productKey));
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWitness {
  event Attested(bytes32 indexed coverKey, bytes32 indexed productKey, address witness, uint256 indexed incidentDate, uint256 stake);
  event Refuted(bytes32 indexed coverKey, bytes32 indexed productKey, address witness, uint256 indexed incidentDate, uint256 stake);

  function attest(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function refute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function getStatus(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function getStakes(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (uint256, uint256);

  function getStakesOf(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) external view returns (uint256, uint256);
}

/* solhint-disable */

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

library NTransferUtilV2 {
  using SafeERC20 for IERC20;

  /**
   *
   * @dev Ensures approval of ERC20-like token
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   *
   */
  function ensureApproval(
    IERC20 malicious,
    address spender,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    require(spender != address(0), "Invalid spender");
    require(amount > 0, "Invalid transfer amount");

    malicious.safeIncreaseAllowance(spender, amount);
  }

  /**
   * @dev Ensures transfer of ERC20-like token
   *
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
   *
   */
  function ensureTransfer(
    IERC20 malicious,
    address recipient,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    require(recipient != address(0), "Spender can't be zero");
    require(amount > 0, "Invalid transfer amount");

    uint256 balanceBeforeTransfer = malicious.balanceOf(recipient);
    malicious.safeTransfer(recipient, amount);
    uint256 balanceAfterTransfer = malicious.balanceOf(recipient);

    // @suppress-subtraction
    uint256 actualTransferAmount = balanceAfterTransfer - balanceBeforeTransfer;

    require(actualTransferAmount == amount, "Invalid transfer");
  }

  /**
   * @dev Ensures transferFrom of ERC20-like token
   *
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
   *
   */
  function ensureTransferFrom(
    IERC20 malicious,
    address sender,
    address recipient,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    // @todo: require(sender != address(0), "Invalid sender");
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 balanceBeforeTransfer = malicious.balanceOf(recipient);
    malicious.safeTransferFrom(sender, recipient, amount);
    uint256 balanceAfterTransfer = malicious.balanceOf(recipient);

    // @suppress-subtraction
    uint256 actualTransferAmount = balanceAfterTransfer - balanceBeforeTransfer;

    require(actualTransferAmount == amount, "Invalid transfer");
  }
}

/* solhint-disable function-max-lines */
// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./RoutineInvokerLibV1.sol";
import "./StoreKeyUtil.sol";
import "./CoverUtilV1.sol";

library GovernanceUtilV1 {
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ProtoUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;

  function getReportingPeriodInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_PERIOD, coverKey);
  }

  function getReportingBurnRateInternal(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE);
  }

  function getGovernanceReporterCommissionInternal(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION);
  }

  function getPlatformCoverFeeRateInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_COVER_PLATFORM_FEE);
  }

  function getClaimReporterCommissionInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_CLAIM_REPORTER_COMMISSION);
  }

  function getMinReportingStakeInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fb = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE);
    uint256 custom = s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, coverKey);

    return custom > 0 ? custom : fb;
  }

  function getLatestIncidentDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey);
  }

  function getResolutionTimestampInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, coverKey, productKey);
  }

  function getReporterInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (address) {
    CoverUtilV1.ProductStatus status = s.getProductStatusOf(coverKey, productKey, incidentDate);
    bool incidentHappened = status == CoverUtilV1.ProductStatus.IncidentHappened || status == CoverUtilV1.ProductStatus.Claimable;
    bytes32 prefix = incidentHappened ? ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES : ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO;

    return s.getAddressByKeys(prefix, coverKey, productKey);
  }

  function getStakesInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    yes = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
    no = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));
  }

  function _getReporterKey(bytes32 coverKey, bytes32 productKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey));
  }

  function _getIncidentOccurredStakesKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey, incidentDate));
  }

  function _getClaimPayoutsKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_CLAIM_PAYOUTS, coverKey, productKey, incidentDate));
  }

  function _getReassurancePayoutKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_PAYOUT, coverKey, productKey, incidentDate));
  }

  function _getIndividualIncidentOccurredStakeKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES, coverKey, productKey, incidentDate, account));
  }

  function _getDisputerKey(bytes32 coverKey, bytes32 productKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, coverKey, productKey));
  }

  function _getFalseReportingStakesKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, coverKey, productKey, incidentDate));
  }

  function _getIndividualFalseReportingStakeKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO, coverKey, productKey, incidentDate, account));
  }

  function getStakesOfInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    yes = s.getUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, account));
    no = s.getUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, account));
  }

  function getResolutionInfoForInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    public
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp
    )
  {
    (uint256 yes, uint256 no) = getStakesInternal(s, coverKey, productKey, incidentDate);
    (uint256 myYes, uint256 myNo) = getStakesOfInternal(s, account, coverKey, productKey, incidentDate);

    CoverUtilV1.ProductStatus decision = s.getProductStatusOf(coverKey, productKey, incidentDate);
    bool incidentHappened = decision == CoverUtilV1.ProductStatus.IncidentHappened || decision == CoverUtilV1.ProductStatus.Claimable;

    totalStakeInWinningCamp = incidentHappened ? yes : no;
    totalStakeInLosingCamp = incidentHappened ? no : yes;
    myStakeInWinningCamp = incidentHappened ? myYes : myNo;
  }

  function getUnstakeInfoForInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    external
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward,
      uint256 unstaken
    )
  {
    (totalStakeInWinningCamp, totalStakeInLosingCamp, myStakeInWinningCamp) = getResolutionInfoForInternal(s, account, coverKey, productKey, incidentDate);

    unstaken = getReportingUnstakenAmountInternal(s, account, coverKey, productKey, incidentDate);
    require(myStakeInWinningCamp > 0, "Nothing to unstake");

    uint256 rewardRatio = (myStakeInWinningCamp * ProtoUtilV1.MULTIPLIER) / totalStakeInWinningCamp;

    uint256 reward = 0;

    // Incident dates are reset when a reporting is finalized.
    // This check ensures only the people who come to unstake
    // before the finalization will receive rewards
    if (getLatestIncidentDateInternal(s, coverKey, productKey) == incidentDate) {
      // slither-disable-next-line divide-before-multiply
      reward = (totalStakeInLosingCamp * rewardRatio) / ProtoUtilV1.MULTIPLIER;
    }

    toBurn = (reward * getReportingBurnRateInternal(s)) / ProtoUtilV1.MULTIPLIER;
    toReporter = (reward * getGovernanceReporterCommissionInternal(s)) / ProtoUtilV1.MULTIPLIER;
    myReward = reward - toBurn - toReporter;
  }

  function getReportingUnstakenAmountInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate, account));
    return s.getUintByKey(k);
  }

  function updateUnstakeDetailsInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 originalStake,
    uint256 reward,
    uint256 burned,
    uint256 reporterFee
  ) external {
    // Unstake timestamp of the account
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, coverKey, productKey, incidentDate, account));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // Last unstake timestamp
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, coverKey, productKey, incidentDate));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // ---------------------------------------------------------------------

    // Amount unstaken by the account
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate, account));
    s.setUintByKey(k, originalStake);

    // Amount unstaken by everyone
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate));
    s.addUintByKey(k, originalStake);

    // ---------------------------------------------------------------------

    if (reward > 0) {
      // Reward received by the account
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, coverKey, productKey, incidentDate, account));
      s.setUintByKey(k, reward);

      // Total reward received
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, coverKey, productKey, incidentDate));
      s.addUintByKey(k, reward);
    }

    // ---------------------------------------------------------------------

    if (burned > 0) {
      // Total burned
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_BURNED, coverKey, productKey, incidentDate));
      s.addUintByKey(k, burned);
    }

    if (reporterFee > 0) {
      // Total fee paid to the final reporter
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REPORTER_FEE, coverKey, productKey, incidentDate));
      s.addUintByKey(k, reporterFee);
    }
  }

  function _updateProductStatusBeforeResolutionInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private {
    require(incidentDate > 0, "Invalid incident date");

    uint256 yes = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
    uint256 no = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));

    if (no > yes) {
      s.setStatusInternal(coverKey, productKey, incidentDate, CoverUtilV1.ProductStatus.FalseReporting);
      return;
    }

    s.setStatusInternal(coverKey, productKey, incidentDate, CoverUtilV1.ProductStatus.IncidentHappened);
  }

  /**
   * @dev Adds attestation to an incident report
   *
   * @custom:suppress-address-trust-issue The address `who` can be trusted here because we are not treating it like a contract.
   *
   */
  function addAttestationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    mustNotExceedNpmThreshold(stake);

    // Add individual stake of the reporter
    s.addUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, who), stake);

    // All "incident happened" camp witnesses combined
    uint256 currentStake = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));

    // No has reported yet, this is the first report
    if (currentStake == 0) {
      s.setAddressByKey(_getReporterKey(coverKey, productKey), msg.sender);
    }

    s.addUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate), stake);
    _updateProductStatusBeforeResolutionInternal(s, coverKey, productKey, incidentDate);

    s.updateStateAndLiquidity(coverKey);
  }

  function getAttestationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    myStake = s.getUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, who));
    totalStake = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
  }

  /**
   * @dev Adds refutation to an incident report
   *
   * @custom:suppress-address-trust-issue The address `who` can be trusted here because we are not treating it like a contract.
   *
   */
  function addRefutationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    mustNotExceedNpmThreshold(stake);

    s.addUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, who), stake);

    uint256 currentStake = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));

    if (currentStake == 0) {
      // The first reporter who disputed
      s.setAddressByKey(_getDisputerKey(coverKey, productKey), msg.sender);
      s.setBoolByKey(getHasDisputeKeyInternal(coverKey, productKey), true);
    }

    s.addUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate), stake);
    _updateProductStatusBeforeResolutionInternal(s, coverKey, productKey, incidentDate);

    s.updateStateAndLiquidity(coverKey);
  }

  function getHasDisputeKeyInternal(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_HAS_A_DISPUTE, coverKey, productKey));
  }

  function getRefutationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    myStake = s.getUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, who));
    totalStake = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));
  }

  function getCoolDownPeriodInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, coverKey);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  function getResolutionDeadlineInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_DEADLINE, coverKey, productKey);
  }

  function addClaimPayoutsInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 claimed
  ) external {
    s.addUintByKey(_getClaimPayoutsKey(coverKey, productKey, incidentDate), claimed);
  }

  function getClaimPayoutsInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(_getClaimPayoutsKey(coverKey, productKey, incidentDate));
  }

  function getReassurancePayoutInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(_getReassurancePayoutKey(coverKey, productKey, incidentDate));
  }

  function addReassurancePayoutInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 capitalized
  ) external {
    s.addUintByKey(_getReassurancePayoutKey(coverKey, productKey, incidentDate), capitalized);
  }

  function getReassuranceTransferrableInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (uint256) {
    uint256 reassuranceRate = s.getReassuranceRateInternal(coverKey);
    uint256 available = s.getReassuranceAmountInternal(coverKey);
    uint256 reassurancePaid = getReassurancePayoutInternal(s, coverKey, productKey, incidentDate);

    uint256 totalReassurance = available + reassurancePaid;

    uint256 claimsPaid = getClaimPayoutsInternal(s, coverKey, productKey, incidentDate);

    uint256 principal = claimsPaid <= totalReassurance ? claimsPaid : totalReassurance;
    uint256 transferAmount = (principal * reassuranceRate) / ProtoUtilV1.MULTIPLIER;

    return transferAmount - reassurancePaid;
  }

  function mustNotExceedNpmThreshold(uint256 amount) public pure {
    require(amount <= ProtoUtilV1.MAX_NPM_STAKE * 1 ether, "Please specify a smaller amount");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./GovernanceUtilV1.sol";
import "./AccessControlLibV1.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/ICxToken.sol";

library ValidationLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;
  using RegistryLibV1 for IStore;

  /**
   * @dev Reverts if the protocol is paused
   */
  function mustNotBePaused(IStore s) public view {
    address protocol = s.getProtocolAddress();
    require(IPausable(protocol).paused() == false, "Protocol is paused");
  }

  /**
   * @dev Reverts if the cover or any of the cover's product is not normal.
   * @param coverKey Enter the cover key to check
   */
  function mustEnsureAllProductsAreNormal(IStore s, bytes32 coverKey) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
    require(s.isCoverNormalInternal(coverKey) == true, "Status not normal");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the product key to check
   */
  function mustHaveNormalProductStatus(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Normal, "Status not normal");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param coverKey Enter the cover key to check
   */
  function mustBeValidCoverKey(IStore s, bytes32 coverKey) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
  }

  /**
   * @dev Reverts if the cover does not support creating products.
   * @param coverKey Enter the cover key to check
   */
  function mustSupportProducts(IStore s, bytes32 coverKey) external view {
    require(s.supportsProductsInternal(coverKey), "Does not have products");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid product of a cover contract.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the cover key to check
   */
  function mustBeValidProduct(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.isValidProductInternal(coverKey, productKey), "Product does not exist");
  }

  /**
   * @dev Reverts if the key resolves in an expired product.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the cover key to check
   */
  function mustBeActiveProduct(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.isActiveProductInternal(coverKey, productKey), "Product retired or deleted");
  }

  /**
   * @dev Reverts if the sender is not the cover owner
   * @param coverKey Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwner(
    IStore s,
    bytes32 coverKey,
    address sender
  ) public view {
    bool isCoverOwner = s.getCoverOwner(coverKey) == sender;
    require(isCoverOwner, "Forbidden");
  }

  /**
   * @dev Reverts if the sender is not the cover owner or the cover contract
   * @param coverKey Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwnerOrCoverContract(
    IStore s,
    bytes32 coverKey,
    address sender
  ) external view {
    bool isCoverOwner = s.getCoverOwner(coverKey) == sender;
    bool isCoverContract = address(s.getCoverContract()) == sender;

    require(isCoverOwner || isCoverContract, "Forbidden");
  }

  function senderMustBeCoverOwnerOrAdmin(IStore s, bytes32 coverKey) external view {
    if (AccessControlLibV1.hasAccess(s, AccessControlLibV1.NS_ROLES_ADMIN, msg.sender) == false) {
      mustBeCoverOwner(s, coverKey, msg.sender);
    }
  }

  function senderMustBePolicyContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY);
  }

  function senderMustBePolicyManagerContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY_MANAGER);
  }

  function senderMustBeCoverContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER);
  }

  function senderMustBeVaultContract(IStore s, bytes32 coverKey) external view {
    address vault = s.getVaultAddress(coverKey);
    require(msg.sender == vault, "Forbidden");
  }

  function senderMustBeGovernanceContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_GOVERNANCE);
  }

  function senderMustBeClaimsProcessorContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR);
  }

  function callerMustBeClaimsProcessorContract(IStore s, address caller) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR, caller);
  }

  function senderMustBeStrategyContract(IStore s) external view {
    bool senderIsStrategyContract = s.getBoolByKey(_getIsActiveStrategyKey(msg.sender));
    require(senderIsStrategyContract == true, "Not a strategy contract");
  }

  function callerMustBeStrategyContract(IStore s, address caller) public view {
    bool isActive = s.getBoolByKey(_getIsActiveStrategyKey(caller));
    bool wasDisabled = s.getBoolByKey(_getIsDisabledStrategyKey(caller));

    require(isActive == true || wasDisabled == true, "Not a strategy contract");
  }

  function callerMustBeSpecificStrategyContract(
    IStore s,
    address caller,
    bytes32 strategyName
  ) external view {
    callerMustBeStrategyContract(s, caller);
    require(IMember(caller).getName() == strategyName, "Access denied");
  }

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function _getIsDisabledStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, strategyAddress));
  }

  function senderMustBeProtocolMember(IStore s) external view {
    require(s.isProtocolMember(msg.sender), "Forbidden");
  }

  function mustBeReporting(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.IncidentHappened, "Not reporting");
  }

  function mustBeDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.FalseReporting, "Not disputed");
  }

  function mustBeClaimable(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Claimable, "Not claimable");
  }

  function mustBeClaimingOrDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    CoverUtilV1.ProductStatus status = s.getProductStatusInternal(coverKey, productKey);

    bool claiming = status == CoverUtilV1.ProductStatus.Claimable;
    bool falseReporting = status == CoverUtilV1.ProductStatus.FalseReporting;

    require(claiming || falseReporting, "Not claimable nor disputed");
  }

  function mustBeReportingOrDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    CoverUtilV1.ProductStatus status = s.getProductStatusInternal(coverKey, productKey);
    bool incidentHappened = status == CoverUtilV1.ProductStatus.IncidentHappened;
    bool falseReporting = status == CoverUtilV1.ProductStatus.FalseReporting;

    require(incidentHappened || falseReporting, "Not reported nor disputed");
  }

  function mustBeBeforeResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);

    if (deadline > 0) {
      require(block.timestamp < deadline, "Emergency resolution deadline over"); // solhint-disable-line
    }
  }

  function mustNotHaveResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);
    require(deadline == 0, "Resolution already has deadline");
  }

  function mustBeAfterResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);
    require(deadline > 0 && block.timestamp > deadline, "Still unresolved"); // solhint-disable-line
  }

  function mustBeValidIncidentDate(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view {
    require(s.getLatestIncidentDateInternal(coverKey, productKey) == incidentDate, "Invalid incident date");
  }

  function mustHaveDispute(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    bool hasDispute = s.getBoolByKey(GovernanceUtilV1.getHasDisputeKeyInternal(coverKey, productKey));
    require(hasDispute == true, "Not disputed");
  }

  function mustNotHaveDispute(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    bool hasDispute = s.getBoolByKey(GovernanceUtilV1.getHasDisputeKeyInternal(coverKey, productKey));
    require(hasDispute == false, "Already disputed");
  }

  function mustBeDuringReportingPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getResolutionTimestampInternal(coverKey, productKey) >= block.timestamp, "Reporting window closed"); // solhint-disable-line
  }

  function mustBeAfterReportingPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(block.timestamp > s.getResolutionTimestampInternal(coverKey, productKey), "Reporting still active"); // solhint-disable-line
  }

  function mustBeValidCxToken(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken,
    uint256 incidentDate
  ) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_CXTOKEN, cxToken) == true, "Unknown cxToken");

    bytes32 COVER_KEY = ICxToken(cxToken).COVER_KEY(); // solhint-disable-line
    bytes32 PRODUCT_KEY = ICxToken(cxToken).PRODUCT_KEY(); // solhint-disable-line

    require(coverKey == COVER_KEY && productKey == PRODUCT_KEY, "Invalid cxToken");

    uint256 expires = ICxToken(cxToken).expiresOn();
    require(expires > incidentDate, "Invalid or expired cxToken");
  }

  function mustBeValidClaim(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken,
    uint256 incidentDate,
    uint256 amount
  ) external view {
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustBeValidCxToken(s, coverKey, productKey, cxToken, incidentDate);
    mustBeClaimable(s, coverKey, productKey);
    mustBeValidIncidentDate(s, coverKey, productKey, incidentDate);
    mustBeDuringClaimPeriod(s, coverKey, productKey);
    require(ICxToken(cxToken).getClaimablePolicyOf(account) >= amount, "Claim exceeds your coverage");
  }

  function mustNotHaveUnstaken(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view {
    uint256 withdrawal = s.getReportingUnstakenAmountInternal(account, coverKey, productKey, incidentDate);
    require(withdrawal == 0, "Already unstaken");
  }

  /**
   * @dev Validates your `unstakeWithoutClaim` arguments
   *
   * @custom:note This function is not intended be used and does not produce correct result
   * during a claim period. Please use `validateUnstakeWithClaim` if you are accessing
   * this function during claim period.
   */
  function validateUnstakeWithoutClaim(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustNotHaveUnstaken(s, msg.sender, coverKey, productKey, incidentDate);
    mustBeAfterReportingPeriod(s, coverKey, productKey);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, coverKey, productKey);
  }

  /**
   * @dev Validates your `unstakeWithClaim` arguments
   *
   * @custom:note This function is only intended be used during a claim period.
   * Please use `validateUnstakeWithoutClaim` if you are accessing
   * this function after claim period expiry.
   */
  function validateUnstakeWithClaim(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustNotHaveUnstaken(s, msg.sender, coverKey, productKey, incidentDate);
    mustBeAfterReportingPeriod(s, coverKey, productKey);

    // If this reporting gets finalized, incident date will become invalid
    // meaning this execution will revert thereby restricting late comers
    // to access this feature. But they can still access `unstake` feature
    // to withdraw their stake.
    mustBeValidIncidentDate(s, coverKey, productKey, incidentDate);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, coverKey, productKey);

    bool incidentHappened = s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Claimable;

    if (incidentHappened) {
      // Incident occurred. Must unstake with claim during the claim period.
      mustBeDuringClaimPeriod(s, coverKey, productKey);
      return;
    }
  }

  function mustBeDuringClaimPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    uint256 beginsFrom = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, coverKey, productKey);
    uint256 expiresAt = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey);

    require(beginsFrom > 0, "Invalid claim begin date");
    require(expiresAt > beginsFrom, "Invalid claim period");

    require(block.timestamp >= beginsFrom, "Claim period hasn't begun"); // solhint-disable-line
    require(block.timestamp <= expiresAt, "Claim period has expired"); // solhint-disable-line
  }

  function mustBeAfterClaimExpiry(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey), "Claim still active"); // solhint-disable-line
  }

  /**
   * @dev Reverts if the sender is not whitelisted cover creator.
   */
  function senderMustBeWhitelistedCoverCreator(IStore s) external view {
    require(s.getAddressBooleanByKey(ProtoUtilV1.NS_COVER_CREATOR_WHITELIST, msg.sender), "Not whitelisted");
  }

  function senderMustBeWhitelistedIfRequired(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address sender
  ) external view {
    bool supportsProducts = s.supportsProductsInternal(coverKey);
    bool required = supportsProducts ? s.checkIfProductRequiresWhitelist(coverKey, productKey) : s.checkIfRequiresWhitelist(coverKey);

    if (required == false) {
      return;
    }

    require(s.getAddressBooleanByKeys(ProtoUtilV1.NS_COVER_USER_WHITELIST, coverKey, productKey, sender), "You are not whitelisted");
  }

  function mustBeSupportedProductOrEmpty(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    bool hasProducts = s.supportsProductsInternal(coverKey);

    hasProducts ? require(productKey > 0, "Specify a product") : require(productKey == 0, "Invalid product");

    if (hasProducts) {
      mustBeValidProduct(s, coverKey, productKey);
      mustBeActiveProduct(s, coverKey, productKey);
    }
  }

  function mustNotHavePolicyDisabled(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(!s.isPolicyDisabledInternal(coverKey, productKey), "Policy purchase disabled");
  }

  function mustNotExceedStablecoinThreshold(IStore s, uint256 amount) external view {
    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    require(amount <= ProtoUtilV1.MAX_LIQUIDITY * stablecoinPrecision, "Please specify a smaller amount");
  }

  function mustNotExceedProposalThreshold(IStore s, uint256 amount) external view {
    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    require(amount <= ProtoUtilV1.MAX_PROPOSAL_AMOUNT * stablecoinPrecision, "Please specify a smaller amount");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/ICover.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/IBondPool.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/ICxTokenFactory.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";

library RegistryLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getGovernanceContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE));
  }

  function getResolutionContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE_RESOLUTION));
  }

  function getStakingContract(IStore s) external view returns (ICoverStake) {
    return ICoverStake(s.getContract(ProtoUtilV1.CNS_COVER_STAKE));
  }

  function getCxTokenFactory(IStore s) external view returns (ICxTokenFactory) {
    return ICxTokenFactory(s.getContract(ProtoUtilV1.CNS_COVER_CXTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) external view returns (IPolicy) {
    return IPolicy(s.getContract(ProtoUtilV1.CNS_COVER_POLICY));
  }

  function getReassuranceContract(IStore s) external view returns (ICoverReassurance) {
    return ICoverReassurance(s.getContract(ProtoUtilV1.CNS_COVER_REASSURANCE));
  }

  function getBondPoolContract(IStore s) external view returns (IBondPool) {
    return IBondPool(getBondPoolAddress(s));
  }

  function getProtocolContract(IStore s, bytes32 cns) public view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, cns);
  }

  function getProtocolContract(
    IStore s,
    bytes32 cns,
    bytes32 key
  ) public view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, cns, key);
  }

  function getCoverContract(IStore s) external view returns (ICover) {
    address vault = getProtocolContract(s, ProtoUtilV1.CNS_COVER);
    return ICover(vault);
  }

  function getVault(IStore s, bytes32 coverKey) external view returns (IVault) {
    return IVault(getVaultAddress(s, coverKey));
  }

  function getVaultAddress(IStore s, bytes32 coverKey) public view returns (address) {
    address vault = getProtocolContract(s, ProtoUtilV1.CNS_COVER_VAULT, coverKey);
    return vault;
  }

  function getVaultDelegate(IStore s) external view returns (address) {
    address vaultImplementation = getProtocolContract(s, ProtoUtilV1.CNS_COVER_VAULT_DELEGATE);
    return vaultImplementation;
  }

  function getStakingPoolAddress(IStore s) external view returns (address) {
    address pool = getProtocolContract(s, ProtoUtilV1.CNS_STAKING_POOL);
    return pool;
  }

  function getBondPoolAddress(IStore s) public view returns (address) {
    address pool = getProtocolContract(s, ProtoUtilV1.CNS_BOND_POOL);
    return pool;
  }

  function getVaultFactoryContract(IStore s) external view returns (IVaultFactory) {
    address factory = s.getContract(ProtoUtilV1.CNS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IVault is IMember, IERC20 {
  event GovernanceTransfer(address indexed to, uint256 amount);
  event StrategyTransfer(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount);
  event StrategyReceipt(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount, uint256 income, uint256 loss);
  event PodsIssued(address indexed account, uint256 issued, uint256 liquidityAdded, bytes32 indexed referralCode);
  event PodsRedeemed(address indexed account, uint256 redeemed, uint256 liquidityReleased);
  event FlashLoanBorrowed(address indexed lender, address indexed borrower, address indexed stablecoin, uint256 amount, uint256 fee);
  event NpmStaken(address indexed account, uint256 amount);
  event NpmUnstaken(address indexed account, uint256 amount);
  event InterestAccrued(bytes32 indexed coverKey);
  event Entered(bytes32 indexed coverKey, address indexed account);
  event Exited(bytes32 indexed coverKey, address indexed account);

  function key() external view returns (bytes32);

  function sc() external view returns (address);

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStake Enter the amount of NPM token to stake. Will be locked for a minimum window of one withdrawal period.
   */
  function addLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bytes32 referralCode
  ) external;

  function accrueInterest() external;

  /**
   * @dev Removes liquidity from the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to remove.
   * @param npmStake Enter the amount of NPM stake to remove.
   * @param exit Indicates NPM stake exit.
   */
  function removeLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bool exit
  ) external;

  /**
   * @dev Transfers liquidity to governance contract.
   * @param coverKey Enter the cover key
   * @param to Enter the destination account
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Transfers liquidity to strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferToStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  /**
   * @dev Receives from strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function receiveFromStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function calculatePods(uint256 forStablecoinUnits) external view returns (uint256);

  function calculateLiquidity(uint256 podsToBurn) external view returns (uint256);

  function getInfo(address forAccount) external view returns (uint256[] memory result);

  /**
   * @dev Returns the stablecoin balance of this vault
   * This also includes amounts lent out in lending strategies
   */
  function getStablecoinBalanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";

interface IRecoverable {
  function s() external view returns (IStore);

  function recoverEther(address sendTo) external;

  function recoverToken(address token, address sendTo) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ValidationLibV1.sol";
import "./AccessControlLibV1.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IPausable.sol";

library BaseLibV1 {
  using ValidationLibV1 for IStore;
  using SafeERC20 for IERC20;

  /**
   * @dev Recover all Ether held by the contract.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   */
  function recoverEtherInternal(address sendTo) external {
    // slither-disable-next-line arbitrary-send
    payable(sendTo).transfer(address(this).balance);
  }

  /**
   * @dev Recover all IERC-20 compatible tokens sent to this address.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   *
   * @custom:suppress-malicious-erc Risk tolerable. Although the token can't be trusted, the recovery agent has to check the token code manually.
   * @custom:suppress-address-trust-issue Risk tolerable. Although the token can't be trusted, the recovery agent has to check the token code manually.
   *
   * @param token IERC-20 The address of the token contract
   */
  function recoverTokenInternal(address token, address sendTo) external {
    IERC20 erc20 = IERC20(token);

    uint256 balance = erc20.balanceOf(address(this));

    if (balance > 0) {
      // slither-disable-next-line unchecked-transfer
      erc20.safeTransfer(sendTo, balance);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] calldata v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function setAddressArrayItem(bytes32 k, address v) external;

  function setBytes32ArrayItem(bytes32 k, bytes32 v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function deleteAddressArrayItem(bytes32 k, address v) external;

  function deleteBytes32ArrayItem(bytes32 k, bytes32 v) external;

  function deleteAddressArrayItemByIndex(bytes32 k, uint256 i) external;

  function deleteBytes32ArrayItemByIndex(bytes32 k, uint256 i) external;

  function getAddressValues(bytes32[] calldata keys) external view returns (address[] memory values);

  function getAddress(bytes32 k) external view returns (address);

  function getAddressBoolean(bytes32 k, address a) external view returns (bool);

  function getUintValues(bytes32[] calldata keys) external view returns (uint256[] memory values);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);

  function countAddressArrayItems(bytes32 k) external view returns (uint256);

  function countBytes32ArrayItems(bytes32 k) external view returns (uint256);

  function getAddressArray(bytes32 k) external view returns (address[] memory);

  function getBytes32Array(bytes32 k) external view returns (bytes32[] memory);

  function getAddressArrayItemPosition(bytes32 k, address toFind) external view returns (uint256);

  function getBytes32ArrayItemPosition(bytes32 k, bytes32 toFind) external view returns (uint256);

  function getAddressArrayItemByIndex(bytes32 k, uint256 i) external view returns (address);

  function getBytes32ArrayItemByIndex(bytes32 k, uint256 i) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";

library AccessControlLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  bytes32 public constant NS_ROLES_ADMIN = 0x00; // SAME AS "DEFAULT_ADMIN_ROLE"
  bytes32 public constant NS_ROLES_COVER_MANAGER = "role:cover:manager";
  bytes32 public constant NS_ROLES_LIQUIDITY_MANAGER = "role:liquidity:manager";
  bytes32 public constant NS_ROLES_GOVERNANCE_AGENT = "role:governance:agent";
  bytes32 public constant NS_ROLES_GOVERNANCE_ADMIN = "role:governance:admin";
  bytes32 public constant NS_ROLES_UPGRADE_AGENT = "role:upgrade:agent";
  bytes32 public constant NS_ROLES_RECOVERY_AGENT = "role:recovery:agent";
  bytes32 public constant NS_ROLES_PAUSE_AGENT = "role:pause:agent";
  bytes32 public constant NS_ROLES_UNPAUSE_AGENT = "role:unpause:agent";

  /**
   * @dev Reverts if the sender is not the protocol admin.
   */
  function mustBeAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_ADMIN, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function mustBeCoverManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_COVER_MANAGER, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the liquidity manager.
   */
  function mustBeLiquidityManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_LIQUIDITY_MANAGER, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a governance agent.
   */
  function mustBeGovernanceAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a governance admin.
   */
  function mustBeGovernanceAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_ADMIN, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not an upgrade agent.
   */
  function mustBeUpgradeAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UPGRADE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a recovery agent.
   */
  function mustBeRecoveryAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_RECOVERY_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the pause agent.
   */
  function mustBePauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_PAUSE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the unpause agent.
   */
  function mustBeUnpauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UNPAUSE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the protocol admin.
   */
  function callerMustBeAdmin(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_ADMIN, caller);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function callerMustBeCoverManager(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_COVER_MANAGER, caller);
  }

  /**
   * @dev Reverts if the sender is not the liquidity manager.
   */
  function callerMustBeLiquidityManager(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_LIQUIDITY_MANAGER, caller);
  }

  /**
   * @dev Reverts if the sender is not a governance agent.
   */
  function callerMustBeGovernanceAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not a governance admin.
   */
  function callerMustBeGovernanceAdmin(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_ADMIN, caller);
  }

  /**
   * @dev Reverts if the sender is not an upgrade agent.
   */
  function callerMustBeUpgradeAgent(IStore s, address caller) public view {
    _mustHaveAccess(s, NS_ROLES_UPGRADE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not a recovery agent.
   */
  function callerMustBeRecoveryAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_RECOVERY_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not the pause agent.
   */
  function callerMustBePauseAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_PAUSE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not the unpause agent.
   */
  function callerMustBeUnpauseAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_UNPAUSE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender does not have access to the given role.
   */
  function _mustHaveAccess(
    IStore s,
    bytes32 role,
    address caller
  ) private view {
    require(hasAccess(s, role, caller), "Forbidden");
  }

  /**
   * @dev Checks if a given user has access to the given role
   * @param role Specify the role name
   * @param user Enter the user account
   * @return Returns true if the user is a member of the specified role
   */
  function hasAccess(
    IStore s,
    bytes32 role,
    address user
  ) public view returns (bool) {
    address protocol = s.getProtocolAddress();

    // The protocol is not deployed yet. Therefore, no role to check
    if (protocol == address(0)) {
      return false;
    }

    // You must have the same role in the protocol contract if you're don't have this role here
    return IAccessControl(protocol).hasRole(role, user);
  }

  /**
   * @dev Adds a protocol member contract
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param s Enter the store instance
   * @param namespace Enter the contract namespace
   * @param key Enter the contract key
   * @param contractAddress Enter the contract address
   */
  function addContractInternal(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));
    _addContract(s, namespace, key, contractAddress);
  }

  function _addContract(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) private {
    if (key > 0) {
      s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, key, contractAddress);
    } else {
      s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, contractAddress);
    }
    _addMember(s, contractAddress);
  }

  function _deleteContract(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) private {
    if (key > 0) {
      s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, key);
    } else {
      s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace);
    }
    _removeMember(s, contractAddress);
  }

  /**
   * @dev Upgrades a contract at the given namespace and key.
   *
   * The previous contract's protocol membership is revoked and
   * the current immediately starts assuming responsbility of
   * whatever the contract needs to do at the supplied namespace and key.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param s Provide store instance
   * @param namespace Enter a unique namespace for this contract
   * @param key Enter a key if this contract has siblings
   * @param previous Enter the existing contract address at this namespace and key.
   * @param current Enter the contract address which will replace the previous contract.
   */
  function upgradeContractInternal(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address previous,
    address current
  ) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    bool isMember = s.isProtocolMember(previous);
    require(isMember, "Not a protocol member");

    _deleteContract(s, namespace, key, previous);
    _addContract(s, namespace, key, current);
  }

  /**
   * @dev Adds member to the protocol
   *
   * A member is a trusted EOA or a contract that was added to the protocol using `addContract`
   * function. When a contract is removed using `upgradeContract` function, the membership of previous
   * contract is also removed.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param member Enter an address to add as a protocol member
   */
  function addMemberInternal(IStore s, address member) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    _addMember(s, member);
  }

  /**
   * @dev Removes a member from the protocol. This function is only accessible
   * to an upgrade agent.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param member Enter an address to remove as a protocol member
   */
  function removeMemberInternal(IStore s, address member) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    _removeMember(s, member);
  }

  function _addMember(IStore s, address member) private {
    require(s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, member) == false, "Already exists");
    s.setBoolByKeys(ProtoUtilV1.NS_MEMBERS, member, true);
  }

  function _removeMember(IStore s, address member) private {
    s.deleteBoolByKeys(ProtoUtilV1.NS_MEMBERS, member);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./IMember.sol";

interface IProtocol is IMember, IAccessControl {
  struct AccountWithRoles {
    address account;
    bytes32[] roles;
  }

  event ContractAdded(bytes32 indexed namespace, bytes32 indexed key, address indexed contractAddress);
  event ContractUpgraded(bytes32 indexed namespace, bytes32 indexed key, address previous, address indexed current);
  event MemberAdded(address member);
  event MemberRemoved(address member);

  function addContract(bytes32 namespace, address contractAddress) external;

  function addContractWithKey(
    bytes32 namespace,
    bytes32 coverKey,
    address contractAddress
  ) external;

  function initialize(address[] calldata addresses, uint256[] calldata values) external;

  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external;

  function upgradeContractWithKey(
    bytes32 namespace,
    bytes32 coverKey,
    address previous,
    address current
  ) external;

  function addMember(address member) external;

  function removeMember(address member) external;

  function grantRoles(AccountWithRoles[] calldata detail) external;

  event Initialized(address[] addresses, uint256[] values);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPausable {
  function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface ICxToken is IERC20 {
  function mint(
    bytes32 coverKey,
    bytes32 productKey,
    address to,
    uint256 amount
  ) external;

  function burn(uint256 amount) external;

  function createdOn() external view returns (uint256);

  function expiresOn() external view returns (uint256);

  // slither-disable-next-line naming-convention
  function COVER_KEY() external view returns (bytes32); // solhint-disable

  // slither-disable-next-line naming-convention
  function PRODUCT_KEY() external view returns (bytes32); // solhint-disable

  function getCoverageStartsFrom(address account, uint256 date) external view returns (uint256);

  function getClaimablePolicyOf(address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function mint(uint256 amount) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMember {
  /**
   * @dev Version number of this contract
   */
  function version() external pure returns (bytes32);

  /**
   * @dev Name of this contract
   */
  function getName() external pure returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICover is IMember {
  event CoverCreated(bytes32 indexed coverKey, bytes32 info, string tokenName, string tokenSymbol, bool indexed supportsProducts, bool indexed requiresWhitelist);
  event ProductCreated(bytes32 indexed coverKey, bytes32 productKey, bytes32 info, bool requiresWhitelist, uint256[] values);
  event CoverUpdated(bytes32 indexed coverKey, bytes32 info);
  event ProductUpdated(bytes32 indexed coverKey, bytes32 productKey, bytes32 info, uint256[] values);
  event ProductStateUpdated(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed stoppedBy, bool status, string reason);
  event VaultDeployed(bytes32 indexed coverKey, address vault);

  event CoverCreatorWhitelistUpdated(address account, bool status);
  event CoverUserWhitelistUpdated(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed account, bool status);
  event CoverCreationFeeSet(uint256 previous, uint256 current);
  event MinCoverCreationStakeSet(uint256 previous, uint256 current);
  event MinStakeToAddLiquiditySet(uint256 previous, uint256 current);
  event CoverInitialized(address indexed stablecoin, bytes32 withName);

  /**
   * @dev Initializes this contract
   * @param stablecoin Provide the address of the token this cover will be quoted against.
   * @param friendlyName Enter a description or ENS name of your liquidity token.
   *
   */
  function initialize(address stablecoin, bytes32 friendlyName) external;

  /**
   * @dev Adds a new coverage pool or cover contract.
   * To add a new cover, you need to pay cover creation fee
   * and stake minimum amount of NPM in the Vault. <br /> <br />
   *
   * Through the governance portal, projects will be able redeem
   * the full cover fee at a later date. <br /> <br />
   *
   * **Apply for Fee Redemption** <br />
   * https://docs.neptunemutual.com/covers/cover-fee-redemption <br /><br />
   *
   * As the cover creator, you will earn a portion of all cover fees
   * generated in this pool. <br /> <br />
   *
   * Read the documentation to learn more about the fees: <br />
   * https://docs.neptunemutual.com/covers/contract-creators
   *
   * @param coverKey Enter a unique key for this cover
   * @param info IPFS info of the cover contract
   * @param values[0] stakeWithFee Enter the total NPM amount (stake + fee) to transfer to this contract.
   * @param values[1] initialReassuranceAmount **Optional.** Enter the initial amount of
   * @param values[2] minStakeToReport A cover creator can override default min NPM stake to avoid spam reports
   * @param values[3] reportingPeriod The period during when reporting happens.
   * reassurance tokens you'd like to add to this pool.
   * @param values[4] cooldownperiod Enter the cooldown period for governance.
   * @param values[5] claimPeriod Enter the claim period.
   * @param values[6] floor Enter the policy floor rate.
   * @param values[7] ceiling Enter the policy ceiling rate.
   */
  function addCover(
    bytes32 coverKey,
    bytes32 info,
    string calldata tokenName,
    string calldata tokenSymbol,
    bool supportsProducts,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external returns (address);

  function addProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external;

  function updateProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256[] calldata values
  ) external;

  /**
   * @dev Updates the cover contract.
   * This feature is accessible only to the cover owner or protocol owner (governance).
   *
   * @param coverKey Enter the cover key
   * @param info Enter a new IPFS URL to update
   */
  function updateCover(bytes32 coverKey, bytes32 info) external;

  function updateCoverCreatorWhitelist(address account, bool whitelisted) external;

  function updateCoverUsersWhitelist(
    bytes32 coverKey,
    bytes32 productKey,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external;

  function disablePolicy(
    bytes32 coverKey,
    bytes32 productKey,
    bool status,
    string calldata reason
  ) external;

  function checkIfWhitelistedCoverCreator(address account) external view returns (bool);

  function checkIfWhitelistedUser(
    bytes32 coverKey,
    bytes32 productKey,
    address account
  ) external view returns (bool);

  function setCoverCreationFee(uint256 value) external;

  function setMinCoverCreationStake(uint256 value) external;

  function setMinStakeToAddLiquidity(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IPolicy is IMember {
  event CoverPurchased(
    bytes32 coverKey,
    bytes32 productKey,
    address onBehalfOf,
    address indexed cxToken,
    uint256 fee,
    uint256 platformFee,
    uint256 amountToCover,
    uint256 expiresOn,
    bytes32 indexed referralCode,
    uint256 policyId
  );

  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you receive equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   * @param onBehalfOf Enter an address you would like to send the claim tokens (cxTokens) to.
   * @param coverKey Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   */
  function purchaseCover(
    address onBehalfOf,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover,
    bytes32 referralCode
  ) external returns (address, uint256);

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   */
  function getCoverFeeInfo(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    );

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] Reassurance amount
   * @param _values[3] Reassurance pool weight
   * @param _values[4] Count of products under this cover
   * @param _values[5] Leverage
   * @param _values[6] Cover product efficiency weight
   */
  function getCoverPoolSummary(bytes32 coverKey, bytes32 productKey) external view returns (uint256[] memory _values);

  function getCxToken(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration
  ) external view returns (address cxToken, uint256 expiryDate);

  function getCxTokenByExpiryDate(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiryDate
  ) external view returns (address cxToken);

  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getAvailableLiquidity(bytes32 coverKey) external view returns (uint256);

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IBondPool is IMember {
  event BondPoolSetup(address[] addresses, uint256[] values);
  event BondCreated(address indexed account, uint256 lpTokens, uint256 npmToVest, uint256 unlockDate);
  event BondClaimed(address indexed account, uint256 amount);

  function setup(address[] calldata addresses, uint256[] calldata values) external;

  function createBond(uint256 lpTokens, uint256 minNpmDesired) external;

  function claimBond() external;

  function getNpmMarketPrice() external view returns (uint256);

  function calculateTokensForLp(uint256 lpTokens) external view returns (uint256);

  function getInfo(address forAccount) external view returns (address[] calldata addresses, uint256[] calldata values);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  event StakeAdded(bytes32 indexed coverKey, address indexed account, uint256 amount);
  event StakeRemoved(bytes32 indexed coverKey, address indexed account, uint256 amount);
  event FeeBurned(bytes32 indexed coverKey, uint256 amount);

  /**
   * @dev Increase the stake of the given cover pool
   * @param coverKey Enter the cover key
   * @param account Enter the account from where the NPM tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   */
  function increaseStake(
    bytes32 coverKey,
    address account,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @dev Decreases the stake from the given cover pool
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of stake to decrease
   */
  function decreaseStake(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param coverKey Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   */
  function stakeOf(bytes32 coverKey, address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface ICxTokenFactory is IMember {
  event CxTokenDeployed(bytes32 indexed coverKey, bytes32 indexed productKey, address cxToken, uint256 expiryDate);

  function deploy(
    bytes32 coverKey,
    bytes32 productKey,
    string calldata tokenName,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICoverReassurance is IMember {
  event ReassuranceAdded(bytes32 indexed coverKey, uint256 amount);
  event WeightSet(bytes32 indexed coverKey, uint256 weight);
  event PoolCapitalized(bytes32 indexed coverKey, bytes32 indexed productKey, uint256 indexed incidentDate, uint256 amount);

  /**
   * @dev Adds reassurance to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addReassurance(
    bytes32 coverKey,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 coverKey, uint256 weight) external;

  function capitalizePool(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param coverKey Enter the cover key
   */
  function getReassurance(bytes32 coverKey) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  event VaultDeployed(bytes32 indexed coverKey, address vault);

  function deploy(
    bytes32 coverKey,
    string calldata name,
    string calldata symbol
  ) external returns (address);
}

/* solhint-disable var-name-mixedcase, private-vars-leading-underscore, reason-string */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 internal constant SECONDS_PER_HOUR = 60 * 60;
  uint256 internal constant SECONDS_PER_MINUTE = 60;
  int256 internal constant OFFSET19700101 = 2440588;

  uint256 internal constant DOW_MON = 1;
  uint256 internal constant DOW_TUE = 2;
  uint256 internal constant DOW_WED = 3;
  uint256 internal constant DOW_THU = 4;
  uint256 internal constant DOW_FRI = 5;
  uint256 internal constant DOW_SAT = 6;
  uint256 internal constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";
import "./RegistryLibV1.sol";

library StrategyLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using RegistryLibV1 for IStore;

  uint256 public constant DEFAULT_LENDING_PERIOD = 180 days;
  uint256 public constant DEFAULT_WITHDRAWAL_WINDOW = 7 days;

  event StrategyAdded(address indexed strategy);
  event RiskPoolingPeriodSet(bytes32 indexed key, uint256 lendingPeriod, uint256 withdrawalWindow);
  event MaxLendingRatioSet(uint256 ratio);

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function _getIsDisabledStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, strategyAddress));
  }

  /**
   * @dev Disables a strategy
   *
   * @custom:suppress-address-trust-issue The address `toFind` can be trusted since we are not treating it like a contract.
   *
   */
  function disableStrategyInternal(IStore s, address toFind) external {
    _disableStrategy(s, toFind);

    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, toFind);
  }

  /**
   * @dev Deletes a strategy
   *
   * @custom:suppress-address-trust-issue The address `toFind` can be trusted since we are not treating it like a contract.
   *
   */
  function deleteStrategyInternal(IStore s, address toFind) external {
    _deleteStrategy(s, toFind);
  }

  function addStrategiesInternal(IStore s, address[] calldata strategies) external {
    for (uint256 i = 0; i < strategies.length; i++) {
      address strategy = strategies[i];
      _addStrategy(s, strategy);
    }
  }

  function getRiskPoolingPeriodsInternal(IStore s, bytes32 coverKey) external view returns (uint256 lendingPeriod, uint256 withdrawalWindow) {
    lendingPeriod = s.getUintByKey(getLendingPeriodKey(coverKey));
    withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(coverKey));

    if (lendingPeriod == 0) {
      lendingPeriod = s.getUintByKey(getLendingPeriodKey(0));
      withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(0));
    }

    lendingPeriod = lendingPeriod == 0 ? DEFAULT_LENDING_PERIOD : lendingPeriod;
    withdrawalWindow = withdrawalWindow == 0 ? DEFAULT_WITHDRAWAL_WINDOW : withdrawalWindow;
  }

  function setRiskPoolingPeriodsInternal(
    IStore s,
    bytes32 coverKey,
    uint256 lendingPeriod,
    uint256 withdrawalWindow
  ) external {
    s.setUintByKey(getLendingPeriodKey(coverKey), lendingPeriod);
    s.setUintByKey(getWithdrawalWindowKey(coverKey), withdrawalWindow);

    emit RiskPoolingPeriodSet(coverKey, lendingPeriod, withdrawalWindow);
  }

  function getLendingPeriodKey(bytes32 coverKey) public pure returns (bytes32) {
    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD;
  }

  function getMaxLendingRatioInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(getMaxLendingRatioKey());
  }

  function setMaxLendingRatioInternal(IStore s, uint256 ratio) external {
    s.setUintByKey(getMaxLendingRatioKey(), ratio);

    emit MaxLendingRatioSet(ratio);
  }

  function getMaxLendingRatioKey() public pure returns (bytes32) {
    return ProtoUtilV1.NS_COVER_LIQUIDITY_MAX_LENDING_RATIO;
  }

  function getWithdrawalWindowKey(bytes32 coverKey) public pure returns (bytes32) {
    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW;
  }

  function _addStrategy(IStore s, address deployedOn) private {
    ILendingStrategy strategy = ILendingStrategy(deployedOn);
    require(strategy.getWeight() <= ProtoUtilV1.MULTIPLIER, "Weight too much");

    s.setBoolByKey(_getIsActiveStrategyKey(deployedOn), true);
    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, deployedOn);
    emit StrategyAdded(deployedOn);
  }

  function _disableStrategy(IStore s, address toFind) private {
    bytes32 key = ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE;

    uint256 pos = s.getAddressArrayItemPosition(key, toFind);
    require(pos > 0, "Invalid strategy");

    s.deleteAddressArrayItem(key, toFind);
    s.setBoolByKey(_getIsActiveStrategyKey(toFind), false);
    s.setBoolByKey(_getIsDisabledStrategyKey(toFind), true);
  }

  function _deleteStrategy(IStore s, address toFind) private {
    bytes32 key = ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED;

    uint256 pos = s.getAddressArrayItemPosition(key, toFind);
    require(pos > 0, "Invalid strategy");

    s.deleteAddressArrayItem(key, toFind);
    s.setBoolByKey(_getIsDisabledStrategyKey(toFind), false);
  }

  function getDisabledStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED);
  }

  function getActiveStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE);
  }

  function getStrategyOutKey(bytes32 coverKey, address token) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_STRATEGY_OUT, coverKey, token));
  }

  function getSpecificStrategyOutKey(
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_STRATEGY_OUT, coverKey, strategyName, token));
  }

  function getAmountInStrategies(
    IStore s,
    bytes32 coverKey,
    address token
  ) public view returns (uint256) {
    bytes32 k = getStrategyOutKey(coverKey, token);
    return s.getUintByKey(k);
  }

  function getAmountInStrategy(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) public view returns (uint256) {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    return s.getUintByKey(k);
  }

  function preTransferToStrategyInternal(
    IStore s,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external {
    if (s.getStablecoin() == address(token) == false) {
      return;
    }

    _addToStrategyOut(s, coverKey, address(token), amount);
    _addToSpecificStrategyOut(s, coverKey, strategyName, address(token), amount);
  }

  function postReceiveFromStrategyInternal(
    IStore s,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 received
  ) external returns (uint256 income, uint256 loss) {
    if (s.getStablecoin() == address(token) == false) {
      return (income, loss);
    }

    uint256 amountInThisStrategy = getAmountInStrategy(s, coverKey, strategyName, address(token));

    income = received > amountInThisStrategy ? received - amountInThisStrategy : 0;
    loss = received < amountInThisStrategy ? amountInThisStrategy - received : 0;

    _reduceStrategyOut(s, coverKey, address(token), amountInThisStrategy);
    _clearSpecificStrategyOut(s, coverKey, strategyName, address(token));

    _logIncomes(s, coverKey, strategyName, income, loss);
  }

  function _addToStrategyOut(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amountToAdd
  ) private {
    bytes32 k = getStrategyOutKey(coverKey, token);
    s.addUintByKey(k, amountToAdd);
  }

  function _reduceStrategyOut(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amount
  ) private {
    bytes32 k = getStrategyOutKey(coverKey, token);
    s.subtractUintByKey(k, amount);
  }

  function _addToSpecificStrategyOut(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token,
    uint256 amountToAdd
  ) private {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    s.addUintByKey(k, amountToAdd);
  }

  function _clearSpecificStrategyOut(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) private {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    s.deleteUintByKey(k);
  }

  function _logIncomes(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 income,
    uint256 loss
  ) private {
    // Overall Income
    s.addUintByKey(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, income);

    // By Cover
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, coverKey)), income);

    // By Cover on This Strategy
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, coverKey, strategyName)), income);

    // Overall Loss
    s.addUintByKey(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, loss);

    // By Cover
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, coverKey)), loss);

    // By Cover on This Strategy
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, coverKey, strategyName)), loss);
  }

  function getStablecoinOwnedByVaultInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    address stablecoin = s.getStablecoin();

    uint256 balance = IERC20(stablecoin).balanceOf(s.getVaultAddress(coverKey));
    uint256 inStrategies = getAmountInStrategies(s, coverKey, stablecoin);

    return balance + inStrategies;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

pragma solidity ^0.8.0;

interface ILendingStrategy is IMember {
  event LogDeposit(bytes32 indexed name, uint256 counter, uint256 amount, uint256 certificateReceived, uint256 depositTotal, uint256 withdrawalTotal);
  event Deposited(bytes32 indexed key, address indexed onBehalfOf, uint256 stablecoinDeposited, uint256 certificateTokenIssued);
  event LogWithdrawal(bytes32 indexed name, uint256 counter, uint256 stablecoinWithdrawn, uint256 certificateRedeemed, uint256 depositTotal, uint256 withdrawalTotal);
  event Withdrawn(bytes32 indexed key, address indexed sendTo, uint256 stablecoinWithdrawn, uint256 certificateTokenRedeemed);
  event Drained(IERC20 indexed asset, uint256 amount);

  function getKey() external pure returns (bytes32);

  function getWeight() external pure returns (uint256);

  function getDepositAsset() external view returns (IERC20);

  function getDepositCertificate() external view returns (IERC20);

  /**
   * @dev Gets info of this strategy by cover key
   * @param coverKey Enter the cover key
   * @param values[0] deposits Total amount deposited
   * @param values[1] withdrawals Total amount withdrawn
   */
  function getInfo(bytes32 coverKey) external view returns (uint256[] memory values);

  function deposit(bytes32 coverKey, uint256 amount) external returns (uint256 certificateReceived);

  function withdraw(bytes32 coverKey) external returns (uint256 stablecoinWithdrawn);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPriceOracle.sol";
import "../dependencies/uniswap-v2/IUniswapV2RouterLike.sol";
import "../dependencies/uniswap-v2/IUniswapV2PairLike.sol";
import "../dependencies/uniswap-v2/IUniswapV2FactoryLike.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";

library PriceLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getPriceOracleInternal(IStore s) public view returns (IPriceOracle) {
    return IPriceOracle(s.getNpmPriceOracle());
  }

  function setNpmPrice(IStore s) internal {
    getPriceOracleInternal(s).update();
  }

  function convertNpmLpUnitsToStabelcoin(IStore s, uint256 amountIn) external view returns (uint256) {
    return getPriceOracleInternal(s).consultPair(amountIn);
  }

  function getLastUpdatedOnInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    bytes32 key = getLastUpdateKey(coverKey);
    return s.getUintByKey(key);
  }

  function setLastUpdatedOn(IStore s, bytes32 coverKey) external {
    bytes32 key = getLastUpdateKey(coverKey);
    s.setUintByKey(key, block.timestamp); // solhint-disable-line
  }

  function getLastUpdateKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LAST_LIQUIDITY_STATE_UPDATE, coverKey));
  }

  function getNpmPriceInternal(IStore s, uint256 amountIn) external view returns (uint256) {
    return getPriceOracleInternal(s).consult(s.getNpmTokenAddress(), amountIn);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPriceOracle {
  function update() external;

  function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

  function consultPair(uint256 amountIn) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2RouterLike {
  function factory() external view returns (address);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2PairLike {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2FactoryLike {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";
import "./CoverUtilV1.sol";
import "./RegistryLibV1.sol";
import "./StrategyLibV1.sol";
import "./ValidationLibV1.sol";

library RoutineInvokerLibV1 {
  using PriceLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;

  enum Action {
    Deposit,
    Withdraw
  }

  function updateStateAndLiquidity(IStore s, bytes32 coverKey) external {
    _invoke(s, coverKey);
  }

  function _invoke(IStore s, bytes32 coverKey) private {
    // solhint-disable-next-line
    if (s.getLastUpdatedOnInternal(coverKey) + _getUpdateInterval(s) > block.timestamp) {
      return;
    }

    PriceLibV1.setNpmPrice(s);

    if (coverKey > 0) {
      _updateWithdrawalPeriod(s, coverKey);
      _invokeAssetManagement(s, coverKey);
      s.setLastUpdatedOn(coverKey);
    }
  }

  function _getUpdateInterval(IStore s) private view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_LIQUIDITY_STATE_UPDATE_INTERVAL);
  }

  function getWithdrawalInfoInternal(IStore s, bytes32 coverKey)
    public
    view
    returns (
      bool isWithdrawalPeriod,
      uint256 lendingPeriod,
      uint256 withdrawalWindow,
      uint256 start,
      uint256 end
    )
  {
    (lendingPeriod, withdrawalWindow) = s.getRiskPoolingPeriodsInternal(coverKey);

    // Get the withdrawal period of this cover liquidity
    start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    // solhint-disable-next-line
    if (block.timestamp >= start && block.timestamp <= end) {
      isWithdrawalPeriod = true;
    }
  }

  function _isWithdrawalPeriod(IStore s, bytes32 coverKey) private view returns (bool) {
    (bool isWithdrawalPeriod, , , , ) = getWithdrawalInfoInternal(s, coverKey);
    return isWithdrawalPeriod;
  }

  function _updateWithdrawalPeriod(IStore s, bytes32 coverKey) private {
    (, uint256 lendingPeriod, uint256 withdrawalWindow, uint256 start, uint256 end) = getWithdrawalInfoInternal(s, coverKey);

    // Without a lending period and withdrawal window, nothing can be updated
    if (lendingPeriod == 0 || withdrawalWindow == 0) {
      return;
    }

    // The withdrawal period is now over.
    // Deposits can be performed again.
    // Set the next withdrawal cycle
    if (block.timestamp > end) {
      // solhint-disable-previous-line

      // Next Withdrawal Cycle

      // Withdrawals can start after the lending period
      start = block.timestamp + lendingPeriod; // solhint-disable
      // Withdrawals can be performed until the end of the next withdrawal cycle
      end = start + withdrawalWindow;

      s.setUintByKey(getNextWithdrawalStartKey(coverKey), start);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), end);
      setAccrualCompleteInternal(s, coverKey, false);
    }
  }

  function isAccrualCompleteInternal(IStore s, bytes32 coverKey) external view returns (bool) {
    return s.getBoolByKey(getAccrualInvocationKey(coverKey));
  }

  function setAccrualCompleteInternal(
    IStore s,
    bytes32 coverKey,
    bool flag
  ) public {
    s.setBoolByKey(getAccrualInvocationKey(coverKey), flag);
  }

  function getAccrualInvocationKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_ACCRUAL_INVOCATION, coverKey));
  }

  function getNextWithdrawalStartKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_START, coverKey));
  }

  function getNextWithdrawalEndKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_END, coverKey));
  }

  function mustBeDuringWithdrawalPeriod(IStore s, bytes32 coverKey) external view {
    // Get the withdrawal period of this cover liquidity
    uint256 start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    uint256 end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    require(start > 0 && block.timestamp >= start, "Withdrawal period has not started");
    require(end > 0 && block.timestamp < end, "Withdrawal period has already ended");
  }

  function _executeAndGetAction(
    IStore s,
    ILendingStrategy,
    bytes32 coverKey
  ) private returns (Action) {
    // If the cover is undergoing reporting, withdraw everything
    bool isNormal = s.isCoverNormalInternal(coverKey);

    if (isNormal != true) {
      // Reset the withdrawal window
      s.setUintByKey(getNextWithdrawalStartKey(coverKey), 0);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), 0);

      return Action.Withdraw;
    }

    if (_isWithdrawalPeriod(s, coverKey) == true) {
      return Action.Withdraw;
    }

    return Action.Deposit;
  }

  function _canDeposit(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    bytes32 coverKey
  ) private view returns (uint256) {
    IERC20 stablecoin = IERC20(s.getStablecoin());

    uint256 totalBalance = s.getStablecoinOwnedByVaultInternal(coverKey);
    uint256 maximumAllowed = (totalBalance * s.getMaxLendingRatioInternal()) / ProtoUtilV1.MULTIPLIER;
    uint256 allocation = maximumAllowed / totalStrategies;
    uint256 weight = strategy.getWeight();
    uint256 canDeposit = (allocation * weight) / ProtoUtilV1.MULTIPLIER;
    uint256 alreadyDeposited = s.getAmountInStrategy(coverKey, strategy.getName(), address(stablecoin));

    if (alreadyDeposited >= canDeposit) {
      return 0;
    }

    return canDeposit - alreadyDeposited;
  }

  function _invokeAssetManagement(IStore s, bytes32 coverKey) private {
    address vault = s.getVaultAddress(coverKey);
    _withdrawFromDisabled(s, coverKey, vault);

    address[] memory strategies = s.getActiveStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      _executeStrategy(s, strategy, strategies.length, vault, coverKey);
    }
  }

  function _executeStrategy(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    address vault,
    bytes32 coverKey
  ) private {
    uint256 canDeposit = _canDeposit(s, strategy, totalStrategies, coverKey);
    uint256 balance = IERC20(s.getStablecoin()).balanceOf(vault);

    if (canDeposit > balance) {
      canDeposit = balance;
    }

    Action action = _executeAndGetAction(s, strategy, coverKey);

    if (action == Action.Deposit && canDeposit == 0) {
      return;
    }

    if (action == Action.Withdraw) {
      _withdrawAllFromStrategy(strategy, vault, coverKey);
      return;
    }

    _depositToStrategy(strategy, coverKey, canDeposit);
  }

  function _depositToStrategy(
    ILendingStrategy strategy,
    bytes32 coverKey,
    uint256 amount
  ) private {
    strategy.deposit(coverKey, amount);
  }

  function _withdrawAllFromStrategy(
    ILendingStrategy strategy,
    address vault,
    bytes32 coverKey
  ) private returns (uint256 stablecoinWithdrawn) {
    uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(vault);

    if (balance > 0) {
      stablecoinWithdrawn = strategy.withdraw(coverKey);
    }
  }

  function _withdrawFromDisabled(
    IStore s,
    bytes32 coverKey,
    address onBehalfOf
  ) private {
    address[] memory strategies = s.getDisabledStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(onBehalfOf);

      if (balance > 0) {
        strategy.withdraw(coverKey);
      }
    }
  }
}