/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/IdManager/Interface/IIdManager.sol


pragma solidity ^0.8.17;

/**
 * @title IIdManager
 * @author Polytrade
 */
interface IIdManager {
    struct Organization {
        bytes32 polytradeId;
        address admin;
        address[] wallets;
        bool verified;
    }

    /**
     * @notice Emits when a polytrade Id is created for an organization
     * @param polytradeId is the Id assigned to an organization
     * @param orgAdminWallet is the organization's admin wallet's address
     */
    event IdCreated(bytes32 indexed polytradeId, address orgAdminWallet);

    /**
     * @notice Emits when an organization is verified
     * @param polytradeId is the Id assigned to an organization
     * @param verified is the verification status of the organization
     */
    event OrgVerified(bytes32 indexed polytradeId, bool verified);

    /**
     * @notice Emits when a wallet is added to an organization
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address
     */
    event WalletAdded(bytes32 indexed polytradeId, address wallet);

    /**
     * @notice Emits when a wallet is removed from an organization
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address
     */
    event WalletRemoved(bytes32 indexed polytradeId, address wallet);

    /**
     * @notice Emits when an organization transfers assigns a new admin
     * @param polytradeId is the Id assigned to an organization
     * @param oldAdmin is the wallet address of the old organization admin
     * @param newAdmin is the wallet address of the new organization admin
     */
    event OrgAdminTransferred(
        bytes32 indexed polytradeId,
        address oldAdmin,
        address newAdmin
    );

    /**
     * @notice Creates a polytrade Id for an organization
     * @dev Maps the polytrade Id generated from the system to an organization's admin wallet
     * @param polytradeId is the Id assigned to an organization
     * @param orgAdminWallet is the organization's admin wallet address
     * @param validKyc boolean value of organization's kyc status
     * Emits {IdCreated} event
     */
    function createId(
        bytes32 polytradeId,
        address orgAdminWallet,
        bool validKyc
    ) external;

    /**
     * @notice Adds a wallet address to an organization
     * @dev It gives a wallet the permission to be able to perform
     * transactions using the organization's polytrade id
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be added
     * Emits {WalletAdded} event
     */
    function addWallet(bytes32 polytradeId, address wallet) external;

    /**
     * @notice Removes a wallet address from an organization
     * @dev Removing it revokes its use of the organization's polytrade Id
     * from making transactions
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet to be removed
     * Emits {WalletRemoved} event
     */
    function removeWallet(bytes32 polytradeId, address wallet) external;

    /**
     * @notice Assigns a new wallet address for an organization's admin
     * @param polytradeId is the Id assigned to an organization
     * @param newAdmin is the wallet address to transfer ownership to
     * Emits {OrgAdminTransferred} event
     */
    function transferAdmin(bytes32 polytradeId, address newAdmin) external;

    /**
     * @dev returns the verification status of an organization
     * @param polytradeId is the Id assigned to an organization
     * @return boolean value representing the verification status
     */
    function isVerified(bytes32 polytradeId) external view returns (bool);

    /**
     * @dev returns the organization details from the organization struct
     * @param polytradeId is the Id assigned to an organization
     * @return struct returns organization struct details
     */
    function getOrgDetails(
        bytes32 polytradeId
    ) external view returns (Organization memory);

    /**
     * @dev returns whether a wallet belongs to an organization's admin
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be checked
     * @return bool true or false
     */
    function isAdminWallet(
        bytes32 polytradeId,
        address wallet
    ) external view returns (bool);

    /**
     * @dev returns whether a wallet belongs to an organization or not
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be checked
     * @return bool true or false
     */
    function isOrgWallet(
        bytes32 polytradeId,
        address wallet
    ) external view returns (bool);
}


// File contracts/IdManager/IdManager.sol


pragma solidity ^0.8.17;


/**
 * @title IdManager
 * @author Polytrade
 */
contract IdManager is IIdManager, Ownable {
    mapping(bytes32 => Organization) private _organizations;

    modifier isValidID(bytes32 id) {
        require(id != bytes32(0), "Invalid Id");
        _;
    }

    modifier isValidAddress(address wallet) {
        require(wallet != address(0), "Invalid address");
        _;
    }

    /**
     * @dev receives and stores organization's Polytrade ID
     * @param organizationId organization's Polytrade ID
     * @param orgAdminWallet organization's admin wallet
     * @param validKyc organization's KYC status
     */
    function createId(
        bytes32 organizationId,
        address orgAdminWallet,
        bool validKyc
    )
        external
        isValidID(organizationId)
        isValidAddress(orgAdminWallet)
        onlyOwner
    {
        require(
            _organizations[organizationId].polytradeId == 0,
            "Organization already exists"
        );
        require(validKyc, "Not Valid KYC");

        _organizations[organizationId].verified = validKyc;
        _organizations[organizationId].polytradeId = organizationId;
        _organizations[organizationId].admin = orgAdminWallet;
        _organizations[organizationId].wallets.push(orgAdminWallet);

        emit IdCreated(organizationId, orgAdminWallet);
    }

    /**
     * @notice Adds a wallet address to an organization
     * @dev It gives a wallet the permission to be able to perform
     * transactions using the organization's polytrade id
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be added
     * Emits {WalletAdded} event
     */
    function addWallet(
        bytes32 polytradeId,
        address wallet
    ) external isValidID(polytradeId) isValidAddress(wallet) onlyOwner {
        require(
            _organizations[polytradeId].polytradeId != bytes32(0),
            "Organization does not exist"
        );
        bool orgWallet = _isOrgWallet(polytradeId, wallet);
        require(!orgWallet, "Wallet already added");
        _organizations[polytradeId].wallets.push(wallet);

        emit WalletAdded(polytradeId, wallet);
    }

    /**
     * @notice Removes a wallet address from an organization
     * @dev Removing it revokes its use of the organization's polytrade Id
     * from making transactions
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet to be removed
     * Emits {WalletRemoved} event
     */
    function removeWallet(
        bytes32 polytradeId,
        address wallet
    ) external isValidID(polytradeId) onlyOwner {
        require(
            _organizations[polytradeId].polytradeId != bytes32(0),
            "Organization does not exist"
        );
        Organization storage organization = _organizations[polytradeId];
        bool orgWallet = _isOrgWallet(polytradeId, wallet);
        require(wallet != organization.admin, "Cannot remove admin wallet");
        require(orgWallet, "Wallet not part of organization");
        address[] storage wallets = organization.wallets;

        for (uint256 i = 0; i < wallets.length - 1; i++) {
            if (wallets[i] == wallet) wallets[i] = wallets[wallets.length - 1];
        }
        wallets.pop();

        emit WalletRemoved(polytradeId, wallet);
    }

    /**
     * @notice Assigns a new wallet address for an organization's admin
     * @param polytradeId is the Id assigned to an organization
     * @param newAdmin is the wallet address to transfer ownership to
     * Emits {OrgAdminTransferred} event
     */
    function transferAdmin(
        bytes32 polytradeId,
        address newAdmin
    ) external isValidID(polytradeId) isValidAddress(newAdmin) onlyOwner {
        require(
            _organizations[polytradeId].polytradeId != bytes32(0),
            "Organization does not exist"
        );

        bool orgWallet = _isOrgWallet(polytradeId, newAdmin);
        if (!orgWallet) {
            _organizations[polytradeId].wallets.push(newAdmin);
        }
        address oldAdmin = _organizations[polytradeId].admin;
        _organizations[polytradeId].admin = newAdmin;

        emit OrgAdminTransferred(polytradeId, oldAdmin, newAdmin);
    }

    /**
     * @dev returns the organization details from the organization struct
     * @param polytradeId is the Id assigned to an organization
     * @return struct returns organization struct details
     */
    function getOrgDetails(
        bytes32 polytradeId
    ) external view isValidID(polytradeId) returns (Organization memory) {
        Organization memory organization = _organizations[polytradeId];
        return organization;
    }

    /**
     * @dev returns the verification status of an organization
     * @param polytradeId is the Id assigned to an organization
     * @return boolean value representing the verification status
     */
    function isVerified(bytes32 polytradeId) external view returns (bool) {
        require(
            _organizations[polytradeId].polytradeId != bytes32(0),
            "Organization does not exist"
        );
        return _organizations[polytradeId].verified;
    }

    /**
     * @dev returns whether a wallet belongs to an organization or not
     * @param polytradeId is the Id assigned to an organization
     * @param wallet is the wallet address to be checked
     * @return bool true or false
     */
    function isOrgWallet(
        bytes32 polytradeId,
        address wallet
    )
        external
        view
        isValidID(polytradeId)
        isValidAddress(wallet)
        returns (bool)
    {
        return _isOrgWallet(polytradeId, wallet);
    }

    function isAdminWallet(
        bytes32 polytradeId,
        address wallet
    )
        external
        view
        isValidID(polytradeId)
        isValidAddress(wallet)
        returns (bool)
    {
        Organization memory organization = _organizations[polytradeId];
        if (wallet == organization.admin) {
            return true;
        } else {
            return false;
        }
    }

    function _isOrgWallet(
        bytes32 polytradeId,
        address wallet
    ) private view returns (bool) {
        Organization memory organization = _organizations[polytradeId];
        address[] memory wallets = organization.wallets;

        for (uint i = 0; i < wallets.length; i++) {
            if (wallets[i] == wallet) {
                return true;
            }
        }
        return false;
    }
}