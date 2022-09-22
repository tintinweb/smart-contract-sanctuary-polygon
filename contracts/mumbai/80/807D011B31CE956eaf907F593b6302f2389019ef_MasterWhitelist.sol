// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMasterWhitelist.sol";
import {IQuadPassport} from "../interfaces/IQuadPassport.sol";
import {IQuadReader} from "../interfaces/IQuadReader.sol";


/**
 * @title Master Whitelist
 * @notice Contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
contract MasterWhitelist is Ownable, IMasterWhitelist {
    uint256 investigation_period = 60 * 60 * 24 * 7; //7 days
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
     * @notice Whitelist for Pending Users
     */
    mapping(address => bool) pendingUsers;

    /**
     * @notice swap manager is in charge of initiating swaps
     */
    address public swapManager;

    /**
     * @notice KYCPassport contract,
     * @dev needs to be set after contract is deployed
     */
    IQuadPassport public KYCPassport;

    /**
     * @notice KYCReader contract,
     * @dev needs to be set after contract is deployed
     */
    IQuadReader public KYCReader;

    /**
     * @notice emits an event when an address is added to a whitelist
     * @param user is the address added to whitelist
     * @param userType can take values 0,1,2,3 if the address is a user, market maker, vault or lawyer respectively
     */
    event UserAddedToWhitelist(address indexed user, uint256 indexed userType);

        /**
     * @notice emits an event when an address is pending whitelist
     * @param user is the address added to pending
     */
    event UserAddedToPending(address indexed user);

    /**
     * @notice emits an event when an address is removed from the whitelist
     * @param user is the address removed from the whitelist
     * @param userType can take values 0,1,2,3 if the address is a user, market maker, vault or lawyer respectively
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

    event newInvestigationPeriod(uint256 oldPeriod, uint256 newPeriod);

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

    /**
     * @notice set swap manager
     * @param _sm is the swap manager address
     */
    function setSwapManager(address _sm) external onlyOwner {
        require(_sm != address(0), "swapManager shouldn't be zero");
        swapManager = _sm;
    }

    /**
     * @notice gets the swap manager
     */
    function getSwapManager() external view returns (address) {
        return swapManager;
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
        lawyers[_lawyer] = false;
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
        pendingUsers[_user] = false;
        delete blacklistedUsers[_user];
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Removes a User from the Whitelist
     * @param _user is the User address
     */
    function removeUserFromWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = false;
        emit userRemovedFromWhitelist(_user, 0);
    }

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool) {
        return whitelistedUsers[_user];
    }

    /**
     * @notice Adds a User to the pending whitelist
     * @param _user is the User address
     */
    function addUserToPending(address _user) external {
        pendingUsers[_user] = true;
        emit UserAddedToPending(_user);
    }

    /**
     * @notice Removes a User from the pending whitelist
     * @param _user is the User address
     */
    function removeUserFromPending(address _user) external onlyLawyer {
        pendingUsers[_user] = false;
    }

    /**
     * @notice Checks if a User is in the pending whitelist
     * @param _user is the User address
     */
    function isUserPending(address _user) external view returns (bool) {
        return pendingUsers[_user];
    }

    /**
     * @notice Blacklists user pending investigation
     * @param _user is the User address
     */
    function addUserToBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = block.timestamp + investigation_period;
        delete whitelistedUsers[_user];
        emit userAddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /**
     * @notice Blacklists user indefinitely after investigation
     * @param _user is the User address
     */
    function addUserToBlacklistIndefinitely(address _user) external onlyLawyer {
        blacklistedUsers[_user] = INF_TIME;
        delete whitelistedUsers[_user];
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
        whitelistedMMs[_mm] = false;
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
        whitelistedVaults[_vault] = false;
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
    }

    /**
     * @notice Removes an Asset from the Whitelist
     * @param _asset is the Asset address
     */
    function removeAssetFromWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = false;
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
    }

    /**
     * @notice Removes a Country from the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function removeCountryFromBlacklist(bytes32 _name) external onlyLawyer {
        blacklistedCountries[_name] = false;
    }

    /**
     * @notice Checks if a Country is in the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function isCountryBlacklisted(bytes32 _name) public view returns (bool) {
        return blacklistedCountries[_name];
    }

    /**
     * @notice Checks if a user has a kyc passport
     * @param _user is the Asset address
     */
    function hasPassport(address _user) public view returns (bool) {
        if (KYCPassport.balanceOf(_user, 1) == 1) {
            return true;
        }
        else {
            return false;
        }
    }

    /**
     * @notice users adds themselves to whitelist using the passport
     * @param _user is the user address
     */
    function addUserToWhitelistUsingPassport(address _user) external payable {
        require(hasPassport(_user) == true, "user has no KYC passport");
        require(!isUserBlacklisted(_user),"user is blacklisted");

        uint256 feeAML = checkFeeAML();
        uint256 feeCountry = checkFeeCountry();
        require(msg.value == feeAML + feeCountry,"fee is not correct");

        uint256 aml = uint256(KYCReader.getAttributes{value:feeAML}(
            _user, 0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119
        )[0].value);
        require(aml < 5,"AML score is too high");

        bytes32 country = KYCReader.getAttributes{value:feeCountry}(
            _user, 0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef
        )[0].value;
        require(!isCountryBlacklisted(country),"country is blacklisted");

        whitelistedUsers[_user] = true;
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Sets the address of the kyc passport
     * @param _kyc is the kyc passport address
     */
    function setKYCPassport(address _kyc) external onlyLawyer {
        KYCPassport = IQuadPassport(_kyc);
    }

    /**
     * @notice Sets the address of the kyc reader
     * @param _kyc is the kyc reader address
     */
    function setKYCReader(address _kyc) external onlyLawyer {
        KYCReader = IQuadReader(_kyc);
    }

    /**
     * @notice Returns the passport checking fee for AML score
     */
    function checkFeeAML() public view returns(uint256) {
        return KYCReader.queryFee(
            0x0000000000000000000000000000000000000000,
            0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119
        );
    }

    /**
     * @notice Returns the passport checking fee for Country
     */
    function checkFeeCountry() public view returns(uint256) {
        return KYCReader.queryFee(
            0x0000000000000000000000000000000000000000,
            0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef
        );
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

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IQuadPassport {
    function balanceOf(address account, uint256 id) external view virtual returns (uint256);
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

    function queryFee( address _account, bytes32 _attribute ) external view returns(uint256);

    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable returns(Attribute[] memory attributes);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}