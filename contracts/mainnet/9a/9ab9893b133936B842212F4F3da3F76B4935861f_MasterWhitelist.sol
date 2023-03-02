// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { IQuadPassport } from "../interfaces/IQuadPassport.sol";
import { IQuadReader } from "../interfaces/IQuadReader.sol";
import { IVerificationRegistry } from "../interfaces/IVerificationRegistry.sol";

/**
 * @title Master Whitelist
 * @notice Contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
contract MasterWhitelist is OwnableUpgradeable {
    uint256 investigation_period;
    uint256 constant INF_TIME = 32503680000; //year 3000

    /**
     * @notice Whitelist for lawyers, who are in charge of managing the other whitelists
     */
    mapping(address => bool) lawyers;

    /**
     * @notice Whitelist for Market Makers
     */
    mapping(address => bool) whitelistedMMs;

    /**
     * @notice maps Market Maker addresses to the MM they belong to
     */
    mapping(address => bytes32) idMM;

    /**
     * @notice Whitelist for Users
     */
    mapping(address => bool) whitelistedUsers;

    /**
     * @notice Blacklist for Users
     */
    mapping(address => uint256) blacklistedUsers;

    /**
     * @notice Blacklist for Countries
     */
    mapping(bytes32 => bool) blacklistedCountries;

    /**
     * @notice Whitelist for Vaults
     */
    mapping(address => bool) whitelistedVaults;

    /**
     * @notice Whitelist for Assets
     */
    mapping(address => bool) whitelistedAssets;

    /**
     * @notice Mapping of users to the kycProvider that whitelisted them
     */
    mapping(address => bytes32) kycProviders;

    /**
     * @notice whitelist for swap managers (in charge of initiating swaps)
     */
    mapping(address => bool) whitelistedSwapManagers;

    /**
     * @notice KYCPassport contract
     */
    IQuadPassport public KYCPassport;

    /**
     * @notice KYCReader contract
     */
    IQuadReader public KYCReader;

    /**
     * @notice KYCRegistry contract
     */
    IVerificationRegistry public KYCRegistry;

    //bytes32 code for Manual provider
    bytes32 constant PROV_CODE_MANUAL = keccak256("Manual");

    //bytes32 code for Quadrata provider
    bytes32 constant PROV_CODE_QUADRATA = keccak256("Quadrata");

    //bytes32 code for Verite provider
    bytes32 constant PROV_CODE_VERITE = keccak256("Verite");

    //bytes32 code for Risk
    bytes32 constant CODE_RISK =
        0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    //bytes32 code for Country
    bytes32 constant CODE_COUNTRY =
        0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;

    //No storage variables should be removed or modified since this is an upgradeable contract.
    //It is safe to add new ones as long as they are declared after the existing ones.

    /**
     * @notice emits an event when an address is added to a whitelist
     * @param user is the address added to whitelist
     * @param userType can take values 0,1,2,3 if the address is a user, market maker, vault or lawyer respectively
     */
    event UserAddedToWhitelist(address indexed user, uint256 indexed userType);

    /**
     * @notice emits an event when an address is removed from the whitelist
     * @param user is the address removed from the whitelist
     * @param userType can take values 0,1,2,3,4 if the address is a user, market maker, vault, lawyer, or swapManager respectively
     */
    event userRemovedFromWhitelist(
        address indexed user,
        uint256 indexed userType
    );

    /**
     * @notice emits an event when add mm  to the whitelist
     * @param user is the address added to the whitelist
     */
    event mmAddedToWhitelist(address indexed user, bytes32 indexed mmid);

    /**
     * @notice emits an event when an address is added to a blacklist
     * @param user is the address added to blacklisted
     * @param investigation_time is the time investigation period will end
     */
    event userAddedToBlacklist(
        address indexed user,
        uint256 investigation_time
    );

    /**
     * @notice emits an event when an address is removed from the blacklist
     * @param user is the address removed from the blacklist
     */
    event userRemovedFromBlacklist(address indexed user);

    event newInvestigationPeriod(uint256 indexed _oldPeriod, uint256 indexed _newPeriod);

    event KYCPassportChanged(address indexed _passport);

    event KYCReaderChanged(address indexed _reader);

    event KYCRegistryChanged(address indexed _registry);

    event CountryToBlacklistAdded(bytes32 indexed _country);

    event RemovedCountryFromBlacklist(bytes32 indexed _country);

    event IdMMChanged(address indexed _mm, bytes32 indexed _id);

    event AddedAssetToWhitelist(address indexed _asset);

    event RemovedAssetFromWhitelist(address indexed _asset);

    /**
     * @notice Requires that the transaction sender is a lawyer or owner (owner is automatically lawyer)
     */
    modifier onlyLawyer() {
        require(
            msg.sender == owner() || lawyers[msg.sender],
            "Lawyer: caller is not a lawyer"
        );
        _;
    }

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer for the whitelist
     * @param _passport is kyc passport address
     * @param _reader is kyc reader address
     * @param _registry is kyc registry address
     * @param _countryBlacklist is an array of the 2 letter country code hashed with keccak256 of blacklisted countries
     */
    function initialize(
        address _passport,
        address _reader,
        address _registry,
        bytes32[] memory _countryBlacklist
    ) external initializer {
        __Ownable_init();
        investigation_period = 60 * 60 * 24 * 7; //7 days
        KYCPassport = IQuadPassport(_passport);
        KYCReader = IQuadReader(_reader);
        KYCRegistry = IVerificationRegistry(_registry);
        for (uint256 i = 0; i < _countryBlacklist.length; ) {
            blacklistedCountries[_countryBlacklist[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds a Swap Manager to the Whitelist
     * @param _sm is the Swap Manager address
     */
    function addSwapManagerToWhitelist(address _sm) external onlyLawyer {
        whitelistedSwapManagers[_sm] = true;
        emit UserAddedToWhitelist(_sm, 4);
    }

    /**
     * @notice Removes a Swap Manager from the Whitelist
     * @param _sm is the Swap Manager address
     */
    function removeSwapManagerFromWhitelist(address _sm) external onlyLawyer {
        whitelistedSwapManagers[_sm] = false;
        emit userRemovedFromWhitelist(_sm, 4);
    }

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm)
        external
        view
        returns (bool)
    {
        return whitelistedSwapManagers[_sm];
    }

    /**
     * @notice modify investigation duration
     * @param _time is the investigation duration
     */
    function setInvestigationPeriod(uint256 _time) external onlyLawyer {
        emit newInvestigationPeriod(investigation_period, _time);
        investigation_period = _time;
    }

    /**
     * @notice gets the investigation duration
     */
    function getInvestigationPeriod() external view returns (uint256) {
        return investigation_period;
    }

    /**
     * @notice adds a lawyer to the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function addLawyer(address _lawyer) external onlyLawyer {
        lawyers[_lawyer] = true;
        emit UserAddedToWhitelist(_lawyer, 3);
    }

    /**
     * @notice removes a lawyer from the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function removeLawyer(address _lawyer) external onlyLawyer {
        delete lawyers[_lawyer];
        emit userRemovedFromWhitelist(_lawyer, 3);
    }

    /**
     * @notice verifies that the lawyer is whitelisted
     * @param _lawyer is the lawyer address
     */
    function isLawyer(address _lawyer) external view returns (bool) {
        return lawyers[_lawyer];
    }

    /**
     * @notice Adds a User to the Whitelist
     * @param _user is the User address
     */
    function addUserToWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_MANUAL;
        delete blacklistedUsers[_user];
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Adds a User to the Whitelist specifying the provider
     * @param _user is the User address
     * @param _provider is the keccak256 hash of the provider name
     */
    function addUserToWhitelistWithProvider(address _user, bytes32 _provider)
        external
        onlyLawyer
    {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = _provider;
        delete blacklistedUsers[_user];
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Removes a User from the Whitelist
     * @param _user is the User address
     */
    function removeUserFromWhitelist(address _user) external onlyLawyer {
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userRemovedFromWhitelist(_user, 0);
    }

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool) {
        if (kycProviders[_user] == PROV_CODE_VERITE) {
            return whitelistedUsers[_user] && KYCRegistry.isVerified(_user);
        }
        return whitelistedUsers[_user];
    }

    /**
     * @notice Blacklists user pending investigation
     * @param _user is the User address
     */
    function addUserToBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = block.timestamp + investigation_period;
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userAddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /**
     * @notice Blacklists user indefinitely after investigation
     * @param _user is the User address
     */
    function addUserToBlacklistIndefinitely(address _user) external onlyLawyer {
        blacklistedUsers[_user] = INF_TIME;
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userAddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /**
     * @notice Removes user from Blacklist after investigation
     * @param _user is the User address
     */
    function removeUserFromBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = 0;
        emit userRemovedFromBlacklist(_user);
    }

    /**
     * @notice Checks if user is blacklisted
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) public view returns (bool) {
        //slither-disable-next-line timestamp
        return block.timestamp < blacklistedUsers[_user];
    }

    /**
     * @notice Adds a Market Maker to the Whitelist
     * @param _mm is the Market Maker address
     */
    function addMMToWhitelist(address _mm) external onlyLawyer {
        whitelistedMMs[_mm] = true;
        emit UserAddedToWhitelist(_mm, 1);
    }

    /**
     * @notice Adds a Market Maker to the Whitelist
     * @param _mm is the Market Maker address
     */
    function addMMToWhitelistWithId(address _mm, bytes32 _id)
        external
        onlyLawyer
    {
        idMM[_mm] = _id;
        whitelistedMMs[_mm] = true;
        emit UserAddedToWhitelist(_mm, 1);
        emit mmAddedToWhitelist(_mm, _id);
    }

    /**
     * @notice Removes a Market Maker from the Whitelist
     * @param _mm is the Market Maker address
     */
    function removeMMFromWhitelist(address _mm) external onlyLawyer {
        delete whitelistedMMs[_mm];
        emit userRemovedFromWhitelist(_mm, 1);
    }

    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool) {
        return whitelistedMMs[_mm];
    }

    /**
     * @notice Adds a Vault to the Whitelist
     * @param _vault is the Vault address
     */
    function addVaultToWhitelist(address _vault) external onlyLawyer {
        whitelistedVaults[_vault] = true;
        emit UserAddedToWhitelist(_vault, 2);
    }

    /**
     * @notice Removes a Vault from the Whitelist
     * @param _vault is the Vault address
     */
    function removeVaultFromWhitelist(address _vault) external onlyLawyer {
        delete whitelistedVaults[_vault];
        emit userRemovedFromWhitelist(_vault, 2);
    }

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool) {
        return whitelistedVaults[_vault];
    }

    /**
     * @notice Adds an Asset to the Whitelist
     * @param _asset is the Asset address
     */
    function addAssetToWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = true;
        emit AddedAssetToWhitelist(_asset);
    }

    /**
     * @notice Removes an Asset from the Whitelist
     * @param _asset is the Asset address
     */
    function removeAssetFromWhitelist(address _asset) external onlyLawyer {
        delete whitelistedAssets[_asset];
        emit RemovedAssetFromWhitelist(_asset);
    }

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return whitelistedAssets[_asset];
    }

    /**
     * @notice Adds an id to a Market Maker address to identify a Market Maker by its address
     * @param _mm is the mm address
     * @param _id is the unique identifier of the market maker
     */
    function setIdMM(address _mm, bytes32 _id) external onlyLawyer {
        idMM[_mm] = _id;
        emit IdMMChanged(_mm, _id);
    }

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32) {
        return idMM[_mm];
    }

    /**
     * @notice Adds a Country to the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function addCountryToBlacklist(bytes32 _name) external onlyLawyer {
        blacklistedCountries[_name] = true;
        emit CountryToBlacklistAdded(_name);
    }

    /**
     * @notice Removes a Country from the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function removeCountryFromBlacklist(bytes32 _name) external onlyLawyer {
        delete blacklistedCountries[_name];
        emit RemovedCountryFromBlacklist(_name);
    }

    /**
     * @notice Checks if a Country is in the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function isCountryBlacklisted(bytes32 _name) public view returns (bool) {
        return blacklistedCountries[_name];
    }

    /**
     * @notice Checks the kyc Provider a user signed up with
     * @param _user is the User address
     */
    function checkKYCProvider(address _user) external view returns (bytes32) {
        return kycProviders[_user];
    }

    /**
     * @notice Checks if a user has a kyc passport
     * @param _user is the Asset address
     */
    function hasPassport(address _user) public view returns (bool) {
        return KYCReader.balanceOf(_user, CODE_RISK) >= 1;
    }

    /**
     * @notice users adds themselves to whitelist using the passport
     * @param _user is the user address
     */
    function addUserToWhitelistUsingPassport(address _user, bytes calldata _signature)
        external
        payable
    {
        require(_policiesSigned(_user, _signature), "user has not signed terms & conditions");
        require(hasPassport(_user), "user has no KYC passport");
        require(!isUserBlacklisted(_user), "user is blacklisted");

        uint256 feeRisk = checkFeeRisk();
        uint256 feeCountry = checkFeeCountry();
        require(msg.value == feeRisk + feeCountry, "fee is not correct");

        uint256 risk = uint256(
            KYCReader.getAttributes{value: feeRisk}(_user, CODE_RISK)[0].value
        );
        require(risk < 5, "Could not be whitelisted: 1");

        bytes32 country = KYCReader
        .getAttributes{value: feeCountry}(_user, CODE_COUNTRY)[0].value;
        require(!isCountryBlacklisted(country), "Could not be whitelisted: 2");

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_QUADRATA;
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice users adds themselves to whitelist using the registry
     * @param _user is the user address
     */
    function addUserToWhitelistUsingRegistry(address _user, bytes calldata _signature)
        external
    {
        require(_policiesSigned(_user, _signature), "user has not signed terms & conditions");
        require(!isUserBlacklisted(_user), "user is blacklisted");
        require(KYCRegistry.isVerified(_user), "user not verified in registry");

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_VERITE;
        emit UserAddedToWhitelist(_user, 0);
    }

    function _policiesSigned(address _user, bytes calldata _signature) private view returns (bool) {
        bytes32 hashedPolicies = keccak256(
            "By accessing and continuing to access the protocol you are agreeing to be bound by the terms and conditions shown in detail at www.trufin.io/policies"
        );
        bytes32 prefixedHashedPolicies = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedPolicies)
        );
        return SignatureChecker.isValidSignatureNow(
            _user,
            prefixedHashedPolicies,
            _signature
        );
    }

    /**
     * @notice Sets the address of the kyc passport
     * @param _kyc is the kyc passport address
     */
    function setKYCPassport(address _kyc) external onlyLawyer {
        KYCPassport = IQuadPassport(_kyc);
        emit KYCPassportChanged(_kyc);
    }

    /**
     * @notice Sets the address of the kyc reader
     * @param _kyc is the kyc reader address
     */
    function setKYCReader(address _kyc) external onlyLawyer {
        KYCReader = IQuadReader(_kyc);
        emit KYCReaderChanged(_kyc);
    }

    /**
     * @notice Sets the address of the kyc registry
     * @param _kyc is the kyc registry address
     */
    function setKYCRegistry(address _kyc) external onlyLawyer {
        KYCRegistry = IVerificationRegistry(_kyc);
        emit KYCRegistryChanged(_kyc);
    }

    /**
     * @notice Returns the passport checking fee for Risk score
     */
    function checkFeeRisk() public view returns (uint256) {
        return KYCReader.queryFee(address(0), CODE_RISK);
    }

    /**
     * @notice Returns the passport checking fee for Country
     */
    function checkFeeCountry() public view returns (uint256) {
        return KYCReader.queryFee(address(0), CODE_COUNTRY);
    }

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     */
    function isAllowed(
        address _user,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (whitelistedMMs[_user]) {
            return 0x19a05a7e;
        } else {
            return bytes4(0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IQuadPassport {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IQuadReader {
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    function queryFee(address _account, bytes32 _attribute)
        external
        view
        returns (uint256);

    function getAttributes(address _account, bytes32 _attribute)
        external
        payable
        returns (Attribute[] memory attributes);

    function balanceOf(address _account, bytes32 _attribute)
        external
        view 
        returns(uint256);
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IVerificationRegistry {
    function isVerified(address subject) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}